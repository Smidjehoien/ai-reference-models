#
# -*- coding: utf-8 -*-
#
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

#!/bin/bash

# Create an array of input directories that are expected and then verify that they exist
declare -A input_envs
input_envs[DATASET_DIR]=${DATASET_DIR}
input_envs[MULTI_TILE]=${MULTI_TILE}
input_envs[OUTPUT_DIR]=${OUTPUT_DIR}
input_envs[PLATFORM]=${PLATFORM}

for i in "${!input_envs[@]}"; do
  var_name=$i
  env_param=${input_envs[$i]}

  if [[ -z $env_param ]]; then
    echo "The required environment variable $var_name is not set" >&2
    exit 1
  fi
done

if [[ "${PLATFORM}" == "Max" ]]; then
    BATCH_SIZE=${BATCH_SIZE:-512}
    PRECISION=${PRECISION:-BF16}
elif [[ "${PLATFORM}" == "Flex" ]]; then
    echo "Only support Max for platform"
fi

# known issue
if [[ "${MULTI_TILE}" == "True" ]]; then
    export ZE_FLAT_DEVICE_HIERARCHY=COMPOSITE
fi

echo 'Running with parameters:'
echo " PLATFORM: ${PLATFORM}"
echo " OUTPUT_DIR: ${OUTPUT_DIR}"
echo " DATASET_DIR: ${DATASET_DIR}"
echo " PRECISION: ${PRECISION}"
echo " BATCH_SIZE: ${BATCH_SIZE}"
echo " MULTI_TILE: ${MULTI_TILE}"

if [[ "${PRECISION}" == "BF16" ]]; then
    flag="--bf16 1 --batch_split_factor 64 "
elif [[ "${PRECISION}" == "FP32" ]]; then
    flag="--batch_split_factor 128 "
elif [[ "${PRECISION}" == "TF32" ]]; then
    export IPEX_FP32_MATH_MODE=1
    flag="--batch_split_factor 128 "
else
    echo -e "Invalid input! Only BF16 FP32 TF32 are supported."
    exit 1
fi

echo "RNNT ${PRECISION} training plain MultiTile=${MULTI_TILE} BS=${BATCH_SIZE}"

# Create the output directory, if it doesn't already exist
mkdir -p $OUTPUT_DIR/out

modelname=rnnt

if [[ ${MULTI_TILE} == "False" ]]; then
    rm ${OUTPUT_DIR}/${modelname}${PRECISION}_train_t0_raw.log
    IPEX_COMPUTE_ENG=1 python -u train.py --dataset_dir ${DATASET_DIR} --val_manifest ${DATASET_DIR}/librispeech-dev-clean-wav.json --train_manifest ${DATASET_DIR}/librispeech-train-clean-100-wav.json --model_toml configs/rnnt.toml --output_dir ${OUTPUT_DIR} --optimizer adam --save_freq 100 --eval_freq 1 --num_steps 20 --train_freq 5 -b ${BATCH_SIZE} --seed 6 --eval_batch_size=2 --num_epochs 1 --lr 0.001 --lr_warmup 8000 --weight_decay 1e-3 --lr_decay --gradient_accumulation_steps 1 ${flag} --xpu --batch_split_factor 64 2>&1 | tee ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0_raw.log
    python common/parse_result.py -m $modelname -l ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0_raw.log -b ${BATCH_SIZE}
    throughput=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0.log | grep Performance | awk -F ' ' '{print $2}')
    throughput_unit=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0.log | grep Performance | awk -F ' ' '{print $3}')
    latency=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0.log | grep Latency | awk -F ' ' '{print $2}')
    acc=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0.log | grep Accuracy | awk -F ' ' '{print $3}')
    acc_unit=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_train_t0.log | grep Accuracy | awk -F ' ' '{print $2}')
else
    rm ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train_raw.log
    IPEX_COMPUTE_ENG=1 mpirun -np 2 -ppn 2 --prepend-rank python -u train.py --dataset_dir ${DATASET_DIR} --val_manifest ${DATASET_DIR}/librispeech-dev-clean-wav.json --train_manifest ${DATASET_DIR}/librispeech-train-clean-100-wav.json --model_toml configs/rnnt.toml --output_dir ${OUTPUT_DIR}/out --optimizer adam --save_freq 100 --eval_freq 1 --num_steps 20 --train_freq 5 -b ${BATCH_SIZE} --seed 6 --eval_batch_size=2 --num_epochs 1 --lr 0.001 --lr_warmup 8000 --weight_decay 1e-3 --lr_decay --gradient_accumulation_steps 1 ${flag} --xpu --batch_split_factor 64 --disable-broadcast-buffers --large-first-bucket --use-gradient-as-bucket-view 2>&1 | tee ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train_raw.log
    python common/parse_result.py -m $modelname --ddp -l ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train_raw.log -b ${BATCH_SIZE}
    throughput=$(cat ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train.log | grep "Sum Performance" | awk -F ' ' '{print $3}')
    throughput_unit=$(cat ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train.log | grep "Sum Performance" | awk -F ' ' '{print $4}')
    latency=$(cat ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train.log | grep Latency | awk -F ' ' '{print $2}')
    acc=$(cat ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train.log | grep Accuracy | awk -F ' ' '{print $3}')
    acc_unit=$(cat ${OUTPUT_DIR}/ddp-${modelname}_${PRECISION}_train.log | grep Accuracy | awk -F ' ' '{print $2}')
fi

yaml_content=$(cat <<EOF
results:
 - key: throughput
   value: $throughput
   unit: $throughput_unit
 - key: latency
   value: $latency
   unit: s
 - key: accuracy
   value: $acc
   unit: $acc_unit
EOF
)

# Write the content to a YAML file
echo "$yaml_content" >  ${OUTPUT_DIR}/results.yaml
echo "YAML file created."
