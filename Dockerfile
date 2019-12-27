FROM python:3

# Install deps
RUN apt update && apt install -y --no-install-recommends git libgtest-dev cmake wget unzip libtinfo-dev libz-dev \
     libcurl4-openssl-dev libopenblas-dev g++ sudo python3-dev

# LLVM
RUN echo deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main \
     >> /etc/apt/sources.list.d/llvm.list && \
     wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add - && \
     apt-get update && apt-get install -y llvm-8

# Build TVM
RUN cd /usr && git clone https://github.com/apache/incubator-tvm.git tvm --recursive
WORKDIR /usr/tvm
RUN git checkout 331f6fd012763438c6d756be051b6e2c8a96f61c
RUN bash -c \
     "echo set\(USE_LLVM llvm-config-8\) >> config.cmake && \
     echo set\(USE_RPC ON\) >> config.cmake && \
     echo set\(USE_SORT ON\) >> config.cmake && \
     echo set\(USE_GRAPH_RUNTIME ON\) >> config.cmake && \
     echo set\(USE_BLAS openblas\) >> config.cmake && \
     mkdir -p build && \
     cd build && \
     cmake .. && \
     make -j2"
ENV PYTHONPATH=/usr/tvm/python:/usr/tvm/topi/python:${PYTHONPATH}

# Set up Python
ENV PYTHON_PACKAGES="\
    numpy \
    nose \
    decorator \
    scipy \
    mxnet \
"
RUN pip3 install --upgrade pip
RUN pip3 install $PYTHON_PACKAGES

WORKDIR /root

# Set up datatypes
COPY Makefile Makefile
COPY ./datatypes ./datatypes
RUN make

# Move tests.
COPY ./tests ./tests

CMD ["nosetests", "./tests"]
