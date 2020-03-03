NAME=kubectl-tmux-exec
VERSION=0.0.2

OUTPUT_DIR=output
RELEASE_FILE_NAME=$(NAME)-$(VERSION).tar.gz
RELEASE_FILE_PATH=$(OUTPUT_DIR)/$(RELEASE_FILE_NAME)
SIG_FILE_NAME=$(NAME)-$(VERSION).asc
SIG_FILE_PATH=$(OUTPUT_DIR)/$(SIG_FILE_NAME)

all: $(RELEASE_FILE_PATH) $(SIG_FILE_PATH)

mk-output-dir:
	mkdir -p $(OUTPUT_DIR)

$(RELEASE_FILE_PATH): mk-output-dir
	tar czvf $(RELEASE_FILE_PATH) bin/ LICENSE

build: $(RELEASE_FILE_PATH)

$(SIG_FILE_PATH): $(RELEASE_FILE_PATH)
	gpg -ab $(RELEASE_FILE_PATH)

sign: $(SIG_FILE_PATH)

clean:
	rm -rf $(RELEASE_FILE_PATH)

.PHONY: build sign clean mk-output-dir
