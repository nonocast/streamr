CC=clang -arch arm64 -arch x86_64 -mmacosx-version-min=12.0
SWIFTC=swiftc
SWIFTSRC=$(shell find $(SRC) -type f -name "*.swift")
SRC=src
BUILD=build
TARGET=$(BUILD)/app

all: $(BUILD) $(TARGET)

$(TARGET): $(SWIFTSRC) $(BUILD)/rtmpext.o
	$(SWIFTC) -import-objc-header $(SRC)/bridge.h -Iinclude -lrtmp -Llib -o $@ $^

$(BUILD):
	@mkdir -p $@

$(BUILD)/rtmpext.o : $(SRC)/rtmpext.c
	$(CC) -c -o $@ $<

run: $(TARGET)
	@$(TARGET)

clean:
	@rm -rf $(BUILD)

.PHONY: clean run all