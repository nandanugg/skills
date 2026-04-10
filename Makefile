SKILLS := $(patsubst %/SKILL.md,%,$(wildcard */SKILL.md))
LEGACY_SKILLS := tmux_mode
UNLINK_SKILLS := $(sort $(SKILLS) $(LEGACY_SKILLS))

# Destinations
CLAUDE_BASE := $(HOME)/.claude/skills
CODEX_BASE := $(HOME)/.agents/skills
OPENCODE_BASE := $(HOME)/.config/opencode/skills

define SKILL_RULE
$(CLAUDE_BASE)/$(1)/SKILL.md: $(1)/SKILL.md
	mkdir -p "$$(@D)"
	ln -sfn "$$(CURDIR)/$$<" "$$@"

$(CODEX_BASE)/$(1)/SKILL.md: $(1)/SKILL.md
	mkdir -p "$$(@D)"
	ln -sfn "$$(CURDIR)/$$<" "$$@"

$(OPENCODE_BASE)/$(1)/SKILL.md: $(1)/SKILL.md
	mkdir -p "$$(@D)"
	ln -sfn "$$(CURDIR)/$$<" "$$@"

ALL_TARGETS += $(CLAUDE_BASE)/$(1)/SKILL.md \
               $(CODEX_BASE)/$(1)/SKILL.md \
               $(OPENCODE_BASE)/$(1)/SKILL.md 
endef

$(foreach skill,$(SKILLS),$(eval $(call SKILL_RULE,$(skill))))

.PHONY: init unlink

init: $(ALL_TARGETS)

unlink:
	@set -e; \
	for skill in $(UNLINK_SKILLS); do \
		rm -f "$(CLAUDE_BASE)/$$skill/SKILL.md"; \
		rm -f "$(CODEX_BASE)/$$skill/SKILL.md"; \
		rm -f "$(OPENCODE_BASE)/$$skill/SKILL.md"; \
		rmdir "$(CLAUDE_BASE)/$$skill" 2>/dev/null || true; \
		rmdir "$(CODEX_BASE)/$$skill" 2>/dev/null || true; \
		rmdir "$(OPENCODE_BASE)/$$skill" 2>/dev/null || true; \
	done
