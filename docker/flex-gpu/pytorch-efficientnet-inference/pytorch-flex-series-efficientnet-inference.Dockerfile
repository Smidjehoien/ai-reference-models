# Copyright (c) 2023-2024 Intel Corporation
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

ARG BASE_IMAGE="intel/intel-extension-for-pytorch"
ARG BASE_TAG="2.1.10-xpu"

FROM ${BASE_IMAGE}:${BASE_TAG}

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

USER root

WORKDIR /workspace/pytorch-flex-series-efficientnet-inference
COPY models_v2/pytorch/efficientnet/inference/gpu .

RUN apt-get update && \
    apt-get install -y --no-install-recommends pciutils numactl && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install -r requirements.txt

RUN pip install --no-cache-dir --upgrade pip

COPY LICENSE license/LICENSE
COPY third_party license/third_party
