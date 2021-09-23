# beaglebone-cross-compile Makefile
# This Makefile is intended to be self-documenting.
# Run `make` or `make usage` for instructions.

.DEFAULT_GOAL := usage

#
# Command runner variables
#

RUNNER_NAME = beaglebone-cross-compile
INSTALL_DIR ?= /usr/bin
VERSION_TAGS = 1.0.0

#
# SDK Cache download variables
#

CURL_OPTIONS ?=
CURL_OPTIONS += --location --create-dirs

# GCC-based ARM Linux cross-compiler
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
GCC_ARM_VERSION ?= 10.3-2021.07
GCC_ARM_DOWNLOAD_URL = https://developer.arm.com/-/media/Files/downloads/gnu-a/$(GCC_ARM_VERSION)/binrel/gcc-arm-$(GCC_ARM_VERSION)-x86_64-arm-none-linux-gnueabihf.tar.xz
GCC_ARM_DOWNLOAD_CACHED = .sdk-cache/gcc-arm-$(GCC_ARM_VERSION).tar.xz
VERSION_TAGS += gcc-arm-$(GCC_ARM_VERSION)

# GCC-based PRU cross-compiler
# https://github.com/dinuxbg/gnupru/releases
GCC_PRU_VERSION ?= 2021.07
GCC_PRU_DOWNLOAD_URL = https://github.com/dinuxbg/gnupru/releases/download/$(GCC_PRU_VERSION)/pru-elf-$(GCC_PRU_VERSION).amd64.tar.xz
GCC_PRU_DOWNLOAD_CACHED = .sdk-cache/gcc-pru-$(GCC_PRU_VERSION).tar.xz
VERSION_TAGS += gcc-pru-$(GCC_PRU_VERSION)

# Texas Instruments PRU cross-compiler
# https://www.ti.com/tool/PRU-CGT#downloads
TI_PRU_VERSION ?= 2.3.3
TI_PRU_DOWNLOAD_URL = https://software-dl.ti.com/codegen/esd/cgt_public_sw/PRU/$(TI_PRU_VERSION)/ti_cgt_pru_$(TI_PRU_VERSION)_linux_installer_x86.bin
TI_PRU_DOWNLOAD_CACHED = .sdk-cache/ti-pru-$(TI_PRU_VERSION).elf
VERSION_TAGS += ti-pru-$(TI_PRU_VERSION)

# Texas Instruments PRU support package
# https://git.ti.com/cgit/pru-software-support-package/pru-software-support-package/
TI_PRU_SUPPORT_VERSION ?= 5.9.0
TI_PRU_SUPPORT_DOWNLOAD_URL = https://git.ti.com/cgit/pru-software-support-package/pru-software-support-package/snapshot/pru-software-support-package-$(TI_PRU_SUPPORT_VERSION).tar.xz
TI_PRU_SUPPORT_DOWNLOAD_CACHED = .sdk-cache/ti-pru-support-$(TI_PRU_SUPPORT_VERSION).tar.xz
VERSION_TAGS += ti-pru-support-$(TI_PRU_SUPPORT_VERSION)

# Combine the version tags into a single identifier
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMBINED_VERSION_TAG = $(subst $(SPACE),_,$(VERSION_TAGS))

#
# Docker-related variables
#

DOCKER_IMAGE_TAG ?= $(RUNNER_NAME):$(COMBINED_VERSION_TAG)
DOCKER_VOLUME_NAME ?= $(RUNNER_NAME)_$(COMBINED_VERSION_TAG)

DOCKER_BUILD_TARGET = .docker-build-$(COMBINED_VERSION_TAG)
DOCKER_VOLUME_TARGET = .docker-volume-$(COMBINED_VERSION_TAG)

DOCKER_USER ?= $(shell id -u):$(shell id -g)

DOCKER_RUN_ARGS ?=
DOCKER_RUN_ARGS += --user $(DOCKER_USER)
ifdef BEAGLEBONE_PROJECT_DIR
DOCKER_RUN_ARGS += --volume $(BEAGLEBONE_PROJECT_DIR):/beaglebone/project --workdir /beaglebone/project
endif
ifdef BEAGLEBONE_KERNEL_DIR
DOCKER_RUN_ARGS += --volume $(BEAGLEBONE_KERNEL_DIR):/beaglebone/kernel
endif

usage: ## Print Makefile usage
	printf "%s\n" "Supported Goals:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'
	printf "\n%s\n" 		"Supported Variables:"
	printf "%-30s %s\n" "INSTALL_DIR" 						"directory to install runner into; default: $(INSTALL_DIR)"
	printf "%-30s %s\n" "BEAGLEBONE_PROJECT_DIR" 	"directory to mount at '/beaglebone/project'"
	printf "%-30s %s\n" "BEAGLEBONE_KERNEL_DIR" 	"directory to mount at '/beaglebone/kernel'"
	printf "%-30s %s\n" "GCC_ARM_VERSION" 				"default: $(GCC_ARM_VERSION)"
	printf "%-30s %s\n" "GCC_PRU_VERSION" 				"default: $(GCC_PRU_VERSION)"
	printf "%-30s %s\n" "TI_PRU_VERSION" 					"default: $(TI_PRU_VERSION)"
	printf "%-30s %s\n" "TI_PRU_SUPPORT_VERSION" 	"default: $(TI_PRU_SUPPORT_VERSION)"
.PHONY: usage
.SILENT: usage

#
# Installation
#

install: ## Install the runner script in INSTALL_DIR
	ln -s $(CURDIR)/host-entrypoint.sh $(INSTALL_DIR)/$(RUNNER_NAME)
.PHONY: install

#
# Docker
#

build-docker-image: | $(DOCKER_BUILD_TARGET) ## Build a Docker image with the SDKs
.PHONY: build-docker-image

$(DOCKER_BUILD_TARGET): Dockerfile docker-entrypoint.sh
	@$(MAKE) clean-docker-image
	DOCKER_BUILDKIT=1 docker build \
		--tag $(DOCKER_IMAGE_TAG) \
		--build-arg GCC_ARM_VERSION=$(GCC_ARM_VERSION) \
		--build-arg GCC_ARM_CACHED=$(GCC_ARM_DOWNLOAD_CACHED) \
		--build-arg GCC_PRU_VERSION=$(GCC_PRU_VERSION) \
		--build-arg GCC_PRU_CACHED=$(GCC_PRU_DOWNLOAD_CACHED) \
		--build-arg TI_PRU_VERSION=$(TI_PRU_VERSION) \
		--build-arg TI_PRU_CACHED=$(TI_PRU_DOWNLOAD_CACHED) \
		--build-arg TI_PRU_SUPPORT_VERSION=$(TI_PRU_SUPPORT_VERSION) \
		--build-arg TI_PRU_SUPPORT_CACHED=$(TI_PRU_SUPPORT_DOWNLOAD_CACHED) \
		.
	@touch $(DOCKER_BUILD_TARGET)

mount-sdks: | $(DOCKER_VOLUME_TARGET) ## Mount the installed SDKs as a Docker volume
	MOUNTPOINT=$$( \
		docker volume inspect $(DOCKER_VOLUME_NAME) \
		| grep Mountpoint \
		| sed 's/.*: "\(.*\)",/\1/' \
	); \
	[ -n "$$MOUNTPOINT" ] && echo "$$MOUNTPOINT"
.PHONY: mount-sdks
.SILENT: mount-sdks

$(DOCKER_VOLUME_TARGET): $(DOCKER_BUILD_TARGET)
	@$(MAKE) clean-docker-volume
	docker volume create $(DOCKER_VOLUME_NAME)
	docker run --rm \
		--user $(DOCKER_USER) \
		--volume $(DOCKER_VOLUME_NAME):/beaglebone/sdks \
		$(DOCKER_IMAGE_TAG)
	@touch $(DOCKER_VOLUME_TARGET)

run: | $(DOCKER_BUILD_TARGET) ## Run a COMMAND in the Docker container
	docker run --rm $(DOCKER_RUN_ARGS) $(DOCKER_IMAGE_TAG) $(COMMAND)
.PHONY: run

#
# SDK Downloads
#

download-sdks: ## Download SDKs installers to the '.sdk-cache' directory
.PHONY: download-sdks

$(GCC_ARM_DOWNLOAD_CACHED):
	@:$(info Downloading the GCC ARM SDK: $(GCC_ARM_VERSION))
	@:$(info Using --insecure due to SSL certificate problem: unable to get local issuer certificate)
	curl --insecure $(CURL_OPTIONS) --output $@ $(GCC_ARM_DOWNLOAD_URL)
download-sdks: | $(GCC_ARM_DOWNLOAD_CACHED)
$(DOCKER_BUILD_TARGET): $(GCC_ARM_DOWNLOAD_CACHED)

$(GCC_PRU_DOWNLOAD_CACHED):
	@:$(info Downloading the GCC PRU SDK: $(GCC_PRU_VERSION))
	curl $(CURL_OPTIONS) --output $@ $(GCC_PRU_DOWNLOAD_URL)
download-sdks: | $(GCC_PRU_DOWNLOAD_CACHED)
$(DOCKER_BUILD_TARGET): $(GCC_PRU_DOWNLOAD_CACHED)

$(TI_PRU_DOWNLOAD_CACHED):
	@:$(info Downloading the TI PRU SDK: $(TI_PRU_VERSION))
	curl $(CURL_OPTIONS) --output $@ $(TI_PRU_DOWNLOAD_URL)
download-sdks: | $(TI_PRU_DOWNLOAD_CACHED)
$(DOCKER_BUILD_TARGET): $(TI_PRU_DOWNLOAD_CACHED)

$(TI_PRU_SUPPORT_DOWNLOAD_CACHED):
	@:$(info Downloading the TI PRU Support Package: $(TI_PRU_SUPPORT_VERSION))
	curl $(CURL_OPTIONS) --output $@ $(TI_PRU_SUPPORT_DOWNLOAD_URL)
download-sdks: | $(TI_PRU_SUPPORT_DOWNLOAD_CACHED)
$(DOCKER_BUILD_TARGET): $(TI_PRU_SUPPORT_DOWNLOAD_CACHED)

#
# Housekeeping
#

clean: ## Delete all artifacts
.PHONY: clean

clean-docker-image: ## Delete the Docker image for the current SDK versions
	docker image rm --force $(DOCKER_IMAGE_TAG) || true
	rm --force $(DOCKER_BUILD_TARGET)
.PHONY: clean-docker-image

clean-docker-volume: ## Delete the Docker volume for the current SDK versions
	docker volume rm --force $(DOCKER_VOLUME_NAME) || true
	rm --force $(DOCKER_VOLUME_TARGET)
.PHONY: clean-docker-volume

clean-all-docker-images: ## Delete Docker images for all SDK versions
	RUNNER_IMAGES=`docker image ls -q "$(RUNNER_NAME)"` ; \
	if [ -n "$$RUNNER_IMAGES" ] ; then \
		echo 'Removing all "$(RUNNER_NAME)" Docker images...' ; \
		docker image rm --force $$RUNNER_IMAGES ; \
		rm --force .docker-build-* ; \
	fi
.PHONY: clean-all-docker-images
.SILENT: clean-all-docker-images
clean: clean-all-docker-images

clean-all-docker-volumes: ## Delete Docker volumes for all SDK versions
	RUNNER_VOLUMES=`docker volume ls -q --filter name="$(RUNNER_NAME)_"` ; \
	if [ -n "$$RUNNER_VOLUMES" ] ; then \
		echo 'Removing all "$(RUNNER_NAME)" Docker volumes...' ; \
		docker volume rm --force $$RUNNER_VOLUMES ; \
		rm --force .docker-volume-* ; \
	fi
.PHONY: clean-all-docker-volumes
.SILENT: clean-all-docker-volumes
clean: clean-all-docker-volumes

clean-sdk-cache: ## Delete the SDK downloads cache
	rm --force --recursive .sdk-cache
.PHONY: clean-sdk-cache
clean: clean-sdk-cache
