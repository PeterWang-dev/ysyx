# Base image
FROM ubuntu:22.04 as ysyx-base

# Set up verilator runtime environment
FROM ysyx-base as verilator-runtime-env
ENV VERILATOR_PATH="/opt/verilator"
ARG DEPENDENCIES="\
    build-essential \
    help2man \
    libfl2 \
    libfl-dev \
    libgoogle-perftools-dev \
    numactl \
    perl \
    python3 \
    zlib1g \
    zlib1g-dev"
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ${DEPENDENCIES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up verilator build environment
FROM verilator-runtime-env as verilator-build-env
ARG BUILD_DEPENDENCIES="\
    git \
    autoconf \
    bc \
    bison \
    ca-certificates \
    flex \
    wget"
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ${BUILD_DEPENDENCIES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build verilator
FROM verilator-build-env as verilator-build
WORKDIR /tmp
ARG VERILATOR_VERSION=5.008
RUN git clone https://github.com/verilator/verilator \
    && cd verilator \
    && git checkout "v${VERILATOR_VERSION}" \
    && autoconf \
    && unset VERILATOR_ROOT \
    && ./configure --prefix "${VERILATOR_PATH}" \
    && make -j$(nproc) \
    && make test \
    && make install

# ysyx environment: verilator
FROM verilator-runtime-env as ysyx-env-verilator
COPY --from=verilator-build ${VERILATOR_PATH} ${VERILATOR_PATH}
ENV PATH="${VERILATOR_PATH}/bin:${PATH}"
ENV VERILATOR_PATH=

# Set up sbt runtime environment
FROM ysyx-env-verilator as sbt-runtime-env
RUN apt-get update \
    && apt-get install --no-install-recommends -y default-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up sbt install environment
FROM sbt-runtime-env as sbt-install-env
RUN apt-get update \
    && apt-get install --no-install-recommends -y curl gnupg \
    && echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list \
    && echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list \
    && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add \
    && apt-get update
RUN apt-get remove --purge --auto-remove -y curl gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ysyx environment: sbt
FROM sbt-install-env as ysyx-env-sbt
RUN apt-get update \
    && apt-get install --no-install-recommends -y sbt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build firtool
FROM ysyx-base as firtool-build
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
RUN wget -q --no-check-certificate https://github.com/llvm/circt/releases/download/firtool-1.56.1/firrtl-bin-linux-x64.tar.gz \
    && wget -q --no-check-certificate https://github.com/llvm/circt/releases/download/firtool-1.56.1/firrtl-bin-linux-x64.tar.gz.sha256 \
    && echo "$(cat firrtl-bin-linux-x64.tar.gz.sha256) firrtl-bin-linux-x64.tar.gz" | sha256sum --check \
    && tar -xzf firrtl-bin-linux-x64.tar.gz

# ysyx environment: firtool
FROM ysyx-env-sbt as ysyx-env-firtool
COPY --from=firtool-build /tmp/firtool-1.56.1/bin/firtool /opt/firtool/bin/firtool
ENV PATH="/opt/firtool/bin:${PATH}"

# Final image
FROM ysyx-env-firtool as ysyx-env
ARG USERNAME=ysyx
ARG UID=1000
ARG DEFAULT_SHELL=/bin/bash
RUN useradd -m -u ${UID} -s ${DEFAULT_SHELL} -d /workspace ${USERNAME}
USER ${USERNAME}
VOLUME [ "/workspace/ysyx" ]
WORKDIR /workspace/ysyx
CMD [ "/bin/bash" ]
