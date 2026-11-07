"""RIFE (Real-Time Intermediate Flow Estimation) ara kare ağı — iki karenin tam ortasındaki kareyi üretir.

Kaynak: https://github.com/hzwer/ECCV2022-RIFE (model/IFNet.py), MIT lisansı, © Megvii Inc.
Ağırlıklar: Hugging Face `TensorForger/RIFE-safetensors` (flownet.safetensors, MIT).
Bu dosya o mimarinin incelenmiş bir kopyasıdır; tek fark, `warp`'ın cihaz ve veri tipini
sabit genel değişkenlerden değil girdiden almasıdır. Ağ dosya veya ağ erişimi yapmaz.

Atıf: Huang vd., "Real-Time Intermediate Flow Estimation for Video Frame Interpolation", ECCV 2022.
"""
import torch
import torch.nn as nn
import torch.nn.functional as F


def conv(in_planes, out_planes, kernel_size=3, stride=1, padding=1, dilation=1):
    return nn.Sequential(
        nn.Conv2d(in_planes, out_planes, kernel_size=kernel_size, stride=stride, padding=padding,
                  dilation=dilation, bias=True),
        nn.PReLU(out_planes),
    )


class IFBlock(nn.Module):
    def __init__(self, in_planes, c=64):
        super().__init__()
        self.conv0 = nn.Sequential(conv(in_planes, c // 2, 3, 2, 1), conv(c // 2, c, 3, 2, 1))
        self.convblock0 = nn.Sequential(conv(c, c), conv(c, c))
        self.convblock1 = nn.Sequential(conv(c, c), conv(c, c))
        self.convblock2 = nn.Sequential(conv(c, c), conv(c, c))
        self.convblock3 = nn.Sequential(conv(c, c), conv(c, c))
        self.conv1 = nn.Sequential(nn.ConvTranspose2d(c, c // 2, 4, 2, 1), nn.PReLU(c // 2),
                                   nn.ConvTranspose2d(c // 2, 4, 4, 2, 1))
        self.conv2 = nn.Sequential(nn.ConvTranspose2d(c, c // 2, 4, 2, 1), nn.PReLU(c // 2),
                                   nn.ConvTranspose2d(c // 2, 1, 4, 2, 1))

    def forward(self, x, flow, scale=1):
        x = F.interpolate(x, scale_factor=1.0 / scale, mode="bilinear", align_corners=False,
                          recompute_scale_factor=False)
        flow = F.interpolate(flow, scale_factor=1.0 / scale, mode="bilinear", align_corners=False,
                             recompute_scale_factor=False) / scale
        feat = self.conv0(torch.cat((x, flow), 1))
        feat = self.convblock0(feat) + feat
        feat = self.convblock1(feat) + feat
        feat = self.convblock2(feat) + feat
        feat = self.convblock3(feat) + feat
        flow = self.conv1(feat)
        mask = self.conv2(feat)
        flow = F.interpolate(flow, scale_factor=scale, mode="bilinear", align_corners=False,
                             recompute_scale_factor=False) * scale
        mask = F.interpolate(mask, scale_factor=scale, mode="bilinear", align_corners=False,
                             recompute_scale_factor=False)
        return flow, mask


class IFNet(nn.Module):
    """Girdi (B, 6, H, W): ilk kare [:3], ikinci kare [3:], değerler [0, 1]. Çıktı (B, 3, H, W) orta kare.
    H ve W 32'nin katı olmalıdır."""

    def __init__(self):
        super().__init__()
        self.block0 = IFBlock(7 + 4, c=90)
        self.block1 = IFBlock(7 + 4, c=90)
        self.block2 = IFBlock(7 + 4, c=90)
        self.block_tea = IFBlock(10 + 4, c=90)  # yalnızca eğitimde kullanılır; ağırlıklar yüklenebilsin diye var

    def forward(self, x):
        scale_list = [4, 2, 1]
        channel = x.shape[1] // 2
        img0, img1 = x[:, :channel], x[:, channel:]
        warped_img0, warped_img1 = img0, img1
        flow = x[:, :4].detach() * 0
        mask = x[:, :1].detach() * 0
        merged, mask_list = [], []
        for i, block in enumerate([self.block0, self.block1, self.block2]):
            f0, m0 = block(torch.cat((warped_img0[:, :3], warped_img1[:, :3], mask), 1), flow, scale=scale_list[i])
            f1, m1 = block(torch.cat((warped_img1[:, :3], warped_img0[:, :3], -mask), 1),
                           torch.cat((flow[:, 2:4], flow[:, :2]), 1), scale=scale_list[i])
            flow = flow + (f0 + torch.cat((f1[:, 2:4], f1[:, :2]), 1)) / 2
            mask = mask + (m0 + (-m1)) / 2
            mask_list.append(mask)
            warped_img0 = warp(img0, flow[:, :2])
            warped_img1 = warp(img1, flow[:, 2:4])
            merged.append((warped_img0, warped_img1))
        m = torch.sigmoid(mask_list[2])
        return merged[2][0] * m + merged[2][1] * (1 - m)


def warp(ten_input, ten_flow):
    n, _, h, w = ten_flow.shape
    dev, dt = ten_input.device, ten_input.dtype
    horizontal = torch.linspace(-1.0, 1.0, w, device=dev, dtype=dt).view(1, 1, 1, w).expand(n, -1, h, -1)
    vertical = torch.linspace(-1.0, 1.0, h, device=dev, dtype=dt).view(1, 1, h, 1).expand(n, -1, -1, w)
    grid = torch.cat([horizontal, vertical], 1)
    ten_flow = torch.cat([ten_flow[:, 0:1] / ((ten_input.shape[3] - 1.0) / 2.0),
                          ten_flow[:, 1:2] / ((ten_input.shape[2] - 1.0) / 2.0)], 1)
    g = (grid + ten_flow).permute(0, 2, 3, 1)
    return F.grid_sample(ten_input, g, mode="bilinear", padding_mode="border", align_corners=True)
