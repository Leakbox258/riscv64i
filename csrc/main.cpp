#include "VMonitor.h"
#include <verilated.h>

VMonitor top;

#ifdef NVBOARD
void nvboard_bind_all_pins(VMonitor *top);
void nvboard_init(int);
void nvboard_update();
void cpu_single_cycle();
void cpu_reset(int);
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
