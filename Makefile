# ok-linux Makefile
# Manages Talos Image Factory schematics and profile inspection
#
# Usage:
#   make show PROFILE=kubevirt
#   make build PROFILE=kubevirt
#   make show-all

FACTORY_URL := https://factory.talos.dev

# Default profile if not specified
PROFILE ?= kubevirt

PROFILE_DIR   := profiles/$(PROFILE)
SCHEMATIC_FILE := $(PROFILE_DIR)/schematic.yaml
PROFILE_FILE  := $(PROFILE_DIR)/profile.yaml

# ── Validation ────────────────────────────────────────────────────────────────

.PHONY: check-profile
check-profile:
	@if [ ! -d "$(PROFILE_DIR)" ]; then \
		echo "ERROR: Profile '$(PROFILE)' not found at $(PROFILE_DIR)"; \
		echo "Available profiles:"; \
		ls profiles/; \
		exit 1; \
	fi
	@if [ ! -f "$(SCHEMATIC_FILE)" ]; then \
		echo "ERROR: $(SCHEMATIC_FILE) not found"; \
		exit 1; \
	fi
	@if [ ! -f "$(PROFILE_FILE)" ]; then \
		echo "ERROR: $(PROFILE_FILE) not found"; \
		exit 1; \
	fi

# ── show ──────────────────────────────────────────────────────────────────────

.PHONY: show
show: check-profile ## Show profile summary (make show PROFILE=kubevirt)
	@echo ""
	@echo "┌─────────────────────────────────────────────┐"
	@echo "│  ok-linux Profile: $(PROFILE)"
	@echo "└─────────────────────────────────────────────┘"
	@echo ""
	@echo "Profile file:  $(PROFILE_FILE)"
	@echo "Schematic:     $(SCHEMATIC_FILE)"
	@echo ""
	@echo "── Talos ────────────────────────────────────────"
	@grep "version:" $(PROFILE_FILE)    | head -1 | awk '{printf "  Version:       %s\n", $$2}'
	@grep "schematic_id:" $(PROFILE_FILE) | head -1 | awk '{printf "  Schematic ID:  %s\n", $$2}'
	@grep "image:" $(PROFILE_FILE)      | head -1 | awk '{printf "  Image:         %s\n", $$2}'
	@echo ""
	@echo "── Extensions ───────────────────────────────────"
	@python3 -c "\
import yaml; \
d = yaml.safe_load(open('$(SCHEMATIC_FILE)')); \
exts = d.get('customization', {}).get('systemExtensions', {}).get('officialExtensions', []); \
[print('  -', e) for e in exts] if exts else print('  (none — base image)');"
	@echo ""
	@echo "── Kernel Args ──────────────────────────────────"
	@python3 -c "\
import yaml; \
d = yaml.safe_load(open('$(PROFILE_FILE)')); \
args = d.get('kernel_args', []); \
[print('  -', a) for a in args] if args else print('  (none)');"
	@echo ""

# ── show-all ──────────────────────────────────────────────────────────────────

.PHONY: show-all
show-all: ## Show summary for all profiles
	@for p in profiles/*/; do \
		$(MAKE) show PROFILE=$$(basename $$p) 2>/dev/null || true; \
	done

# ── build ─────────────────────────────────────────────────────────────────────

.PHONY: build
build: check-profile ## Submit schematic to Image Factory and update profile.yaml
	@echo "Submitting schematic for profile '$(PROFILE)'..."
	@echo "Schematic:"
	@cat $(SCHEMATIC_FILE) | grep -v "^#"
	@echo ""

	$(eval SCHEMATIC_ID := $(shell \
		grep -v "^#" $(SCHEMATIC_FILE) | \
		curl -sf -X POST \
			-H "Content-Type: application/yaml" \
			--data-binary @- \
			$(FACTORY_URL)/schematics | \
		python3 -c "import sys,json; print(json.load(sys.stdin)['id'])"))

	@if [ -z "$(SCHEMATIC_ID)" ]; then \
		echo "ERROR: Failed to get schematic ID from Image Factory"; \
		exit 1; \
	fi

	@echo "Schematic ID: $(SCHEMATIC_ID)"

	$(eval TALOS_VERSION := $(shell grep "version:" $(PROFILE_FILE) | head -1 | awk '{print $$2}'))
	$(eval IMAGE_URL := $(FACTORY_URL)/installer/$(SCHEMATIC_ID):$(TALOS_VERSION))

	@echo "Image URL:    $(IMAGE_URL)"
	@echo ""

	@# Update profile.yaml with new schematic_id and image
	@python3 -c "\
import yaml; \
f = '$(PROFILE_FILE)'; \
d = yaml.safe_load(open(f)); \
d['talos']['schematic_id'] = '$(SCHEMATIC_ID)'; \
d['talos']['image'] = '$(IMAGE_URL)'; \
open(f, 'w').write(yaml.dump(d, default_flow_style=False, sort_keys=False));"

	@echo "✓ profile.yaml updated:"
	@echo "    schematic_id: $(SCHEMATIC_ID)"
	@echo "    image:        $(IMAGE_URL)"
	@echo ""
	@echo "Next step: update ok-cluster cluster-config.yaml:"
	@echo "    os:"
	@echo "      schematic_id: $(SCHEMATIC_ID)"

# ── verify ────────────────────────────────────────────────────────────────────

.PHONY: verify
verify: check-profile ## Verify schematic ID matches current schematic.yaml
	@echo "Verifying schematic for profile '$(PROFILE)'..."

	$(eval CURRENT_ID := $(shell grep "schematic_id:" $(PROFILE_FILE) | head -1 | awk '{print $$2}'))
	@if [ -z "$(CURRENT_ID)" ]; then \
		echo "ERROR: No schematic_id found in $(PROFILE_FILE)"; \
		exit 1; \
	fi

	$(eval COMPUTED_ID := $(shell \
		grep -v "^#" $(SCHEMATIC_FILE) | \
		curl -sf -X POST \
			-H "Content-Type: application/yaml" \
			--data-binary @- \
			$(FACTORY_URL)/schematics | \
		python3 -c "import sys,json; print(json.load(sys.stdin)['id'])"))

	@if [ "$(CURRENT_ID)" = "$(COMPUTED_ID)" ]; then \
		echo "✓ Schematic ID verified: $(CURRENT_ID)"; \
	else \
		echo "✗ Mismatch!"; \
		echo "  profile.yaml:  $(CURRENT_ID)"; \
		echo "  factory.talos.dev: $(COMPUTED_ID)"; \
		echo "  Run: make build PROFILE=$(PROFILE)"; \
		exit 1; \
	fi

# ── help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
