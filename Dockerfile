FROM amd64/debian:11.0

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

RUN apt-get update \
 && apt-get install -y libc6-i386 xz-utils make \
 && mkdir -p ${GCC_ARM_SDK} \
 && tar -xf ${GCC_ARM_CACHED} --directory ${GCC_ARM_SDK} --strip-components=1 \
 && rm ${GCC_ARM_CACHED} \
 && mkdir -p ${GCC_PRU_SDK}  \
 && tar -xf ${GCC_PRU_CACHED} --directory ${GCC_PRU_SDK} --strip-components=1 \
 && rm ${GCC_PRU_CACHED} \
 && chmod +x ${TI_PRU_CACHED} \
 && ./${TI_PRU_CACHED} --prefix $(pwd) --mode unattended \
 && mv ti-cgt-pru_* ${TI_PRU_SDK} \
 && rm ${TI_PRU_CACHED}

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []
