NAME=kubectl-tmux-exec
VERSION=0.0.3

OUTPUT_DIR=output
RELEASE_FILE_NAME=$(NAME)-$(VERSION).tar.gz
RELEASE_FILE_PATH=$(OUTPUT_DIR)/$(RELEASE_FILE_NAME)
SIG_FILE_NAME=$(NAME)-$(VERSION).asc
SIG_FILE_PATH=$(OUTPUT_DIR)/$(SIG_FILE_NAME)
CHECKSUM_FILE_NAME=$(RELEASE_FILE_NAME).sha256
CHECKSUM_FILE_PATH=$(OUTPUT_DIR)/$(CHECKSUM_FILE_NAME)

ifeq ($(OS), Windows_NT)
    OS_UNAME := Windows
else
    OS_UNAME := $(shell uname -s)
endif

.PHONY: build sign checksum clean mk-output-dir

all: $(RELEASE_FILE_PATH) $(CHECKSUM_FILE_PATH)

build: $(RELEASE_FILE_PATH)

checksum: $(CHECKSUM_FILE_PATH)

sign: $(SIG_FILE_PATH)

mk-output-dir:
	mkdir -p $(OUTPUT_DIR)

clean:
	rm -rf $(RELEASE_FILE_PATH) $(CHECKSUM_FILE_PATH) $(SIG_FILE_PATH)

$(RELEASE_FILE_PATH): mk-output-dir
	tar czvf $(RELEASE_FILE_PATH) bin/ LICENSE

$(SIG_FILE_PATH): $(RELEASE_FILE_PATH)
	gpg -ab $(RELEASE_FILE_PATH)

$(CHECKSUM_FILE_PATH): $(RELEASE_FILE_PATH)
ifeq ($(OS_UNAME), Darwin)
	shasum -a 256 $(RELEASE_FILE_PATH) | awk '{print $$1}' > $(CHECKSUM_FILE_PATH)
else ifeq ($(OS_UNAME), Linux)
	sha256sum $(RELEASE_FILE_PATH) | awk '{print $$1}' > $(CHECKSUM_FILE_PATH)
else
	echo "Unsupported OS: $(OS_UNAME)"
	exit 1
endif
