#!/bin/bash
set -e

echo "Setup PyTorch Test Enviroment for RNN-T Inference"

PRECISION=$1
SCRIPT=$2
OUTPUT_DIR=${OUTPUT_DIR-"$(pwd)/tests/cicd/output/PyTorch/rnnt-inference/${SCRIPT}/${PRECISION}"}
WORKSPACE=$3
is_lkg_drop=$4
DATASET=$5

# Create the output directory in case it doesn't already exist
mkdir -p ${OUTPUT_DIR}

if [[ "${is_lkg_drop}" == "true" ]]; then
  source ${WORKSPACE}/pytorch_setup/bin/activate pytorch
fi
 
export LD_PRELOAD="${WORKSPACE}/jemalloc/lib/libjemalloc.so":"${WORKSPACE}/tcmalloc/lib/libtcmalloc.so":"/usr/local/lib/libiomp5.so":$LD_PRELOAD 
export MALLOC_CONF="oversize_threshold:1,background_thread:true,metadata_thp:auto,dirty_decay_ms:9000000000,muzzy_decay_ms:9000000000"
export DNNL_MAX_CPU_ISA=AVX512_CORE_AMX

# Install model:
./quickstart/language_modeling/pytorch/rnnt/inference/cpu/install_dependency_baremetal.sh

# Install pre-trained model:
export CHECKPOINT_DIR=$(pwd)/tests/cicd/output/PyTorch/rnnt-inference/${PRECISION}
bash quickstart/language_modeling/pytorch/rnnt/inference/cpu/download_model.sh

# Download dataset
if [ -z ${DATASET} ];then
  export DATASET_DIR=$(pwd)/tests/cicd/PyTorch/rnnt-inference/
  ./quickstart/language_modeling/pytorch/rnnt/inference/cpu/download_dataset.sh
else
  DATASET_DIR=${DATASET}
fi

# Run script
OUTPUT_DIR=${OUTPUT_DIR} DATASET_DIR=${DATASET} PRECISION=${PRECISION} CHECKPOINT_DIR=${CHECKPOINT_DIR} ./quickstart/language_modeling/pytorch/rnnt/inference/cpu/${SCRIPT}
