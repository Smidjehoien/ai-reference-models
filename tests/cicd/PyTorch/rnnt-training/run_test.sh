#!/bin/bash
set -e

echo "Setup PyTorch Test Enviroment for RNN-T Training"

PRECISION=$1
SCRIPT=$2
OUTPUT_DIR=${OUTPUT_DIR-"$(pwd)/tests/cicd/output/PyTorch/rnnt-training/${SCRIPT}/${PRECISION}"}
WORKSPACE=$3
is_lkg_drop=$4
DATASET=$5

# Create the output directory in case it doesn't already exist
mkdir -p ${OUTPUT_DIR}

if [[ "${is_lkg_drop}" == "true" ]]; then
  source ${WORKSPACE}/pytorch_setup/bin/activate pytorch
fi

#Build torch-ccl:
git clone https://github.com/intel-innersource/frameworks.ai.pytorch.torch-ccl.git
# torch-ccl branch refer to https://github.com/intel-innersource/frameworks.ai.pytorch.ipex-cpu/blob/cpu-device/dependency_version.yml
cd frameworks.ai.pytorch.torch-ccl
git submodule sync 
git submodule update --init --recursive
python setup.py install 
cd - 

export LD_PRELOAD="${WORKSPACE}/jemalloc/lib/libjemalloc.so":"${WORKSPACE}/tcmalloc/lib/libtcmalloc.so":"/usr/local/lib/libiomp5.so":$LD_PRELOAD 
export MALLOC_CONF="oversize_threshold:1,background_thread:true,metadata_thp:auto,dirty_decay_ms:9000000000,muzzy_decay_ms:9000000000"
export DNNL_MAX_CPU_ISA=AVX512_CORE_AMX

# Install model dependencies:
./quickstart/language_modeling/pytorch/rnnt/training/cpu/install_dependency.sh

# Run script
OUTPUT_DIR=${OUTPUT_DIR} DATASET_DIR=${DATASET} PRECISION=${PRECISION} ./quickstart/language_modeling/pytorch/rnnt/training/cpu/${SCRIPT}
