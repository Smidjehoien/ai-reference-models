# TensorFlow MobileNet V1 inference

## Description
This document has instructions for running MobileNet V1 inference using Intel-optimized TensorFlow.

## Pull Command
```
docker pull intel/image-recognition:tf-cpu-centos-mobilenet-v1-inference
```

<table>
   <thead>
      <tr>
         <th>Script name</th>
         <th>Description</th>
      </tr>
   </thead>
   <tbody>
      <tr>
         <td>inference_realtime_multi_instance.sh</td>
         <td>A multi-instance run that uses 4 cores per instance with `batch_size=1` for the specified precision (fp32, int8, bfloat16, bfloat32). Uses synthetic data if no DATASET_DIR is set</td>
      </tr>
      <tr>
         <td>inference_throughput_multi_instance.sh</td>
         <td>A multi-instance run that uses 4 cores per instance with `batch_size=448` for the specified precision (fp32, int8, bfloat16, bfloat32). Uses synthetic data if no DATASET_DIR is set</td>
      </tr>
      <tr>
         <td>accuracy.sh</td>
         <td>Measures the model accuracy (batch_size=100) for the specified precision (fp32, int8, bfloat16, bfloat32).</td>
      </tr>
   </tbody>
</table>

## Datasets
Download and preprocess the ImageNet dataset using the [instructions here](https://github.com/IntelAI/models/blob/master/datasets/imagenet/README.md).
After running the conversion script you should have a directory with the
ImageNet dataset in the TF records format.

Set the `DATASET_DIR` to point to the TF records directory when running MobileNet V1.

## Docker Run
(Optional) Export related proxy into docker environment.
```bash
export DOCKER_RUN_ENVS="-e ftp_proxy=${ftp_proxy} \
  -e FTP_PROXY=${FTP_PROXY} -e http_proxy=${http_proxy} \
  -e HTTP_PROXY=${HTTP_PROXY} -e https_proxy=${https_proxy} \
  -e HTTPS_PROXY=${HTTPS_PROXY} -e no_proxy=${no_proxy} \
  -e NO_PROXY=${NO_PROXY} -e socks_proxy=${socks_proxy} \
  -e SOCKS_PROXY=${SOCKS_PROXY}"
```

To run MobileNet V1 inference, set environment variables to specify the dataset directory, precision and mode to run, and an output directory. 
```bash
# Set the required environment vars
export DATASET_DIR=<path to the dataset>
export OUTPUT_DIR=<directory where log files will be written>
export SCRIPT=<specify the script to run>
export PRECISION=<specify the precision to run>

# For a custom batch size, set env var `BATCH_SIZE` or it will run with a default value.
export BATCH_SIZE=<customized batch size value>

docker run --rm \
  --env BATCH_SIZE=${BATCH_SIZE} \
  --env DATASET_DIR=${DATASET_DIR} \
  --env OUTPUT_DIR=${OUTPUT_DIR} \
  --env PRECISION=${PRECISION} \
  --volume ${DATASET_DIR}:${DATASET_DIR} \
  --volume ${OUTPUT_DIR}:${OUTPUT_DIR} \
  --privileged --init -it \
  --shm-size 8G \
  -w /workspace/tf-mobilenet-v1-inference \
  intel/image-recognition:tf-cpu-centos-mobilenet-v1-inference \
  /bin/bash quickstart/${SCRIPT}
```

## Documentation and Sources
#### Get Started​
[Docker* Repository](https://hub.docker.com/r/intel/image-recognition)

[Main GitHub*](https://github.com/IntelAI/models)

[Release Notes](https://github.com/IntelAI/models/releases)

[Get Started Guide](https://github.com/IntelAI/models/blob/master/quickstart/image_recognition/tensorflow/mobilenet_v1/inference/cpu/README_DEV_CAT.md)

#### Code Sources
[Dockerfile](https://github.com/IntelAI/models/tree/master/dockerfiles/tensorflow)

[Report Issue](https://community.intel.com/t5/Intel-Optimized-AI-Frameworks/bd-p/optimized-ai-frameworks)

## License Agreement
LEGAL NOTICE: By accessing, downloading or using this software and any required dependent software (the “Software Package”), you agree to the terms and conditions of the software license agreements for the Software Package, which may also include notices, disclaimers, or license terms for third party software included with the Software Package. Please refer to the [license](https://github.com/IntelAI/models/tree/master/third_party) file for additional details.

[View All Containers and Solutions 🡢](https://www.intel.com/content/www/us/en/developer/tools/software-catalog/containers.html?s=Newest)