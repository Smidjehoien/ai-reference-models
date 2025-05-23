#!/usr/bin/env bash
### This file is originally from: [mlcommons repo](https://github.com/mlcommons/inference/tree/r0.5/others/cloud/single_stage_detector/download_dataset.sh)
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
DATASET_DIR=${DATASET_DIR-$PWD}

dir=$(pwd)
mkdir -p ${DATASET_DIR}/coco; cd ${DATASET_DIR}/coco
curl -O http://images.cocodataset.org/zips/val2017.zip; unzip val2017.zip
curl -O http://images.cocodataset.org/annotations/annotations_trainval2017.zip; unzip annotations_trainval2017.zip
cd $dir
