# Pytorch doesn't work with 3.8
FROM python:3.7

# Install deps
RUN apt update && apt install -y --no-install-recommends git libgtest-dev cmake wget unzip libtinfo-dev libz-dev \
     libcurl4-openssl-dev libopenblas-dev g++ sudo python3-dev

# Libposit dependencies: gmp and mpfr
run apt install -y --no-install-recommends libmpfr-dev libgmp-dev

# LLVM
RUN echo deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main \
     >> /etc/apt/sources.list.d/llvm.list && \
     wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add - && \
     apt-get update && apt-get install -y llvm-8

# Build Gus's version of TVM
RUN cd /usr && git clone https://github.com/gussmith23/tvm.git tvm --recursive
WORKDIR /usr/tvm
RUN git fetch
RUN git checkout 75140ef9576bddc81de6b423b5eef64c1b65bed5
RUN git submodule sync && git submodule update
RUN echo 'set(USE_LLVM llvm-config-8)' >> config.cmake
RUN echo 'set(USE_RPC ON)' >> config.cmake
RUN echo 'set(USE_SORT ON)' >> config.cmake
RUN echo 'set(USE_GRAPH_RUNTIME ON)' >> config.cmake
RUN echo 'set(USE_BLAS openblas)' >> config.cmake
RUN echo 'set(CMAKE_CXX_STANDARD 14)' >> config.cmake
RUN echo 'set(CMAKE_CXX_STANDARD_REQUIRED ON)' >> config.cmake
RUN echo 'set(CMAKE_CXX_EXTENSIONS OFF)' >> config.cmake
# TODO(gus) For some reason, Resnet50 segfaults in my docker image when TVM is
# built in Release configuration.
RUN echo 'set(CMAKE_BUILD_TYPE Debug)' >> config.cmake
RUN bash -c \
     "mkdir -p build && \
     cd build && \
     cmake .. && \
     make -j2"
ENV PYTHONPATH=/usr/tvm/python:/usr/tvm/topi/python:${PYTHONPATH}

WORKDIR /root

# Set up Python
RUN pip3 install --upgrade pip
COPY ./requirements.txt ./requirements.txt
RUN pip3 install -r requirements.txt
RUN pip3 install torch==1.3.1+cpu torchvision==0.4.2+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Set up datatypes
COPY Makefile Makefile
COPY ./datatypes ./datatypes
RUN make

# Move tests.
COPY ./tests ./tests

# Move run script.
COPY run.sh run.sh

CMD ["./run.sh"]
