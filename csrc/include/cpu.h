#ifndef __CPU_H__
#define __CPU_H__

#include "Vriscv64i.h"
#include "debug.h"
#include "macro.h"

#include "Vriscv64i_CPU.h"
#include "Vriscv64i_GPR.h"
#include "Vriscv64i_MemControl.h"
#include "Vriscv64i_PC.h"
#include "Vriscv64i___024root.h"
#include "Vriscv64i_riscv64i.h"

extern Vriscv64i top;
#define CPU_PHYADDR_BEGIN 0x80000000
#define CPU top.riscv64i->Cpu
#define CPU_GPRs top.riscv64i->Cpu->gpr->__PVT__gprs
#define CPU_RAM top.riscv64i->Cpu->ram->__PVT__ram_
#define CPU_PC top.riscv64i->Pc->__PVT__pc
#define CPU_RAM_SIZE Vriscv64i_MemControl::RAM_SIZE

#define IFID_IN top.riscv64i->Cpu->__PVT__ifid_in
#define FLUSH_IFID_IN ifid_in.set(IFID_IN)

#define IFID_OUT top.riscv64i->Cpu->__PVT__ifid_out
#define FLUSH_IFID_OUT ifid_out.set(IFID_OUT)

#define IDEX_IN top.riscv64i->Cpu->__PVT__idex_in
#define FLUSH_IDEX_IN idex_in.set(IDEX_IN)

#define IDEX_OUT top.riscv64i->Cpu->__PVT__idex_out
#define FLUSH_IDEX_OUT idex_out.set(IDEX_OUT)

#define EXMEM_IN top.riscv64i->Cpu->__PVT__exmem_in
#define FLUSH_EXMEM_IN exmem_in.set(EXMEM_IN)

#define EXMEM_OUT top.riscv64i->Cpu->__PVT__exmem_out
#define FLUSH_EXMEM_OUT exmem_out.set(EXMEM_OUT)

#define MEMWB_IN top.riscv64i->Cpu->__PVT__memwb_in
#define FLUSH_MEMWB_IN memwb_in.set(MEMWB_IN)

#define MEMWB_OUT top.riscv64i->Cpu->__PVT__memwb_out
#define FLUSH_MEMWB_OUT memwb_out.set(MEMWB_OUT)

typedef Vriscv64i_IFID_Pipe_t__struct__0 IFID_t;
typedef Vriscv64i_IDEX_Pipe_t__struct__0 IDEX_t;
typedef Vriscv64i_EXMEM_Pipe_t__struct__0 EXMEM_t;
typedef Vriscv64i_MEMWB_Pipe_In_t__struct__0 MEMWB_IN_t;
typedef Vriscv64i_MEMWB_Pipe_Out_t__struct__0 MEMWB_OUT_t;

void cpu_single_cycle();

void cpu_reset(int n);

void cpu_exec(unsigned i);

#endif