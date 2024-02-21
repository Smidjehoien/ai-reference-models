# Copyright (c) 2020-2021 Intel Corporation
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

ARG TF_BASE_IMAGE="intel/intel-extension-for-tensorflow"
ARG TF_BASE_TAG="xpu"

FROM ${TF_BASE_IMAGE}:${TF_BASE_TAG}

ENV DEBIAN_FRONTEND=noninteractive

ARG PY_VERSION=3.10

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        parallel \
        pciutils \
        numactl \
        build-essential \
        python${PY_VERSION}-dev && \
    rm -rf /var/lib/apt/lists/*

# Note pycocotools has to be install after the other requirements
RUN pip install \
        Cython \
        contextlib2 \
        jupyter \
        lxml \
        matplotlib \
        numpy>=1.17.4 \
        'pillow>=9.3.0' \
        pycocotools

WORKDIR /workspace/tf-flex-series-ssd-mobilenet-inference

ARG MODEL_URL

RUN mkdir -p pretrained_models && \
    wget ${MODEL_URL} -O pretrained_models/ssdmobilenet_int8_pretrained_model_gpu.pb 

COPY benchmarks benchmarks
COPY models models
COPY quickstart/common quickstart/common
COPY quickstart/object_detection/tensorflow/ssd-mobilenet/inference/gpu/batch_inference.sh quickstart/batch_inference.sh
COPY quickstart/object_detection/tensorflow/ssd-mobilenet/inference/gpu/online_inference.sh quickstart/online_inference.sh
COPY quickstart/object_detection/tensorflow/ssd-mobilenet/inference/gpu/accuracy.sh quickstart/accuracy.sh
COPY quickstart/object_detection/tensorflow/ssd-mobilenet/inference/gpu/flex_multi_card_batch_inference.sh quickstart/flex_multi_card_batch_inference.sh
COPY quickstart/object_detection/tensorflow/ssd-mobilenet/inference/gpu/flex_multi_card_online_inference.sh quickstart/flex_multi_card_online_inference.sh

COPY LICENSE license/LICENSE
COPY third_party license/third_party
