FROM dsw-registry-vpc.cn-hangzhou.cr.aliyuncs.com/cloud-dsw/eas-service:aigc-torch113-cu117-ubuntu22.04-v0.2.1_accelerated


RUN apt update && apt install -y aria2

RUN clone https://gitcode.net/overbill1683/stable-diffusion-webui

WORKDIR /mnt/auto/stable-diffusion-webui

RUN mkdir repositories
WORKDIR /mnt/auto/stable-diffusion-webui/repositories

# 克隆仓库
RUN git clone https://gitcode.net/overbill1683/stablediffusion stable-diffusion-stability-ai
RUN git clone https://gitcode.net/overbill1683/taming-transformers repositories/taming-transformers
RUN git clone https://gitcode.net/overbill1683/k-diffusion repositories/k-diffusion
RUN git clone https://gitcode.net/overbill1683/CodeFormer repositories/CodeFormer
RUN git clone https://gitcode.net/overbill1683/BLIP repositories/BLIP

WORKDIR /mnt/auto/stable-diffusion-webui

# 下载配置文件
RUN wget -O "config.json" "https://gitcode.net/Akegarasu/sd-webui-configs/-/raw/master/config.json"

# 安装常用插件
RUN echo "https://gitcode.net/ranting8323/a1111-sd-webui-tagcomplete" >> extensions.txt \
    && echo "https://gitcode.net/overbill1683/stable-diffusion-webui-localization-zh_Hans" >> extensions.txt \
    && echo "https://gitcode.net/ranting8323/sd-webui-additional-networks" >> extensions.txt \
    && echo "https://gitcode.net/ranting8323/sd-webui-infinite-image-browsing" >> extensions.txt \
    && echo "https://gitcode.net/ranting8323/stable-diffusion-webui-wd14-tagger" >> extensions.txt \
    && while read -r url; do git clone "$url" "extensions/$(basename "$url")"; done < extensions.txt \
    && rm extensions.txt

# 下载模型文件
RUN model_url="https://huggingface.co/gsdf/Counterfeit-V2.5/resolve/main/Counterfeit-V2.5_fp16.safetensors" \
    && aria2c --console-log-level=error -c -x 16 -s 16 $model_url -o $(basename $model_url) -d /mnt/workspace/stable-diffusion-webui/models/Stable-diffusion

# 下载VAE
RUN VAE_URL="https://huggingface.co/akibanzu/animevae/resolve/main/animevae.pt" \
    && aria2c --console-log-level=error -c -x 16 -s 16 $VAE_URL -o $(basename $VAE_URL) -d /mnt/workspace/stable-diffusion-webui/models/VAE

# 安装所需的 Python 包
RUN pip install --no-cache-dir GFPGAN==8d2447a2d918f8eba5a4a01463fd48e45126a379 \
    && pip install --no-cache-dir CLIP==d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 \
    && pip install --no-cache-dir open_clip==bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b

# 设置环境变量
ENV PIP_INDEX_URL=https://mirrors.bfsu.edu.cn/pypi/web/simple
ENV GFPGAN_PACKAGE=git+https://gitcode.net/overbill1683/GFPGAN.git@8d2447a2d918f8eba5a4a01463fd48e45126a379
ENV CLIP_PACKAGE=git+https://gitcode.net/overbill1683/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1
ENV OPENCLIP_PACKAGE=git+https://gitcode.net/overbill1683/open_clip.git@bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b

# 启动 Web UI
CMD python launch.py --no-download-sd-model --no-half-vae --xformers --share --listen --enable-insecure-extension-access

