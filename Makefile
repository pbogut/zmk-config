help:
	@echo "Make targets:"
	@grep '^[^#[:space:]].*:' Makefile | grep -v ^.PHONY | sed 's/\(.*\):.*/  \1/g'

KYRIA_DONGLE_BOARD ?= nice_nano_v2
KYRIA_DONGLE_MOUNT ?= /run/media/pbogut/NICENANO
ZMK_DIR ?= $(CURDIR)/zmk
ZMK_PATCHES := nice_view_battery_percentage.patch volatile_output_selection.patch

build_kyria_left build_kyria_right build_kyria_dongle build_kyria_settings_reset: | patch

build_kyria: build_kyria_left .WAIT build_kyria_right .WAIT build_kyria_dongle

build_kyria_left:
	@mkdir -p ./build/artifacts
	west build --pristine -d build/kyria_left -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="kyria_left" && \
	cp build/kyria_left/zephyr/zmk.uf2 kyria_left-nice_nano_v2-zmk.uf2

build_kyria_right:
	@mkdir -p ./build/artifacts
	west build --pristine -d build/kyria_right -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="kyria_right" && \
	cp build/kyria_right/zephyr/zmk.uf2 kyria_right-nice_nano_v2-zmk.uf2

build_kyria_dongle:
	@mkdir -p ./build/artifacts
	west build --pristine -d build/kyria_dongle -s zmk/app -b "$(KYRIA_DONGLE_BOARD)" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="kyria_dongle" -DZMK_EXTRA_MODULES="${PWD}/custom_modules/battery_usb" && \
	cp build/kyria_dongle/zephyr/zmk.uf2 kyria_dongle-$(KYRIA_DONGLE_BOARD)-zmk.uf2

build_kyria_settings_reset:
	@mkdir -p ./build/artifacts
	west build --pristine -d build/kyria_settings_reset -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="settings_reset" && \
	cp build/kyria_settings_reset/zephyr/zmk.uf2 kyria_settings_reset-nice_nano_v2-zmk.uf2

build_dactyl_gaming:
	@mkdir -p ./build/artifacts
	west build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="dactyl_gaming" -DZMK_EXTRA_MODULES="${PWD}/custom_modules/pbogut" && \
	cp build/zephyr/zmk.uf2 dactyl_gaming-nice_nano_v2-zmk.uf2

build_dactyl_gaming_settings_reset:
	@mkdir -p ./build/artifacts
	west build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="settings_reset" -DZMK_EXTRA_MODULES="${PWD}/custom_modules/pbogut" && \
	cp build/zephyr/zmk.uf2 dactyl_gaming_settings_reset-nice_nano_v2-zmk.uf2

copy_kyria: copy_kyria_left .WAIT copy_kyria_right .WAIT copy_kyria_dongle

copy_kyria_left:
	@while ! cp ./kyria_left-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria_left] ..."; \
		sleep 1s; \
	done
	@while mountpoint -q /run/media/pbogut/NICENANO; do sleep 1s; done

copy_kyria_right:
	@while ! cp ./kyria_right-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria_right] ..."; \
		sleep 1s; \
	done
	@while mountpoint -q /run/media/pbogut/NICENANO; do sleep 1s; done

copy_kyria_settings_reset:
	@while ! cp ./kyria_settings_reset-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria] ..."; \
		sleep 1s; \
	done

copy_kyria_dongle:
	@while ! cp ./kyria_dongle-$(KYRIA_DONGLE_BOARD)-zmk.uf2 "$(KYRIA_DONGLE_MOUNT)/" 2> /dev/null; do \
		echo "Waiting for device [kyria_dongle] ..."; \
		sleep 1s; \
	done

copy_dactyl_gaming:
	@while ! cp ./dactyl_gaming-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [dactyl_gaming] ..."; \
		sleep 1s; \
	done

copy_dactyl_gaming_settings_reset:
	@while ! cp ./dactyl_gaming_settings_reset-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [dactyl_gaming] ..."; \
		sleep 1s; \
	done

build_eql60:
	@mkdir -p ./build/artifacts
	west build --pristine -s zmk/app -b "boardsource_blok" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="boardsource5x12" && \
	cp build/zephyr/zmk.uf2 eql60-boardsource_blok-zmk.uf2

build_eql60_settings_reset:
	@mkdir -p ./build/artifacts
	west build --pristine -s zmk/app -b "boardsource_blok" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="settings_reset" && \
	cp build/zephyr/zmk.uf2 eql60_settings_reset-boardsource_blok-zmk.uf2

copy_eql60:
	@while ! cp ./eql60-boardsource_blok-zmk.uf2 /run/media/pbogut/RPI-RP2/ 2> /dev/null; do \
		echo "Waiting for device [eql60] ..."; \
		sleep 1s; \
	done

copy_eql60_settings_reset:
	@while ! cp ./eql60_settings_reset-boardsource_blok-zmk.uf2 /run/media/pbogut/RPI-RP2/ 2> /dev/null; do \
		echo "Waiting for device [eql60] ..."; \
		sleep 1s; \
	done

build_eql60_nn:
	@mkdir -p ./build/artifacts
	west build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="boardsource5x12 equals60_nnv2" -DZMK_EXTRA_MODULES="${PWD}/custom_modules/pbogut" && \
	cp build/zephyr/zmk.uf2 eql60-nice_nano_v2-zmk.uf2

copy_eql60_nn:
	@while ! cp ./eql60-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [eql60nn] ..."; \
		sleep 1s; \
	done

patch:
	@set -e; for name in $(ZMK_PATCHES); do \
		patch="$(CURDIR)/patch/$$name"; \
		if git -C "$(ZMK_DIR)" apply --reverse --check "$$patch" 2>/dev/null; then \
			echo "Already applied: $$name"; \
		else \
			echo "Applying: $$name"; \
			git -C "$(ZMK_DIR)" apply --check "$$patch"; \
			git -C "$(ZMK_DIR)" apply "$$patch"; \
		fi; \
	done

unpatch:
	@set -e; for name in $(ZMK_PATCHES); do \
		patch="$(CURDIR)/patch/$$name"; \
		if git -C "$(ZMK_DIR)" apply --reverse --check "$$patch" 2>/dev/null; then \
			echo "Reverting: $$name"; \
			git -C "$(ZMK_DIR)" apply --reverse "$$patch"; \
		else \
			echo "Checking unapplied patch: $$name"; \
			git -C "$(ZMK_DIR)" apply --check "$$patch"; \
		fi; \
	done

update:
	$(MAKE) unpatch
	west update
	west zephyr-export
	$(MAKE) patch

init:
	@test -f .west/config || west init -l config
	@if test -e "$(ZMK_DIR)/.git"; then $(MAKE) unpatch; fi
	west update
	west zephyr-export
	$(MAKE) patch

.PHONY: init update patch unpatch

pyenv:
	python -m venv "${PWD}/.pyenv"
	./.pyenv/bin/pip install -r requirements.txt

pip_install:
	pip install -r requirements.txt

flash_kyria: build_kyria .WAIT copy_kyria
flash_kyria_left: build_kyria_left .WAIT copy_kyria_left
flash_kyria_right: build_kyria_right .WAIT copy_kyria_right
flash_kyria_dongle: build_kyria_dongle .WAIT copy_kyria_dongle
flash_eql60: build_eql60 .WAIT copy_eql60
flash_eql60_nn: build_eql60_nn .WAIT copy_eql60_nn

flash_dactyl_gaming: build_dactyl_gaming .WAIT copy_dactyl_gaming
