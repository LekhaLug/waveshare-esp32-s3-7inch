# Makefile для ESPHome-компіляції та прошивки
# Автор: Copilot для Олексія
DEVICE = waveshare-7inch
VENV_PATH=../.venv
ACTIVATE=$(VENV_PATH)/bin/activate
YAML_FILE=config.yaml
BUILD_DIR=.esphome/build/$(DEVICE)/.pioenvs/$(DEVICE)
BIN_FILE=$(BUILD_DIR)/firmware.bin
BIN_FILE_OTA=$(BUILD_DIR)/firmware.ota.bin
OTA_HOST=$(DEVICE)  # Заміни на IP твоєї ESP

# Порт для прошивки (уточни при потребі)
PORT=/dev/ttyACM0

all: compile

compile:
	@if [ ! -f "$(ACTIVATE)" ]; then \
		echo "❌ Virtualenv не знайдено: $(ACTIVATE)"; \
		exit 1; \
	fi
	@echo "✅ Активація venv..."
	@. $(ACTIVATE) && \
	esphome compile $(YAML_FILE)
	./copy_firmware_factory_to_shared

run: #compile
	@if [ ! -f "$(BIN_FILE)" ]; then \
		echo "❌ firmware.bin не знайдено: $(BIN_FILE)"; \
		exit 1; \
	fi
	@. $(ACTIVATE) && esphome run $(YAML_FILE)
	@echo "🚀 Прошивка ESP через esptool..."
	@esptool.py --chip esp32s3 --port $(PORT) --baud 460800 write_flash -z 0x0 $(BIN_FILE)

ota: compile
	@if [ -f "$(BIN_FILE)" ]; then \
		echo "📡 OTA-прошивка на $(OTA_HOST)..."; \
		echo "🔄 Підміна firmware.bin → firmware.ota.bin"; \
		mv "$(BIN_FILE)" "$(BIN_FILE).orig" ; \
		cp "$(BIN_FILE_OTA)" "$(BIN_FILE)" ; \
		echo "🚀 OTA-прошивка через esphome upload" ; \
		. "$(ACTIVATE)" && esphome upload "$(YAML_FILE)" --device $(OTA_HOST); \
		echo "♻️ Відновлення firmware.bin" ; \
		mv "$(BIN_FILE).orig" "$(BIN_FILE)" ; \
		echo "✅ Готово!" ; \
	else \
		echo "❌ firmware.bin не знайдено: $(BIN_FILE)"; \
		exit 1; \
	fi
#		. python espota.py -i $(OTA_HOST) -p 3232 -f $(BUILD_DIR)/firmware.ota.bin; \

clean:
	@echo "🧹 Очистка build-файлів..."
	@rm -rf .esphome/build/*



check:
	@test -f $(BIN_FILE) && \
	echo "✅ firmware.bin знайдено" || \
	echo "❌ firmware.bin не знайдено"

.PHONY: all compile run clean check