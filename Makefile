swift-src = $(shell find src -type f -name "*.swift")

all: build/app

run: build/app
	@$<

test: build/gtest build/swifttest run/gtest

run/gtest: build/gtest
	@$<

run/swifttest: build/swifttest
	@$<

build/swifttest: test/test.swift $(swift-src)
	@swiftc -import-objc-header src/bridge.h -Iinclude -lrtmp -Llib -o $@ build/rtmpext.o $(subst src/app.swift, ,$(shell find src -type f -name "*.swift")) test/test.swift

build/gtest: build/rtmpext.o test/rtmpext_test.cc
	@mkdir -p $(@D)
	@clang++ -std=c++11 `pkg-config --cflags --libs gtest` -Bstatic -Iinclude -lrtmp -Llib -lgtest_main -o $@ $^

build/app: build/rtmpext.o $(swift-src)
	@mkdir -p $(@D)
	@swiftc -import-objc-header src/bridge.h -Iinclude -lrtmp -L/usr/local/lib -o $@ build/rtmpext.o $(swift-src)

build/rtmpext.o: src/rtmp/rtmpext.c
	@mkdir -p $(@D)
	@clang -mmacosx-version-min=12.0 -arch x86_64 -arch arm64 -c -o $@ $<

clean:
	@rm -rf build

.PHONY: clean run run/swiftest run/gtest test all