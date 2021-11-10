# This script builds pytorch wheel including libtorch for arm64 and python 3.9 with cuda support

docker buildx build --platform=linux/arm64 --progress=plain --output type=local,dest=. -t build-torch-l4t:aarch64 ${pwd}
