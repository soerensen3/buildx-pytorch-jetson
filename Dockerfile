# modified from: https://github.com/flacjacket/docker_images/blob/cuda-tx2/Dockerfile

FROM nvcr.io/nvidia/l4t-base:r32.6.1 as cuda-devel
COPY jetson-ota-public.asc /etc/apt/trusted.gpg.d/jetson-ota-public.asc
RUN  apt-get update \
  && apt-get install -y --no-install-recommends \
         ca-certificates \
  && echo "deb https://repo.download.nvidia.com/jetson/common r32.6 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list \
  && echo "deb https://repo.download.nvidia.com/jetson/t186 r32.6 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
         cuda-libraries-10-2 \
         cuda-nvrtc-10-2 \
         cuda-nvtx-10-2 \
         python3-libnvinfer \
  && ln -sf python3 /usr/bin/python \
  && rm -rf /var/cache/apt /var/lib/apt/lists/*

RUN ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && apt-get update && apt-get install -y software-properties-common apt-utils
#-------------------------------------------------------------------------------------


FROM --platform=$BUILDPLATFORM ubuntu:18.04 as downloader
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common apt-utils \
      git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN git clone https://github.com/pytorch/pytorch torch
ARG VER=1.10.0
WORKDIR /torch/
RUN git checkout "v$VER"
RUN git checkout --recurse-submodules "v$VER"
RUN git submodule sync
RUN git submodule update --init --recursive
#-------------------------------------------------------------------------------------


FROM cuda-devel as builder
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

RUN add-apt-repository 'ppa:deadsnakes/ppa'
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
		  libopenblas-dev \
		  libopenmpi2 \
            openmpi-bin \
            openmpi-common \
		  gfortran \
          python3.9 \
          python3.9-dev \
          python3.9-distutils \
          python3.9-venv \
          build-essential \
          ccache \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENV VIRTUAL_ENV=/opt/venv
RUN python3.9 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64 ${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

WORKDIR /opt/venv

RUN python3 -m pip install numpy scipy six wheel Cython cmake pyyaml typing_extensions

COPY --from=downloader /torch /opt/venv/torch
WORKDIR /opt/venv/torch

ARG PYTORCH_BUILD_VERSION="$VER"
ARG PYTORCH_BUILD_NUMBER="1"

ARG BUILD_TEST=0
ARG USE_BREAKPAD=0

ARG TORCH_CUDA_ARCH_LIST=10.2
#ARG TORCH_CUDA_ARCH_LIST=Turing
ARG USE_CUDA=1
ARG USE_DISTRIBUTED=0
ARG USE_NCCL=0
RUN rm build/CMakeCache.txt || :
RUN python3 setup.py build
RUN python3 setup.py install
RUN python3 setup.py bdist_wheel

#-------------------------------------------------------------------------------------

FROM scratch as artifact
COPY --from=builder /opt/venv/torch/dist /
#-------------------------------------------------------------------------------------

FROM artifact as release
