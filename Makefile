SKILLS := $(patsubst %/SKILL.md,%,$(wildcard */SKILL.md))

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

.PHONY: init

init: $(ALL_TARGETS)
