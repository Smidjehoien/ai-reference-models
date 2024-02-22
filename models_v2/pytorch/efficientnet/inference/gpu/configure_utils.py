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
import sys
import os
import random
import warnings
import torch
import torch.backends.cudnn as cudnn

# sample modules
import io_utils
from arguments_utils import args

def enum_device():
    # Detect device type from xpu, cuda, and cpu.
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    if device == 'cpu':
        import intel_extension_for_pytorch as ipex
        device = 'xpu' if ipex.xpu.is_available() else device

    # Assign device number.
    args.gpu = False
    args.xpu = False
    if device == 'cuda':
        io_utils.write_info('Use GPU: {0}'.format(args.device))
        args.device = '{0}:{1}'.format(device, args.device)
        args.gpu = True
    elif device == 'xpu':
        io_utils.write_info('Use XPU: {0}'.format(args.device))
        args.device = '{0}:{1}'.format(device, args.device)
        args.xpu = True
    else:
        io_utils.write_info('Use CPU')
        args.device = 'cpu'

    # Ensure system is configured properly
    if args.gpu:
        if not torch.cuda.is_available():
            io_utils.write_error('Make sure cuda is enabled in torch.')
            sys.exit(1)
    elif args.xpu:
        try:
            import intel_extension_for_pytorch as ipex
        except:
            io_utils.write_error('Make sure Intel Extension for PyTorch is enabled.')
            sys.exit(1)

def enum_dtypes():
    if args.bf16:
        dtype = torch.float16 if args.fp16 else torch.float32
        dtype = torch.bfloat16 if args.bf16 else dtype
        args.torch_dtype = torch.bfloat16
        args.dtype_str = 'bfloat16'
    elif args.fp16:
        args.torch_dtype = torch.float16
        args.dtype_str = 'float16'
    elif args.int8:
        args.torch_dtype = torch.int8
        args.dtype_str = 'int8'
    elif args.uint8:
        args.torch_dtype = torch.uint8
        args.dtype_str = 'uint8'
    elif args.tf32:
        args.torch_dtype = torch.float32
        args.dtype_str = 'tfloat32'
        if args.xpu:
            import intel_extension_for_pytorch as ipex
            torch.xpu.set_fp32_math_mode(torch.xpu.FP32MathMode.TF32)
    elif args.bf32:
        args.torch_dtype = torch.float32
        args.dtype_str = 'bfloat32'
        if args.xpu:
            import intel_extension_for_pytorch as ipex
            torch.xpu.set_fp32_math_mode(torch.xpu.FP32MathMode.BF32)
    else:
        args.torch_dtype = torch.float32
        args.dtype_str = 'float32'
        if args.xpu:
            import intel_extension_for_pytorch as ipex
            torch.xpu.set_fp32_math_mode(torch.xpu.FP32MathMode.FP32)

    if 'float32' in args.dtype_str or args.no_amp:
        io_utils.write_info('use data type {0} (No AMP)'.format(args.dtype_str))
    elif not args.no_amp:
        io_utils.write_info('use data type {0} (AMP)'.format(args.dtype_str))

def set_single_environ(name, value):
    if name in os.environ:
        io_utils.write_info('EV["{0}"] changed from "{1}" to "{2}"'.format(
            args.instance,
            args.total_instances,
            name,
            os.environ[name],
            value
        ))
    else:
        io_utils.write_info('EV["{0}"] changed from "NULL" to "{1}"'.format(
            args.instance,
            args.total_instances,
            name,
            value
        ))
    os.environ[name] = value

def set_environ():
    pass

def config_devices():
    if args.seed is not None:
        io_utils.write_info('Using "{0}" as random seed'.format(args.seed))
        random.seed(args.seed)
        torch.manual_seed(args.seed)
        if args.xpu:
            torch.xpu.manual_seed(args.seed)
        if torch.cuda.is_available():
            cudnn.deterministic = True
            io_utils.write_warning(' '.join([
                'You have chosen to seed training.',
                'This will turn on the CUDNN deterministic setting,',
                'which can slow down your training considerably!',
                'You may see unexpected behavior when restarting',
                'from checkpoints.'
            ]))

    if args.xpu:
        using_block_layout = os.environ.get('IPEX_XPU_ONEDNN_LAYOUT', 'OFF').upper() in ['1', 'Y', 'ON', 'YES', 'TRUE']
        if using_block_layout:
            import intel_extension_for_pytorch as ipex
            ipex.disable_auto_channels_last()
            io_utils.write_warning('Using block layout and disabling auto channels last')
