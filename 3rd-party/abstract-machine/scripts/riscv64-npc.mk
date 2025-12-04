include $(ABSTRACT_MACHINE_DIR)/scripts/isa/riscv.mk
include $(ABSTRACT_MACHINE_DIR)/scripts/platform/npc.mk
COMMON_CFLAGS += -march=rv64gc -mabi=lp64d  # overwrite
LDFLAGS       += -melf64lriscv                    # overwrite

AM_SRCS += riscv/npc/libgcc/div.S \
           riscv/npc/libgcc/muldi3.S \
           riscv/npc/libgcc/multi3.c \
           riscv/npc/libgcc/ashldi3.c \
           riscv/npc/libgcc/unused.c
