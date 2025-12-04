#include "Vtop.h"
#include <stdio.h>
#include <verilated.h>

int main() {
  Verilated::traceEverOn(true);

  Vtop *vtop = new Vtop;

  while (true) {
    int a = rand() & 1;
    int b = rand() & 1;
    vtop->a = a;
    vtop->b = b;
    vtop->eval();
    printf("a = %d, b = %d, f = %d\n", a, b, vtop->f);
    assert(vtop->f == (a ^ b));
  }

  return 0;
}
