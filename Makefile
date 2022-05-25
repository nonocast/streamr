SRC=src
BUILD=build
TARGET=$(BUILD)/app

all: $(BUILD) $(TARGET)

$(TARGET): $(SRC)/main.swift $(BUILD)/foo.o
	swiftc -import-objc-header $(SRC)/bridge.h -Iinclude -lrtmp -Llib -o $@ $^

$(BUILD):
	@mkdir -p $@

$(BUILD)/foo.o : $(SRC)/foo.c
	clang -c -o $@ $<

run: $(TARGET)
	@$(TARGET)

clean:
	@rm -rf $(BUILD)

.PHONY: clean run all