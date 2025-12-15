#ifndef __CPU_H__
#define __CPU_H__

#include "VMonitor.h"
#include "debug.h"
#include "macro.h"

#include "VMonitor_CPU.h"
#include "VMonitor_GPR.h"
#include "VMonitor_Monitor.h"
#include "VMonitor_PC.h"
#include "VMonitor_RAM.h"
#include "VMonitor___024root.h"

extern VMonitor top;
#define CPU_PHYADDR_BEGIN 0x80000000
#define CPU top.Monitor->Cpu
#define CPU_GPRs top.Monitor->Cpu->gpr->__PVT__gprs
#define CPU_RAM top.Monitor->Cpu->ram->__PVT__ram_
#define CPU_PC top.Monitor->Pc->__PVT__pc
#define CPU_RAM_SIZE sizeof(VMonitor_RAM::__PVT__addr_i) * 8

#define IFID_IN top.Monitor->Cpu->__PVT__ifid_in
#define FLUSH_IFID_IN ifid_in.set(IFID_IN)
#define IFID_OUT top.Monitor->Cpu->__PVT__ifid_out
#define FLUSH_IFID_OUT ifid_out.set(IFID_OUT)
#define IDEX_IN top.Monitor->Cpu->__PVT__idex_in
#define FLUSH_IDEX_IN idex_in.set(IDEX_IN)
#define IDEX_OUT top.Monitor->Cpu->__PVT__idex_out
#define FLUSH_IDEX_OUT idex_out.set(IDEX_OUT)
#define EXMEM_IN top.Monitor->Cpu->__PVT__exmem_in
#define FLUSH_EXMEM_IN exmem_in.set(EXMEM_IN)
#define EXMEM_OUT top.Monitor->Cpu->__PVT__exmem_out
#define FLUSH_EXMEM_OUT exmem_out.set(EXMEM_OUT)
#define MEMWB_IN top.Monitor->Cpu->__PVT__memwb_in
#define FLUSH_MEMWB_IN memwb_in.set(MEMWB_IN)
#define MEMWB_OUT top.Monitor->Cpu->__PVT__memwb_out
#define FLUSH_MEMWB_OUT memwb_out.set(MEMWB_OUT)

typedef VMonitor_IFID_Pipe_t__struct__0 IFID_t;
typedef VMonitor_IDEX_Pipe_t__struct__0 IDEX_t;
typedef VMonitor_EXMEM_Pipe_t__struct__0 EXMEM_t;
typedef VMonitor_MEMWB_Pipe_In_t__struct__0 MEMWB_IN_t;
typedef VMonitor_MEMWB_Pipe_Out_t__struct__0 MEMWB_OUT_t;

void cpu_single_cycle();

void cpu_reset(int n);

void cpu_exec(unsigned i);

#endif