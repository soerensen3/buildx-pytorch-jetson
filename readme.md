# Building pytorch for arm64 with CUDA on amd64

## Motivation

This repository contains the Docker manifests for building pytorch wheels for arm64 resp. aarch64 architecture. 
It can be used instead of cross compilation to build the wheel for example on amd64.

There are already wheels for aarch64 pytorch for Python 3.6 by NVidia. However if you need a more recent Python version you have to compile a new wheel yourself. While it is possible to do this on arm device it takes a very long time (On my Jetson it took several days) and needs a lot of system memory which might not be available on the device. So building it on a fast amd64 is a lot faster.

## Parameters

    arm64/aarch64
    Python 3.9
    CUDA 10.2 [not yet working]

## Important !!!

Right now it does not build with cuda support. The goal however is to support this, to be able to use it with the NVIDIA Jetson.

# Get started

## Preparation

For the following steps I will assume that you installed a docker version that comes with buildx and the qemu-user-bin-fmt and qemu-user-static packages for your distribution. I will also assume you use GNU/Linux. However the steps will probably more or less apply to other OS's.

### Fedora

    sudo dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install \
      docker-ce \
      qemu-user-binfmt \
      qemu-user-static 


You can use build.sh to start building. When the build completes it will drop the whl file in the working directory.
