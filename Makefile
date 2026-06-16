# Get the absolute path of the current directory, then extract the last part
PROJECT_NAME := $(notdir $(patsubst %/,%,$(CURDIR)))

# Use it to define your output file
OUTPUT := $(PROJECT_NAME)

.SILENT:

build: clear
	mkdir -p build/
	odin build src/ -out:build/$(OUTPUT)

clear:
	rm -rf build

run: build
	./build/$(OUTPUT)
