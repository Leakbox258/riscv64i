#include "VMonitor.h"
#include <verilated.h>

typedef VMonitor TOP_NAME;

void nvboard_bind_all_pins(TOP_NAME* top);
void nvboard_init(int);
void nvboard_update();

static TOP_NAME top;

static void single_cycle() {
  top.clk_i = 0;
  top.eval();
  top.clk_i = 1;
  top.eval();
}

static void reset(int n) {
  top.rst_i = 1;
  while (n-- > 0)
    single_cycle();
  top.rst_i = 0;
}

int main() {
  setbuf(stdout, NULL);
  setbuf(stderr, NULL);

  nvboard_bind_all_pins(&top);
  nvboard_init(0);

  reset(10);

  while (1) {
    nvboard_update();
    single_cycle();
    // sleep(1);
  }

  return 0;
}
