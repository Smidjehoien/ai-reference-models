import math

# MIT License
# 
# Copyright (c) 2018 Facebook
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import torch
import torch.nn as nn
from torch.nn.modules.utils import _pair

from .deform_conv_func import deform_conv, modulated_deform_conv


class DeformConv(nn.Module):

    def __init__(
        self,
        in_channels,
        out_channels,
        kernel_size,
        stride=1,
        padding=0,
        dilation=1,
        groups=1,
        deformable_groups=1,
        bias=False
    ):
        assert not bias
        super(DeformConv, self).__init__()
        self.with_bias = bias

        assert in_channels % groups == 0, \
            'in_channels {} cannot be divisible by groups {}'.format(
                in_channels, groups)
        assert out_channels % groups == 0, \
            'out_channels {} cannot be divisible by groups {}'.format(
                out_channels, groups)
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = _pair(kernel_size)
        self.stride = _pair(stride)
        self.padding = _pair(padding)
        self.dilation = _pair(dilation)
        self.groups = groups
        self.deformable_groups = deformable_groups

        self.weight = nn.Parameter(
            torch.Tensor(out_channels, in_channels // self.groups,
                         *self.kernel_size))

        self.reset_parameters()

    def reset_parameters(self):
        n = self.in_channels
        for k in self.kernel_size:
            n *= k
        stdv = 1. / math.sqrt(n)
        self.weight.data.uniform_(-stdv, stdv)

    def forward(self, input, offset):
        return deform_conv(input, offset, self.weight, self.stride,
                           self.padding, self.dilation, self.groups,
                           self.deformable_groups)

    def __repr__(self):
        return "".join([
            "{}(".format(self.__class__.__name__),
            "in_channels={}, ".format(self.in_channels),
            "out_channels={}, ".format(self.out_channels),
            "kernel_size={}, ".format(self.kernel_size),
            "stride={}, ".format(self.stride),
            "dilation={}, ".format(self.dilation),
            "padding={}, ".format(self.padding),
            "groups={}, ".format(self.groups),
            "deformable_groups={}, ".format(self.deformable_groups),
            "bias={})".format(self.with_bias),
        ])


class ModulatedDeformConv(nn.Module):

    def __init__(
        self,
        in_channels,
        out_channels,
        kernel_size,
        stride=1,
        padding=0,
        dilation=1,
        groups=1,
        deformable_groups=1,
        bias=True
    ):
        super(ModulatedDeformConv, self).__init__()
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = _pair(kernel_size)
        self.stride = stride
        self.padding = padding
        self.dilation = dilation
        self.groups = groups
        self.deformable_groups = deformable_groups
        self.with_bias = bias

        self.weight = nn.Parameter(torch.Tensor(
            out_channels, 
            in_channels // groups,
            *self.kernel_size
        ))
        if bias:
            self.bias = nn.Parameter(torch.Tensor(out_channels))
        else:
            self.register_parameter('bias', None)
        self.reset_parameters()

    def reset_parameters(self):
        n = self.in_channels
        for k in self.kernel_size:
            n *= k
        stdv = 1. / math.sqrt(n)
        self.weight.data.uniform_(-stdv, stdv)
        if self.bias is not None:
            self.bias.data.zero_()

    def forward(self, input, offset, mask):
        return modulated_deform_conv(
            input, offset, mask, self.weight, self.bias, self.stride,
            self.padding, self.dilation, self.groups, self.deformable_groups)

    def __repr__(self):
        return "".join([
            "{}(".format(self.__class__.__name__),
            "in_channels={}, ".format(self.in_channels),
            "out_channels={}, ".format(self.out_channels),
            "kernel_size={}, ".format(self.kernel_size),
            "stride={}, ".format(self.stride),
            "dilation={}, ".format(self.dilation),
            "padding={}, ".format(self.padding),
            "groups={}, ".format(self.groups),
            "deformable_groups={}, ".format(self.deformable_groups),
            "bias={})".format(self.with_bias),
        ])

class ModulatedDeformConvPack(ModulatedDeformConv):

    def __init__(self,
                 in_channels,
                 out_channels,
                 kernel_size,
                 stride=1,
                 padding=0,
                 dilation=1,
                 groups=1,
                 deformable_groups=1,
                 bias=True):
        super(ModulatedDeformConvPack, self).__init__(
            in_channels, out_channels, kernel_size, stride, padding, dilation,
            groups, deformable_groups, bias)

        self.conv_offset_mask = nn.Conv2d(
            self.in_channels // self.groups,
            self.deformable_groups * 3 * self.kernel_size[0] *
            self.kernel_size[1],
            kernel_size=self.kernel_size,
            stride=_pair(self.stride),
            padding=_pair(self.padding),
            bias=True)
        self.init_offset()

    def init_offset(self):
        self.conv_offset_mask.weight.data.zero_()
        self.conv_offset_mask.bias.data.zero_()

    def forward(self, input):
        out = self.conv_offset_mask(input)
        o1, o2, mask = torch.chunk(out, 3, dim=1)
        offset = torch.cat((o1, o2), dim=1)
        mask = torch.sigmoid(mask)
        return modulated_deform_conv(
            input, offset, mask, self.weight, self.bias, self.stride,
            self.padding, self.dilation, self.groups, self.deformable_groups)
