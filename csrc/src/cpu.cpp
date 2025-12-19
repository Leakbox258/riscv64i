#include "cpu.h"
#include "common.h"
#include "debug.h"
#include <algorithm>

const char *regs[] = {"$0", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2",
                      "s0", "s1", "a0",  "a1",  "a2", "a3", "a4", "a5",
                      "a6", "a7", "s2",  "s3",  "s4", "s5", "s6", "s7",
                      "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

IFID_t ifid_in, ifid_out;
IDEX_t idex_in, idex_out;
EXMEM_t exmem_in, exmem_out;
MEMWB_IN_t memwb_in;
MEMWB_OUT_t memwb_out;

std::set<paddr_t> cpu_break_points;
std::set<paddr_t> cpu_watch_points;
std::set<unsigned> cpu_reg_watch_points;

static uint64_t g_timer = 0; // unit: us
uint64_t g_nr_guest_inst = 0;

void cpu_single_cycle() {
  top.clk = 0;
  top.eval();
  top.clk = 1;
  top.eval();
}

void init_cpu() {
  FLUSH_IDEX_IN;
  FLUSH_IDEX_OUT;
  FLUSH_EXMEM_IN;
  FLUSH_EXMEM_OUT;
  FLUSH_IFID_IN;
  FLUSH_IFID_OUT;
  FLUSH_MEMWB_IN;
  FLUSH_MEMWB_OUT;

  cpu_reset(1);
}

void cpu_reset(int n) {
  top.rst = 1;
  while (n-- > 0) {
    cpu_single_cycle();
  }
  top.rst = 0;
}

static int memwid(int);

void cpu_exec(unsigned i) {
  for (unsigned ii = 0; ii < i; ++ii) {
    cpu_single_cycle();

    FLUSH_EXMEM_OUT;
    FLUSH_MEMWB_OUT;

    /// Check Break Point
    if (cpu_break_points.find((paddr_t)CPU_PC) != cpu_break_points.end()) {

      Log("monitor: Hit BreakPoint at 0x%08lx", (paddr_t)CPU_PC);
      return;
    }

    /// Memory Watch Point
    if (std::find_if(cpu_watch_points.begin(), cpu_watch_points.end(),
                     [&](const auto &wp) {
                       return wp >= (paddr_t)exmem_out.ALU_Result &&
                              wp < (paddr_t)(exmem_out.ALU_Result +
                                             memwid(exmem_out.Detail));
                     }) != cpu_watch_points.end()) {

      if (memwid(exmem_out.Detail) != -1 &&
          (exmem_out.Mem_WEn || exmem_out.Mem_REn)) {

        Log("monitor: Hit WatchPoint on 0x%08lx",
            (paddr_t)exmem_out.ALU_Result);
        return;
      }
    }

    /// Register Watch Point
    if (cpu_reg_watch_points.find((unsigned)memwb_out.RD_Addr) !=
            cpu_reg_watch_points.end() &&
        memwb_out.Reg_WEn) {

      Log("monitor: Hit WatchPoint on register %s", regs[memwb_out.RD_Addr]);
      return;
    }
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

static int memwid(int detail) {
  switch (detail) {
  case 0: // B
  case 4: // BU
    return 1;
  case 1: // H
  case 5: // HU
    return 2;
  case 2: // W
  case 6: // WU
    return 4;
  case 3: // D
    return 8;
  default:
    return -1; // MemWEn unavalible
  }
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}