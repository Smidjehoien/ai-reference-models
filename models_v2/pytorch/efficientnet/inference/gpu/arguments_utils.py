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

# system modules
import argparse
import torchvision.models as models

args = argparse.Namespace()

def parse_arguments():
    model_names = sorted(name for name in models.__dict__
        if name.islower() and not name.startswith('__')
        and callable(models.__dict__[name]))

    parser = argparse.ArgumentParser(description='PyTorch EfficientNet inference')
    parser.add_argument('--data', metavar='DIR', nargs='?', default=None,
                        help='path to dataset (default: None)')
    parser.add_argument('--output-dir', default='/workspace/temp/',
                        help='path to output results (default: /workspace/temp/)')
    parser.add_argument('-a', '--arch', metavar='ARCH', default='efficientnet_b0',
                        choices=model_names,
                        help='model architecture: ' +
                            ' | '.join(model_names) +
                            ' (default: efficientnet_b4)')
    parser.add_argument('--width', default=380, type=int, metavar='N',
                        help='width of input image to be used (default: 380)')
    parser.add_argument('--height', default=380, type=int, metavar='N',
                        help='height of input image to be used (default: 380)')
    parser.add_argument('-b', '--batch-size', default=16, type=int,
                        metavar='N',
                        help='mini-batch size (default: 16), this is the total '
                            'batch size of all GPUs on the current node when '
                            'using Data Parallel or Distributed Data Parallel')
    parser.add_argument('--batch-streaming', default=1, type=int,
                        metavar='N',
                        help='Aggregate data over this number of batches before calculating stats')
    parser.add_argument('--max-val-dataset-size', default=50000, type=int,
                        metavar='N',
                        help='limit number of images to use for validation (default: 50000)')
    parser.add_argument('--status-prints', default=10, type=int,
                        metavar='N', help='number of status prints during benchmarking (default: 10)')
    parser.add_argument('--pretrained', dest='pretrained', action='store_true',
                        help='use pre-trained model')
    parser.add_argument('--seed', default=None, type=int,
                        help='seed for initializing training. ')
    parser.add_argument('--device', default=0, type=int,
                        help='device id to use. should correspond to either NV GPU or Intel XPU')
    parser.add_argument('--tf32', default=0, type=int, help='Datatype used: TF32')
    parser.add_argument('--bf32', default=0, type=int, help='Datatype used: BF32')
    parser.add_argument('--fp16', default=0, type=int, help='Datatype used: FP16')
    parser.add_argument('--bf16', default=0, type=int, help='Datatype used: BF16')
    parser.add_argument('--int8', default=0, type=int, help='Use signed int8 quantization to do inference')
    parser.add_argument('--uint8', default=0, type=int, help='Use unsigned int8 quantization to do inference')
    parser.add_argument('--asymmetric-quantization', dest='asymmetric_quantization', action='store_true',
                        help='Enable asymmetric quantization (default is symmetric).')
    parser.add_argument('--jit-trace', action='store_true',
                        help='enable PyTorch JIT trace graph mode')
    parser.add_argument('--jit-script', action='store_true',
                        help='enable PyTorch JIT script graph mode')
    parser.add_argument('--zero-grad', action='store_true',
                        help='set model gradients to zero')
    parser.add_argument('--no-grad', action='store_true',
                        help='set model gradients to none')
    parser.add_argument('--no-amp', action='store_true',
                        help='Do not use autocast. Direct conversion from native data type to desired data type')
    parser.add_argument('--calib-iters', default=8, type=int,
                        help='iteration number for calibration')
    parser.add_argument('--calib-bs', default=32, type=int,
                        metavar='N', help='mini-batch size for calibration')
    parser.add_argument('--perchannel-weight', default=False,
                        help='do calibration with weight per channel quantization')
    parser.add_argument('--non-blocking', default=False, action='store_true',
                        help='non blocking H2D for input and target, default False')
    parser.add_argument('--channels-last', action='store_true', help='enable channels last')
    parser.add_argument('--warm-up', default=0, type=int, help='warm up batches')
    parser.add_argument('--label-smoothing', default=0.0, type=float)
    parser.add_argument('--dummy', action='store_true', help='use dummy data for '
                        'benchmark training or val')
    parser.add_argument('--save', help='Path to save entire model, save inference mode, training is not available')
    parser.add_argument('--load', help='Path to load entire inference model')
    parser.add_argument('--total-instances', default=1, type=int, help='total number of instances for multi-process inference perf measurement')
    parser.add_argument('--max-wait-for-sync', default=60, type=int, help='max amount of time that will be spend waiting for sync success')
    parser.add_argument('--terminate-if-sync-fail', action='store_true', help='terminate process if fail to sync')

    global args
    parser.parse_args(namespace=args)
