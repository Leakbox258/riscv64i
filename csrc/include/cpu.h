#ifndef __CPU_H__
#define __CPU_H__

#include "VMonitor.h"
#include "debug.h"
#include "macro.h"

#include "VMonitor_CPU.h"
#include "VMonitor_CodeROM.h"
#include "VMonitor_GPR.h"
#include "VMonitor_Monitor.h"
#include "VMonitor_PC.h"
#include "VMonitor_RAM.h"
#include "VMonitor___024root.h"

extern VMonitor top;
#define CPU_PHYADDR_BEGIN 0x80000000
#define CPU_GPRs top.Monitor->Cpu->gpr->__PVT__gprs
#define CPU_INSTS top.Monitor->Cpu->code->__PVT__rom_
#define CPU_RAM top.Monitor->Cpu->ram->__PVT__ram_
#define CPU_PC top.Monitor->Pc->__PVT__pc
#define CPU_RAM_SIZE sizeof(VMonitor_RAM::__PVT__addr_i) * 8

void cpu_single_cycle();

void cpu_reset(int n);

void cpu_exec(int i);

#endif