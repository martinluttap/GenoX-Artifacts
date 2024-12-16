# ARG FROM_IMAGE_NAME=nvcr.io/nvidia/pytorch:22.11-py3
ARG FROM_IMAGE_NAME=pytorch/pytorch 

FROM ${FROM_IMAGE_NAME}

RUN apt update && apt install -y build-essential ;
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install requirements
RUN pip3 install lightning pytorch-lightning Cython nemo_toolkit['asr'] librosa 