TOPNAME = riscv64i
NXDC_FILES = constr/riscv64i.nxdc
INC_PATH ?= ./csrc/include

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
					-O3 --x-assign fast \
					--public-params		\
					--x-initial fast --noassert

VERILATOR_INCLUDE += -I./vsrc/pkg

BUILD_DIR = ./build
FPGA_DIR = ./FPGA
AM_KERNELS_CPU_TESTS_DIR = ./3rd-party/am-kernels/tests/cpu-tests
ABSTRACT_MACHINE_DIR = ./3rd-party/abstract-machine
OBJ_DIR = $(BUILD_DIR)/obj_dir

NVBIN = $(BUILD_DIR)/$(addprefix nv_, $(TOPNAME))
BIN = $(BUILD_DIR)/$(TOPNAME)
VBIN = $(BUILD_DIR)/$(addprefix v_, $(TOPNAME))

SV2V = $(BUILD_DIR)/$(TOPNAME).v

ALL ?=

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
FPGA_VSRCS = $(shell find $(abspath $(FPGA_DIR)) -name "*.sv") # sv only
VSRCS = $(shell find $(abspath ./vsrc) -name "*.sv") # sv only
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CENTRY = csrc/main.cpp

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(abspath $(INC_PATH)))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
READLINE_LIB = "-lreadline"

$(NVBIN): $(VSRCS) $(CENTRY) $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) $(VERILATOR_INCLUDE) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		-CFLAGS -DNVBOARD \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(addprefix -LDFLAGS , $(READLINE_LIB)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(NVBIN))

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) $(VERILATOR_INCLUDE) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(READLINE_LIB)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

$(VBIN): $(SV2V) $(CENTRY) $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		-CFLAGS -DNVBOARD \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(addprefix -LDFLAGS , $(READLINE_LIB)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(VBIN))

# generate headers for C++ linting
headers: $(VSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) $(VERILATOR_INCLUDE) \
		--top-module $(TOPNAME) $^ \
		--Mdir $(OBJ_DIR)

# build & run single app
testcase: 
	@make -s -f $(AM_KERNELS_CPU_TESTS_DIR)/Makefile \
		ARCH=riscv64-npc \
		ALL=$(AM_KERNELS_CPU_TESTS_DIR)/tests/$(ALL) \
		AM_KERNELS_CPU_TESTS_DIR=$(AM_KERNELS_CPU_TESTS_DIR) \
		ABSTRACT_MACHINE_DIR=$(ABSTRACT_MACHINE_DIR) \
		debug

nvrun: $(NVBIN) testcase
	@clear
	@$^

run: $(BIN) testcase
	@clear
	@$(BIN) --batch

debug: $(BIN) testcase
	@clear
	@$(BIN)

$(SV2V):
	sv2v $(VERILATOR_INCLUDE) $(VSRCS) --top=Monitor --write=$(SV2V)

sv2v:
	@mkdir -p $(BUILD_DIR)/verilog
	$(foreach sv, $(FPGA_VSRCS),$(info "converting $(sv)"))
	$(foreach sv, $(FPGA_VSRCS),$(shell sv2v $(VERILATOR_INCLUDE) $(sv) -w $(BUILD_DIR)/verilog/$(notdir $(sv)).v))

vrun: $(VBIN) testcase
	@clear
	@$(VBIN)

CP_DIR ?= ~/workspace/riscv64i/rtl

cp: sv2v
	$(foreach v, $(shell find $(abspath $(BUILD_DIR)/verilog) -name "*.sv.v"), $(shell cp $(v) $(CP_DIR)/.))

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean nvrun run