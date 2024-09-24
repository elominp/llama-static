# Build image

FROM alpine:3.20 AS build

RUN apk update && apk add --no-cache autoconf build-base binutils cmake curl file git libtool make musl-dev tar unzip wget upx bash

RUN git clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /llama.cpp

RUN git checkout $(git describe --abbrev=0 --tags $(git rev-list --tags --max-count=1))

RUN mkdir build && mkdir dist

WORKDIR /llama.cpp/build

RUN cmake \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_Type=MinSizeRel \
  -DCMAKE_C_FLAGS=-static \
  -DCMAKE_CXX_FLAGS=-static \
  -DCMAKE_EXE_LINKER_FLAGS=-static \
  -DCMAKE_INSTALL_PREFIX=/llama.cpp/dist \
  -DACCELERATE=OFF \
  -DGGML_LASX=OFF \
  -DGGML_LLAMAFILE=OFF \
  -DGGML_LSX=OFF \
  -DGGML_LTO=ON \
  -DGGML_STATIC=ON \
  -DGGML_OPENMP=OFF \
  ..
  
RUN make -j$(nproc)

RUN make install

WORKDIR /llama.cpp/dist/bin

RUN strip * || echo "[Warning] Failed to strip some files"

RUN echo 'for f in ./*; do upx -9 $f; done' | bash

# Runtime image

FROM scratch

COPY --from=build /llama.cpp/dist/bin /bin

ENTRYPOINT [ "/bin/llama-server" ]

CMD [ "-h" ]
