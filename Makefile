APP_NAME = ClaudeUsage
VERSION = 1.1.2
BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/release

# Stable code signing identity. A self-signed cert in the login keychain is
# enough — the point is that the signature stays identical across rebuilds so
# macOS keychain "Always Allow" grants stick. Override to "-" for ad-hoc.
# See CLAUDE.md for one-time setup instructions.
CODESIGN_IDENTITY ?= ClaudeUsage Self-Signed

.PHONY: build bundle clean

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	cp Sources/ClaudeUsage/Info.plist $(BUNDLE)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/
	codesign --force --sign "$(CODESIGN_IDENTITY)" $(BUNDLE)
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
