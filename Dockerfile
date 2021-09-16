ARG BASE_IMAGE=amd64/debian:11.0

# Install/Extract the downloaded SDKs

FROM ${BASE_IMAGE}

ARG GCC_ARM_CACHED
ARG TI_PRU_CACHED
ARG GCC_PRU_CACHED

COPY ${GCC_ARM_CACHED} ${TI_PRU_CACHED} ${GCC_PRU_CACHED} .sdk-cache/

RUN apt-get update \
 && apt-get install -y libc6-i386 xz-utils make \
 && chmod +x ${TI_PRU_CACHED} \
 && ./${TI_PRU_CACHED} --prefix / --mode unattended \
 && mv /ti-cgt-pru_* /ti-pru \
 && rm ${TI_PRU_CACHED} \
 && mkdir /gcc-pru \
 && tar -xf ${GCC_PRU_CACHED} --directory /gcc-pru --strip-components=1 \
 && rm ${GCC_PRU_CACHED} \
 && mkdir /gcc-arm \
 && tar -xf ${GCC_ARM_CACHED} --directory /gcc-arm --strip-components=1 \
 && rm ${GCC_ARM_CACHED}

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []
