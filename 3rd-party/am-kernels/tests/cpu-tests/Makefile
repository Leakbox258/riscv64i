.PHONY: all run gdb clean latest $(ALL)

BUILD_DIR ?= ./build
RESULT = $(BUILD_DIR)/.result
$(shell > $(RESULT))

COLOR_RED   = \033[1;31m
COLOR_GREEN = \033[1;32m
COLOR_NONE  = \033[0m

AM_KERNELS_CPU_TESTS_DIR ?= .
ABSTRACT_MACHINE_DIR ?= ${AM_KERNELS_CPU_TESTS_DIR}

ALL = $(basename $(notdir $(shell find $(AM_KERNELS_CPU_TESTS_DIR)/tests/. -name "*.c")))
ALL_BASE = $(notdir $(ALL))

all: $(addprefix Makefile., $(ALL_BASE))
	@echo "test list [$(words $(ALL)) item(s)]:" $(ALL)

debug: $(addprefix Makefile_Debug., $(ALL_BASE))
	@echo "debug list [$(words $(ALL)) item(s)]:" $(ALL)
	
$(ALL_BASE): %: Makefile_Debug.%

$(ALL_BASE): %: Makefile.%

Makefile.%: $(AM_KERNELS_CPU_TESTS_DIR)/tests/%.c latest
	@/bin/echo -e "NAME = $*\nSRCS = $<\ninclude ${ABSTRACT_MACHINE_DIR}/Makefile" > $@
	@if make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS); then \
		printf "[%14s] $(COLOR_GREEN)PASS$(COLOR_NONE)\n" $* >> $(RESULT); \
	else \
		printf "[%14s] $(COLOR_RED)***FAIL***$(COLOR_NONE)\n" $* >> $(RESULT); \
	fi
	-@rm -f Makefile.$*

Makefile_Debug.%: $(AM_KERNELS_CPU_TESTS_DIR)/tests/%.c latest
	@/bin/echo -e "NAME = $*\nSRCS = $<\ninclude ${ABSTRACT_MACHINE_DIR}/Makefile" > $@
	@make -s -f $@ ARCH=$(ARCH) BUILD_DIR=$(BUILD_DIR) $(MAKECMDGOALS)
	-@rm -f Makefile_Debug.$*

run: all
	@cat $(RESULT)
	@rm $(RESULT)

run_batch: all
	@cat $(RESULT)
	@rm $(RESULT)

gdb: all

clean:
	rm -rf Makefile.* build/

latest:
