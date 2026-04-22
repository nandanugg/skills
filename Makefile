SKILLS := $(patsubst %/SKILL.md,%,$(wildcard */SKILL.md))
LEGACY_SKILLS := tmux_mode
UNLINK_SKILLS := $(sort $(SKILLS) $(LEGACY_SKILLS))

CLAUDE_BASE := $(HOME)/.claude/skills
CODEX_BASE := $(HOME)/.codex/skills
AGENTS_BASE := $(HOME)/.agents/skills
OPENCODE_BASE := $(HOME)/.config/opencode/skills
DEST_BASES := $(CLAUDE_BASE) $(CODEX_BASE) $(AGENTS_BASE) $(OPENCODE_BASE)

.PHONY: init unlink

init:
	@set -e; \
	for base in $(DEST_BASES); do \
		mkdir -p "$$base"; \
	done; \
	for skill in $(SKILLS); do \
		for base in $(DEST_BASES); do \
			dest="$$base/$$skill"; \
			mkdir -p "$$dest"; \
			for name in SKILL.md agents references scripts assets; do \
				entry="$$skill/$$name"; \
				if [ -e "$$entry" ]; then \
					rm -rf "$$dest/$$name"; \
					ln -s "$(CURDIR)/$$entry" "$$dest/$$name"; \
				fi; \
			done; \
			for entry in "$$skill"/*.md; do \
				if [ ! -e "$$entry" ]; then \
					continue; \
				fi; \
				name="$$(basename "$$entry")"; \
				if [ "$$name" = "SKILL.md" ]; then \
					continue; \
				fi; \
				rm -rf "$$dest/$$name"; \
				ln -s "$(CURDIR)/$$entry" "$$dest/$$name"; \
			done; \
		done; \
	done

unlink:
	@set -e; \
	for skill in $(UNLINK_SKILLS); do \
		for base in $(DEST_BASES); do \
			dest="$$base/$$skill"; \
			if [ -d "$$dest" ]; then \
				find "$$dest" -mindepth 1 -maxdepth 1 -exec rm -rf {} +; \
				rmdir "$$dest" 2>/dev/null || true; \
			fi; \
		done; \
	done
