ROOT_SKILL := $(CURDIR)/SKILL.md

CLAUDE_DIR := $(HOME)/.claude/skills/tmux_mode
CODEX_DIR := $(HOME)/.agents/skills/tmux_mode
OPENCODE_DIR := $(HOME)/.config/opencode/skills/tmux_mode
GEMINI_DIR := $(HOME)/.gemini/skills/tmux_mode

TARGETS := \
	$(CLAUDE_DIR)/SKILL.md \
	$(CODEX_DIR)/SKILL.md \
	$(OPENCODE_DIR)/SKILL.md \
	$(GEMINI_DIR)/SKILL.md

.PHONY: init

init: $(TARGETS)

$(TARGETS): SKILL.md
	mkdir -p "$(@D)"
	ln -sfn "$(ROOT_SKILL)" "$@"
