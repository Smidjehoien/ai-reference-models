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
# ============================================================================
#
# THIS IS A GENERATED DOCKERFILE.
#
# This file was assembled from multiple pieces, whose use is documented
# throughout. Please refer to the TensorFlow dockerfiles documentation
# for more information.

ARG TF_BASE_IMAGE="intel/intel-extension-for-tensorflow"
ARG TF_BASE_TAG="2.14.0.1-xpu"

FROM ${TF_BASE_IMAGE}:${TF_BASE_TAG}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        intel-oneapi-mpi-devel=2021.11.0-49493  \
        intel-oneapi-ccl=2021.11.2-5 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/tf-max-series-bert-large-training/models

COPY models_v2/tensorflow/bert_large/training/gpu .

RUN git clone https://github.com/titipata/pubmed_parser && \
    pip install ./pubmed_parser

RUN python -m pip install git+https://github.com/NVIDIA/dllogger \
              requests \
              tqdm \
              sentencepiece \
              tensorflow_hub \
              wget \
              progressbar \
              nltk \
              tensorflow-addons 

RUN git clone https://github.com/NVIDIA/DeepLearningExamples.git && \
    cd DeepLearningExamples/TensorFlow2/LanguageModeling/BERT && \
    cp /workspace/tf-max-series-bert-large-training/models/bert-large-itex-bf16.patch . && \
    git apply bert-large-itex-bf16.patch 

ENV LD_LIBRARY_PATH=/opt/intel/oneapi/mpi/2021.11/opt/mpi/libfabric/lib:/opt/intel/oneapi/mpi/2021.11/lib:/opt/intel/oneapi/ccl/2021.11/lib/:$LD_LIBRARY_PATH
ENV PATH=/opt/intel/oneapi/mpi/2021.11/opt/mpi/libfabric/bin:/opt/intel/oneapi/mpi/2021.11/bin:$PATH
ENV CCL_ROOT=/opt/intel/oneapi/ccl/2021.11
ENV I_MPI_ROOT=/opt/intel/oneapi/mpi/2021.11
ENV FI_PROVIDER_PATH=/opt/intel/oneapi/mpi/2021.11/opt/mpi/libfabric/lib/prov:/usr/lib/x86_64-linux-gnu/libfabric

COPY LICENSE licenses/LICENSE
COPY third_party licenses/third_party
