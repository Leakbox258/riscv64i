#include "cpu.h"

const char *regs[] = {"$0", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2",
                      "s0", "s1", "a0",  "a1",  "a2", "a3", "a4", "a5",
                      "a6", "a7", "s2",  "s3",  "s4", "s5", "s6", "s7",
                      "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

static uint64_t g_timer = 0; // unit: us
uint64_t g_nr_guest_inst = 0;

void cpu_single_cycle() {
  top.clk_i = 0;
  top.eval();
  top.clk_i = 1;
  top.eval();
}

void cpu_reset(int n) {
  top.rst_i = 1;
  while (n-- > 0) {
    cpu_single_cycle();
  }
  top.rst_i = 0;
}

void cpu_exec(unsigned i) {
  for (unsigned ii = 0; ii < i; ++ii) {
    cpu_single_cycle();
  }
}

paddr_t guest_to_host(vaddr_t vaddr) {
  /// TODO: mmu: vaddr_t -> paddr_t
  return (paddr_t)(vaddr & ((1ull << CPU_RAM_SIZE) - 1));
}

void isa_reg_display() {
  printf("%3s: 0x%10lx |\n", "pc", CPU_PC);

  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); ++i) {
    printf("%3s: 0x%10lx", regs[i], CPU_GPRs[i]);

    if (i % 4 == 3) {
      printf(" |\n");
    } else {
      printf(" | ");
    }
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0)
    Log("simulation frequency = " NUMBERIC_FMT " inst/s",
        g_nr_guest_inst * 1000000 / g_timer);
  else
    Log("Finish running in less than 1 us and can not calculate the simulation "
        "frequency");
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}