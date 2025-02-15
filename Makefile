WEST="${PWD}/.pyenv/bin/west"

help:
	@echo "Make targets:"
	@grep '^[^#[:space:]].*:' Makefile | grep -v ^.PHONY | sed 's/\(.*\):.*/  \1/g'

build_kyria: build_kyria_left .WAIT build_kyria_right

build_kyria_left:
	@mkdir -p ./build/artifacts
	${WEST} build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="kyria_left nice_view_adapter nice_view" && \
	cp build/zephyr/zmk.uf2 kyria_left-nice_nano_v2-zmk.uf2

build_kyria_right:
	@mkdir -p ./build/artifacts
	${WEST} build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="kyria_right nice_view_adapter nice_view" && \
	cp build/zephyr/zmk.uf2 kyria_right-nice_nano_v2-zmk.uf2

build_kyria_settings_reset:
	@mkdir -p ./build/artifacts
	${WEST} build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="settings_reset" && \
	cp build/zephyr/zmk.uf2 kyria_settings_reset-nice_nano_v2-zmk.uf2

build_dactyl_gaming:
	@mkdir -p ./build/artifacts
	${WEST} build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="dactyl_gaming" -DZMK_EXTRA_MODULES="${PWD}/shields/dactyl_gaming" && \
	cp build/zephyr/zmk.uf2 dactyl_gaming-nice_nano_v2-zmk.uf2

build_dactyl_gaming_settings_reset:
	@mkdir -p ./build/artifacts
	${WEST} build --pristine -s zmk/app -b "nice_nano_v2" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="settings_reset" -DZMK_EXTRA_MODULES="${PWD}/shields/dactyl_gaming" && \
	cp build/zephyr/zmk.uf2 dactyl_gaming_settings_reset-nice_nano_v2-zmk.uf2

copy_kyria: copy_kyria_left .WAIT copy_kyria_right

copy_kyria_left:
	@while ! cp ./kyria_left-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria_left] ..."; \
		sleep 1s; \
	done

copy_kyria_right:
	@while ! cp ./kyria_right-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria_right] ..."; \
		sleep 1s; \
	done

copy_kyria_gaming_settings_reset:
	@while ! cp ./kyria_settings_reset-nice_nano_v2-zmk.uf2 /run/media/pbogut/NICENANO/ 2> /dev/null; do \
		echo "Waiting for device [kyria] ..."; \
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

patch:
	git -C "${PWD}/zmk" apply  < "${PWD}/patch/nice_view_battery_percentage.patch"

update:
	git -C "${PWD}/zmk" apply -R < "${PWD}/patch/nice_view_battery_percentage.patch"; \
	${WEST} update; \
	git -C "${PWD}/zmk" apply < "${PWD}/patch/nice_view_battery_percentage.patch";

pyenv:
	python -m venv "${PWD}/.pyenv"
	./.pyenv/bin/pip install -r requirements.txt

pip_install:
	pip install -r requirements.txt

flash_kyria: build_kyria_left .WAIT build_kyria_right .WAIT copy_kyria_left .WAIT copy_kyria_right
flash_kyria_left: build_kyria_left .WAIT copy_kyria_left
flash_kyria_right: build_kyria_right .WAIT copy_kyria_right

flash_dactyl_gaming: build_dactyl_gaming .WAIT copy_dactyl_gaming
