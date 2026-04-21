APP_NAME = ClaudeUsage
VERSION = 1.1.3
BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/release

.PHONY: build bundle clean install zip

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	cp Sources/ClaudeUsage/Info.plist $(BUNDLE)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/
	codesign --force --sign - $(BUNDLE)
	@echo "Built $(BUNDLE) v$(VERSION)"

zip: bundle
	rm -f $(APP_NAME)-$(VERSION).zip
	ditto -c -k --keepParent $(BUNDLE) $(APP_NAME)-$(VERSION).zip
	@echo "Created $(APP_NAME)-$(VERSION).zip"

install: bundle
	rm -rf /Applications/$(BUNDLE)
	cp -R $(BUNDLE) /Applications/
	@echo "Installed to /Applications/$(BUNDLE)"

clean:
	swift package clean
	rm -rf $(BUNDLE) *.zip
