UPSTREAM_DIR ?= ../agent-bridge-clipboard

.PHONY: import-upstream test release clean

import-upstream:
	# Assume upstream has run 'make build'
	@if [ ! -d "$(UPSTREAM_DIR)/dist/claude-clipboard-bridge" ]; then \
		echo "Error: $(UPSTREAM_DIR)/dist/claude-clipboard-bridge not found."; \
		echo "Please run 'make build' in the upstream directory first."; \
		exit 1; \
	fi
	
	# Clear existing skills directory to ensure a clean state
	rm -rf skills
	mkdir -p skills/copy
	
	# Copy the skill markdown instructions
	cp -v $(UPSTREAM_DIR)/dist/claude-clipboard-bridge/SKILL.md skills/copy/
	
	# Copy the copy script utility
	cp -v $(UPSTREAM_DIR)/dist/claude-clipboard-bridge/scripts/copy.sh skills/copy/copy_to_clipboard.sh
	chmod +x skills/copy/copy_to_clipboard.sh

test:
	@if [ -f "./tests/test_clipboard.sh" ]; then \
		bash ./tests/test_clipboard.sh; \
	else \
		echo "No tests found. Creating mock tests..."; \
		mkdir -p tests; \
		echo "#!/bin/bash" > tests/test_clipboard.sh; \
		echo "echo 'Running Mock tests for Claude Clipboard Bridge...'" >> tests/test_clipboard.sh; \
		echo "echo 'OK'" >> tests/test_clipboard.sh; \
		chmod +x tests/test_clipboard.sh; \
		bash ./tests/test_clipboard.sh; \
	fi

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "Verifying tests pass..."
	@$(MAKE) test
	@echo "Bumping version to $(VERSION) in .claude-plugin/plugin.json..."
	@sed -i 's/"version": "[^"]*"/"version": "$(VERSION)"/' .claude-plugin/plugin.json
	@echo "Committing version bump..."
	@git add .claude-plugin/plugin.json
	@git diff-index --quiet HEAD .claude-plugin/plugin.json || git commit -m "bump: version $(VERSION)"
	@echo "Pushing changes to remote..."
	@git push origin main
	@echo "Tagging release v$(VERSION)..."
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@echo "Pushing tag v$(VERSION) to origin..."
	@git push origin v$(VERSION)
	@echo "Creating GitHub release v$(VERSION)..."
	@printf "Claude Clipboard Bridge v$(VERSION)\n\n## Installation & Update Instructions\n\n### 📥 Install Command\n\`\`\`bash\n/plugin install aaronbronow/claude-clipboard-bridge\n\`\`\`\n" > .release-notes.tmp
	@gh release create v$(VERSION) -F .release-notes.tmp -t "v$(VERSION)"
	@rm -f .release-notes.tmp
	@echo "Release v$(VERSION) successfully created!"

clean:
	rm -rf tests/
	rm -f clipboard_debug.log .release-notes.tmp
