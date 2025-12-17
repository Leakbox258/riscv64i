#include "Vriscv64i.h"
#include <verilated.h>

Vriscv64i top;

#ifdef NVBOARD
void nvboard_bind_all_pins(Vriscv64i *top);
void nvboard_init(int);
void nvboard_update();
void cpu_single_cycle() {
  top.clk = 0;
  top.eval();
  top.clk = 1;
  top.eval();
}
void cpu_reset(int n) {
  top.rst = 1;
  while (n-- > 0) {
    cpu_single_cycle();
  }
  top.rst = 0;
}
#else
void init_monitor(int argc, char *argv[]);
void engine_start();
#endif

int main(int argc, char *argv[]) {
  setbuf(stdout, NULL);
  setbuf(stderr, NULL);

#ifdef NVBOARD
  nvboard_bind_all_pins(&top);
  nvboard_init(0);
  cpu_reset(10);
  while (1) {
    nvboard_update();
    cpu_single_cycle();
  }
#else
  init_monitor(argc, argv);
  engine_start();
#endif

  return 0;
}
