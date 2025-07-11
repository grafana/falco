FROM debian:12-slim AS builder_base

LABEL org.opencontainers.image.source='https://github.com/grafana/falco/tree/master/docker/falco/Dockerfile' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN apt-get update
RUN apt-get install -y --no-install-recommends libasan5 libusan1 ca-certificates
RUN apt clean -y && \
    rm -rf /var/lib/apt/lists/*

FROM builder_base AS builder

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        ca-certificates curl jq git make cmake clang build-essential \
        libelf-dev llvm pkg-config autoconf libcurl4-openssl-dev libasan6 libubsan1 \
        automake libtool m4 bpftool linux-headers-$(uname -m | sed 's/x86_/amd/' | sed 's/aarch/arm/') \
        libbpf1 libbpf-dev libyaml-cpp-dev nlohmann-json3-dev openssl libssl-dev

ARG USER=1000
ARG GROUP=1000

USER ${USER}:${GROUP}

COPY --chown=${USER}:${GROUP} . /src
WORKDIR /src

ARG FALCO_VERSION=0.0.0

RUN mkdir -p build
RUN cmake -B skeleton-build -S . \
    -DUSE_BUNDLED_DEPS=ON \
    -DCREATE_TEST_TARGETS=OFF \
    -DFALCO_VERSION=${FALCO_VERSION}
RUN cmake --build skeleton-build --target ProbeSkeleton -j$(nproc)

ARG BUILD_TYPE="RelWithDebInfo"
ARG USE_ASAN="OFF"
ARG USE_JEMALLOC="OFF"
RUN cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DUSE_BUNDLED_DEPS=ON \
    -DFALCO_ETC_DIR=/etc/falco \
    -DFALCO_VERSION=${FALCO_VERSION} \
    -DMODERN_BPF_SKEL_DIR=./skeleton-build/skel_dir/ \
    -DBUILD_DRIVER=OFF \
    -DBUILD_BPF=OFF \
    -DUSE_JEMALLOC=${USE_JEMALLOC} \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DUSE_ASAN=${USE_ASAN} \
    -DCREATE_TEST_TARGETS=ON \
    -DBUILD_FALCO_UNIT_TESTS=ON

RUN cmake --build build --target falco -j$(nproc)
RUN cmake --build build --target package -j$(nproc)
RUN cmake --build build --target falco_unit_tests -j$(nproc)
RUN mv build/falco-${FALCO_VERSION}-$(uname -m).tar.gz falco.tar.gz

USER root
RUN /src/build/unit_tests/falco_unit_tests

FROM builder_base

COPY --from=builder /src/falco.tar.gz /falco.tar.gz
RUN tar -xzf falco.tar.gz && \
    mv falco-*/ falco/ && \
    rm -f falco.tar.gz && \
    rm -rf falco/usr/src/falco-* && \
    cp -r falco/* / && \
    rm -rf falco

ENTRYPOINT ["/usr/bin/falco"]
