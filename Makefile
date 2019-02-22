# On OSX the PATH variable isn't exported unless "SHELL" is also set, see: http://stackoverflow.com/a/25506676
SHELL = /bin/bash
NODE_BINDIR = ./node_modules/.bin
export PATH := $(NODE_BINDIR):$(PATH)
LOGNAME ?= $(shell logname)

# adding the name of the user's login name to the template file, so that
# on a multi-user system several users can run this without interference
TEMPLATE_POT ?= /tmp/template-$(LOGNAME).pot

# Where to find input files (it can be multiple paths).
INPUT_FILES = ./dev

# Where to write the files generated by this makefile.
OUTPUT_DIR = ./dev

# Available locales for the app.
LOCALES = en_GB fr_FR it_IT

# Name of the generated .po files for each available locale.
LOCALE_FILES ?= $(patsubst %,$(OUTPUT_DIR)/locale/%/LC_MESSAGES/app.po,$(LOCALES))

GETTEXT_SOURCES ?= $(shell find $(INPUT_FILES) -name '*.jade' -o -name '*.html' -o -name '*.js' -o -name '*.vue' 2> /dev/null)

# Makefile Targets
.PHONY: clean makemessages translations all

all:
	@echo choose a target from: clean makemessages translations

clean:
	rm -f $(TEMPLATE_POT) $(OUTPUT_DIR)/translations.json

makemessages: $(TEMPLATE_POT)

translations: ./$(OUTPUT_DIR)/translations.json

# Create a main .pot template, then generate .po files for each available language.
# Thanx to Systematic: https://github.com/Polyconseil/systematic/blob/866d5a/mk/main.mk#L167-L183
$(TEMPLATE_POT): $(GETTEXT_SOURCES)
# `dir` is a Makefile built-in expansion function which extracts the directory-part of `$@`.
# `$@` is a Makefile automatic variable: the file name of the target of the rule.
# => `mkdir -p /tmp/`
	mkdir -p $(dir $@)
# Extract gettext strings from templates files and create a POT dictionary template.
	gettext-extract --quiet --attribute v-translate --output $@ $(GETTEXT_SOURCES)
# Generate .po files for each available language.
	@for lang in $(LOCALES); do \
		export PO_FILE=$(OUTPUT_DIR)/locale/$$lang/LC_MESSAGES/app.po; \
		mkdir -p $$(dirname $$PO_FILE); \
		if [ -f $$PO_FILE ]; then  \
			echo "msgmerge --update $$PO_FILE $@"; \
			msgmerge --lang=$$lang --update $$PO_FILE $@ || break ;\
		else \
			msginit --no-translator --locale=$$lang --input=$@ --output-file=$$PO_FILE || break ; \
			msgattrib --no-wrap --no-obsolete -o $$PO_FILE $$PO_FILE || break; \
		fi; \
	done;

$(OUTPUT_DIR)/translations.json: $(LOCALE_FILES)
	mkdir -p $(OUTPUT_DIR)
	gettext-compile --output $@ $(LOCALE_FILES)
