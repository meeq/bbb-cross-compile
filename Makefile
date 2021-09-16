.SILENT: help
.DEFAULT_GOAL := help

check_defined = $(if $(value $(strip $1)),,$(error Undefined $1))

#
# SDK Cache download variables
#

# GCC-based ARM Linux cross-compiler
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
GCC_ARM_VERSION ?= 10.3-2021.07
GCC_ARM_DOWNLOAD_URL = https://developer.arm.com/-/media/Files/downloads/gnu-a/$(GCC_ARM_VERSION)/binrel/gcc-arm-$(GCC_ARM_VERSION)-x86_64-arm-none-linux-gnueabihf.tar.xz
GCC_ARM_DOWNLOAD_CACHED = .sdk-cache/gcc-arm-$(GCC_ARM_VERSION).tar.xz

# Texas Instruments PRU cross-compiler
# https://www.ti.com/tool/PRU-CGT#downloads
TI_PRU_VERSION ?= 2.3.3
TI_PRU_DOWNLOAD_URL = https://software-dl.ti.com/codegen/esd/cgt_public_sw/PRU/$(TI_PRU_VERSION)/ti_cgt_pru_$(TI_PRU_VERSION)_linux_installer_x86.bin
TI_PRU_DOWNLOAD_CACHED = .sdk-cache/ti-pru-$(TI_PRU_VERSION).elf

# GCC-based PRU cross-compiler
# https://github.com/dinuxbg/gnupru/releases
GCC_PRU_VERSION ?= 2021.07
GCC_PRU_DOWNLOAD_URL = https://github.com/dinuxbg/gnupru/releases/download/$(GCC_PRU_VERSION)/pru-elf-$(GCC_PRU_VERSION).amd64.tar.xz
GCC_PRU_DOWNLOAD_CACHED = .sdk-cache/gcc-pru-$(GCC_PRU_VERSION).tar.xz

#
# Docker-related variables
#

DOCKER_IMAGE_TAG = bbb-cross-compile
DOCKER_BUILD_TARGET = .docker-build-$(DOCKER_IMAGE_TAG)
DOCKER_USER ?= $(shell id -u):$(shell id -g)

DOCKER_RUN_INTERACTIVE = docker run --rm \
	--user $(DOCKER_USER) \
	--interactive --tty \
	$(DOCKER_IMAGE_TAG)

DOCKER_RUN_IN_PROJECT = docker run --rm \
	--user $(DOCKER_USER) \
	--volume $(PROJECT):/project \
	--workdir /project \
	$(DOCKER_IMAGE_TAG)

#
# Help
# Running `make` or `make help` will print usage.
# This is intended to be a self-documenting Makefile.
#

.PHONY: help
help: ## Print Makefile usage
	printf "%s\n" "Supported Commands:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

#
# Container creation
#

.PHONY: build
build: | $(DOCKER_BUILD_TARGET) ## Build the Docker container

$(DOCKER_BUILD_TARGET): Dockerfile docker-entrypoint.sh
	@make clean-docker
	docker build \
		--tag $(DOCKER_IMAGE_TAG) \
		--build-arg GCC_ARM_CACHED=$(GCC_ARM_DOWNLOAD_CACHED) \
		--build-arg TI_PRU_CACHED=$(TI_PRU_DOWNLOAD_CACHED) \
		--build-arg GCC_PRU_CACHED=$(GCC_PRU_DOWNLOAD_CACHED) \
		.
	touch $(DOCKER_BUILD_TARGET)

#
# Container usage
#

.PHONY: run
run: | $(DOCKER_BUILD_TARGET) ## Run an arbitrary command in the Docker container
	@:$(call check_defined, CMD)
	$(DOCKER_RUN_INTERACTIVE) $(CMD)

.PHONY: ti-pru
ti-pru: | $(DOCKER_BUILD_TARGET) ## Make PROJECT with TI PRU SDK
	@:$(call check_defined, PROJECT)
	$(DOCKER_RUN_IN_PROJECT) \
		make PRU_CGT=/ti-pru $(ARGS)

.PHONY: gcc-pru
gcc-pru: | $(DOCKER_BUILD_TARGET) ## Make PROJECT with GCC PRU SDK
	@:$(call check_defined, PROJECT)
	$(DOCKER_RUN_IN_PROJECT) \
		make CROSS_COMPILE=/gcc-pru/bin/pru- $(ARGS)

.PHONY: gcc-arm
gcc-arm: | $(DOCKER_BUILD_TARGET) ## Make PROJECT with GCC ARM SDK
	@:$(call check_defined, PROJECT)
	$(DOCKER_RUN_IN_PROJECT) \
		make CROSS_COMPILE=/gcc-arm/bin/arm-none-linux-gnueabihf- $(ARGS)

#
# SDK Downloads
#

.PHONY: sdk-cache
sdk-cache: $(GCC_ARM_DOWNLOAD_CACHED) $(TI_PRU_DOWNLOAD_CACHED) $(GCC_PRU_DOWNLOAD_CACHED)

$(DOCKER_BUILD_TARGET): $(GCC_ARM_DOWNLOAD_CACHED)
$(GCC_ARM_DOWNLOAD_CACHED):
	@echo "Using --insecure due to SSL certificate problem: unable to get local issuer certificate"
	curl --silent --location --create-dirs --insecure --output $@ $(GCC_ARM_DOWNLOAD_URL)

$(DOCKER_BUILD_TARGET): $(TI_PRU_DOWNLOAD_CACHED)
$(TI_PRU_DOWNLOAD_CACHED):
	curl --silent --location --create-dirs --output $@ $(TI_PRU_DOWNLOAD_URL)

$(DOCKER_BUILD_TARGET): $(GCC_PRU_DOWNLOAD_CACHED)
$(GCC_PRU_DOWNLOAD_CACHED):
	curl --silent --location --create-dirs --output $@ $(GCC_PRU_DOWNLOAD_URL)

#
# Housekeeping
#

.PHONY: clean
clean: clean-docker clean-cache ## Delete project artifacts

.PHONY: clean-docker
clean-docker: ## Delete the Docker container
	docker image rm --force $(DOCKER_IMAGE_TAG) || true
	rm -f $(DOCKER_BUILD_TARGET)

.PHONY: clean-sdk-cache
clean-sdk-cache: ## Delete the cached SDK downloads
	rm -Rf .sdk-cache
