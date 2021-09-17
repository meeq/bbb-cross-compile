# syntax=docker/dockerfile:1.3

FROM amd64/debian:11.0 AS base

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get -y --quiet --no-install-recommends install \
        bc \
        bison \
        build-essential \
        cpio \
        flex \
        libc6-i386 \
        libssl-dev \
        lzop \
        make \
        u-boot-tools \
        xz-utils \
 && apt-get -y autoremove \
 && apt-get clean autoclean \
 && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

FROM base AS sdks

ARG GCC_ARM_VERSION
ENV GCC_ARM_VERSION=${GCC_ARM_VERSION}
ENV GCC_ARM_SDK=/sdks/gcc-arm-${GCC_ARM_VERSION}

ARG GCC_PRU_VERSION
ENV GCC_PRU_VERSION=${GCC_PRU_VERSION}
ENV GCC_PRU_SDK=/sdks/gcc-pru-${GCC_PRU_VERSION}

ARG TI_PRU_VERSION
ENV TI_PRU_VERSION=${TI_PRU_VERSION}
ENV TI_PRU_SDK=/sdks/ti-pru-${TI_PRU_VERSION}

ARG GCC_ARM_CACHED
ARG GCC_PRU_CACHED
ARG TI_PRU_CACHED
COPY ${GCC_ARM_CACHED} ${GCC_PRU_CACHED} ${TI_PRU_CACHED} .sdk-cache/

RUN mkdir --parents ${GCC_ARM_SDK} ${GCC_PRU_SDK} \
 && tar -xf ${GCC_ARM_CACHED} --directory ${GCC_ARM_SDK} --strip-components=1 \
 && rm ${GCC_ARM_CACHED} \
 && tar -xf ${GCC_PRU_CACHED} --directory ${GCC_PRU_SDK} --strip-components=1 \
 && rm ${GCC_PRU_CACHED} \
 && chmod +x ${TI_PRU_CACHED} \
 && ./${TI_PRU_CACHED} --prefix $(pwd) --mode unattended \
 && mv ti-cgt-pru_* ${TI_PRU_SDK} \
 && rm ${TI_PRU_CACHED}

FROM sdks AS runner

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
