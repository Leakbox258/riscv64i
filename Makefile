TOPNAME = Monitor
NXDC_FILES = constr/Monitor.nxdc
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
					-O3 --x-assign fast \
					--x-initial fast --noassert

VERILATOR_INCLUDE += -I./vsrc/pkg

BUILD_DIR = ./build
AM_KERNELS_CPU_TESTS_DIR = ./3rd-party/am-kernels/tests/cpu-tests
ABSTRACT_MACHINE_DIR = ./3rd-party/abstract-machine
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
ALL ?=

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) $(VERILATOR_INCLUDE) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

# generate headers for C++ linting
headers: $(VSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		--Mdir $(OBJ_DIR)

# build & run single app
debug: 
	@make -s -f $(AM_KERNELS_CPU_TESTS_DIR)/Makefile \
		ARCH=riscv64-npc \
		ALL=$(AM_KERNELS_CPU_TESTS_DIR)/tests/$(ALL) \
		AM_KERNELS_CPU_TESTS_DIR=$(AM_KERNELS_CPU_TESTS_DIR) \
		ABSTRACT_MACHINE_DIR=$(ABSTRACT_MACHINE_DIR) \
		debug

all: default

run: $(BIN) debug
# 	@$^ > $(BUILD_DIR)/display.log
	@$^

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default all clean run