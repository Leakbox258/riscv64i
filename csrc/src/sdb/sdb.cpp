/***************************************************************************************
 * Copyright (c) 2014-2024 Zihao Yu, Nanjing University
 *
 * Modified by YuFei Zhang in 2025 for riscv64-g ISA and verilator simulation
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan
 *PSL v2. You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY
 *KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 *NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include "common.h"
#include "cpu.h"
#include "debug.h"
#include "macro.h"
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <readline/history.h>
#include <readline/readline.h>
#include <stdlib.h>
#include <string.h>

extern void isa_reg_display();
extern paddr_t guest_to_host(vaddr_t);
extern IFID_t ifid_in, ifid_out;
extern IDEX_t idex_in, idex_out;
extern EXMEM_t exmem_in, exmem_out;
extern MEMWB_IN_t memwb_in;
extern MEMWB_OUT_t memwb_out;

static int is_batch_mode = false; // is_debug_mode = true

void init_regex();
void init_wp_pool();
extern const char *regs[];

static char *rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) { return -1; }

static int cmd_help(char *args);

static int cmd_si(char *args) {
  char *arg = strtok(NULL, " ");

  int i;
  if (arg) {
    char *nptr = NULL;
    i = strtol(arg, &nptr, 10);

    if (nptr != arg + strlen(arg)) {
      Log("Invalid forward number for debugger cmd_si");
      return 1;
    }
  } else {
    i = 1;
  }

  cpu_exec(i);

  return 0;
}

static int cmd_info(char *args) {
  char *arg = strtok(NULL, " ");

  if (arg == NULL) {
    Log("cmd_info support 'r' to dump current registers");
    return 1;
  }

  if (!strncmp(arg, "r", 1)) {
    isa_reg_display();
  } else {
    Log("cmd_info support 'r' to dump current registers");
    return 2;
  }

  return 0;
}

static int cmd_xm(char *args) {
  char *cnt_s = strtok(NULL, " ");
  char *expr_s = strtok(NULL, " ");

  if (!cnt_s || !expr_s) {
    Log("Invalid args for cmd_xm");
    return 4;
  }

  char *nptr_cnt = NULL;
  int cnt = strtol(cnt_s, &nptr_cnt, 10);

  char *nptr_expr = NULL;
  paddr_t expr = strtol(expr_s, &nptr_expr, 16);

  if (nptr_cnt != cnt_s + strlen(cnt_s)) {
    Log("Invalid number of cmd_xm");
    return 1;
  }

  if (nptr_expr != expr_s + strlen(expr_s)) {
    Log("Invalid expr of cmd_xm");
    return 2;
  }

  paddr_t addr = guest_to_host(expr);

  if (addr % 4) {
    Log("The input address is not align to a word");
    return 3;
  }

  for (int i = 0; i < cnt; ++i) {

    printf("0x%08x ", *((uint32_t *)&CPU_RAM[addr]));

    addr += 4; // skip a word
  }

  printf("\n");

  return 0;
}

static int cmd_xi(char *args) {
  char *cnt_s = strtok(NULL, " ");
  char *expr_s = strtok(NULL, " ");

  if (!cnt_s || !expr_s) {
    Log("Invalid input of cmd_xi");
    return 4;
  }

  char *nptr_cnt = NULL;
  int cnt = strtol(cnt_s, &nptr_cnt, 10);

  char *nptr_expr = NULL;
  paddr_t expr = strtol(expr_s, &nptr_expr, 16);

  if (nptr_cnt != cnt_s + strlen(cnt_s)) {
    Log("Invalid number of cmd_xi");
    return 1;
  }

  if (nptr_expr != expr_s + strlen(expr_s)) {
    Log("Invalid expr of cmd_xi");
    return 2;
  }

  paddr_t addr = guest_to_host(expr);

  if (addr % 4) {
    Log("The input address is not align to an inst");
    return 3;
  }

  for (int i = 0; i < cnt; ++i) {
    /// TODO: addr maybe acceed the limit of the neum address?

    printf("%08x: %08x \n", (uint32_t)(addr + CPU_PHYADDR_BEGIN),
           *((uint32_t *)&CPU_RAM[addr]));

    addr += 4; // skip a word
  }
  printf("\n");

  return 0;
}

static int cmd_pipe_impl(char *reg);

static int cmd_pipe(char *args) {
  char *reg = strtok(NULL, " ");

  if (!reg) {
    Log("Invalid pipeline register of cmd_pipe");
    return 1;
  }

  if (cmd_pipe_impl(reg)) {
    return 2;
  }

  return 0;
}

static int cmd_pipea(char *args) {
  char arg0[] = "ifid-in";
  cmd_pipe_impl(arg0);
  char arg1[] = "ifid-out";
  cmd_pipe_impl(arg1);
  char arg2[] = "idex-in";
  cmd_pipe_impl(arg2);
  char arg3[] = "idex-out";
  cmd_pipe_impl(arg3);
  char arg4[] = "exmem-in";
  cmd_pipe_impl(arg4);
  char arg5[] = "exmem-out";
  cmd_pipe_impl(arg5);
  char arg6[] = "memwb-in";
  cmd_pipe_impl(arg6);
  char arg7[] = "memwb-out";
  cmd_pipe_impl(arg7);
  return 0;
}

extern std::set<paddr_t> cpu_break_points;

static int cmd_b(char *args) {
  char *expr_s = strtok(NULL, " ");

  if (!expr_s) {
    Log("Invalid PC for cmd_b");
    return 1;
  }

  char *nptr_expr = NULL;
  paddr_t expr = strtol(expr_s, &nptr_expr, 16);

  if (nptr_expr != expr_s + strlen(expr_s)) {
    Log("Invalid expr of cmd_b");
    return 2;
  }

  if (cpu_break_points.find(expr) != cpu_break_points.end()) {
    Log("Already has a break point at 0x%08lx", expr);
    return 3;
  }

  cpu_break_points.insert(expr);

  Log("BreakPoint at 0x%08lx", expr);

  return 0;
}

extern std::set<paddr_t> cpu_watch_points;
extern std::set<unsigned> cpu_reg_watch_points;

static int cmd_w_impl(paddr_t addr);

static int cmd_wreg_impl(unsigned reg);

static int cmd_w(char *args) {
  char *expr_s = strtok(NULL, " ");

  if (!expr_s) {
    Log("Invalid PC for cmd_w");
    return 1;
  }

  if (expr_s[0] == 'x') {
    char *nptr_reg = NULL;
    unsigned reg = strtol(expr_s + 1, &nptr_reg, 10);

    if (nptr_reg != expr_s + strlen(expr_s) || reg > 31) {
      Log("Invalid register of cmd_w");
      return 2;
    }

    cmd_wreg_impl(reg);

  } else {
    char *nptr_expr = NULL;
    paddr_t expr = strtol(expr_s, &nptr_expr, 16);

    if (nptr_expr != expr_s + strlen(expr_s)) {
      Log("Invalid expr of cmd_w");
      return 2;
    }

    cmd_w_impl(expr);
  }

  return 0;
}

static int cmd_wb(char *args) {
  char *cnt_s = strtok(NULL, " ");
  char *expr_s = strtok(NULL, " ");

  if (!expr_s || !cnt_s) {
    Log("Invalid arg for cmd_wb");
    return 1;
  }

  char *nptr_cnt = NULL;
  unsigned cnt = strtoul(cnt_s, &nptr_cnt, 10);

  char *nptr_expr = NULL;
  paddr_t expr = strtol(expr_s, &nptr_expr, 16);

  if (nptr_expr != expr_s + strlen(expr_s)) {
    Log("Invalid expr of cmd_wb");
    return 2;
  }

  if (nptr_cnt != cnt_s + strlen(cnt_s)) {
    Log("Invalid cnt of cmd_wb");
    return 3;
  }

  for (unsigned i = 1; i < cnt; ++i) {
    cmd_w_impl((paddr_t)expr + 4 * i);
  }

  return 0;
}

static struct {
  const char *name;
  const char *description;
  int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit npc", cmd_q},

    /* TODO: Add more commands */
    {"si", "Step instruction", cmd_si},
    {"info", "Display infos", cmd_info},
    {"xm", "Scan memory", cmd_xm},
    {"xi", "Scan instruction", cmd_xi},
    {"pipe", "print status infos of pipeline registers", cmd_pipe},
    {"pipea", "print status infos of all pipeline registers", cmd_pipea},
    {"b", "insert a software break point at some location", cmd_b},
    {"w", "watch on somewhere of memory by software", cmd_w},
    {"wb", "watch on a range of memory (stride = 4btye)", cmd_wb}};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  } else {
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() { is_batch_mode = true; }

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }
  Log("Running Mode Has been set as debug");

  for (char *str; (str = rl_gets()) != NULL;) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) {
      continue;
    }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

    // #ifdef CONFIG_DEVICE
    //     extern void sdl_clear_event_queue();
    //     sdl_clear_event_queue();
    // #endif

    int i;
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) {
          return;
        }
        break;
      }
    }

    if (i == NR_CMD) {
      printf("Unknown command '%s'\n", cmd);
    }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}

static int cmd_pipe_impl(char *reg) {
  if (!strcmp(reg, "ifid_in") || !strcmp(reg, "ifid-in")) {
    FLUSH_IFID_IN;

    printf("ifid_in: \n\tPC: 0x%08x", (uint32_t)ifid_in.PC);
  } else if (!strcmp(reg, "ifid_out") || !strcmp(reg, "ifid-out")) {
    FLUSH_IFID_OUT;

    printf("ifid_out: \n\tPC: 0x%08x", (uint32_t)ifid_out.PC);
  } else if (!strcmp(reg, "idex_in") || !strcmp(reg, "idex-in")) {
    FLUSH_IDEX_IN;

    printf("idex_in: \n\tPC: 0x%08x |\tRd: %s |\tRs1: %s 0x%lx |\tRs2: %s "
           "0x%lx |En: %d",
           (uint32_t)idex_in.PC, regs[idex_in.RegIdx[2]],
           regs[idex_in.RegIdx[0]], idex_in.RegData[0], regs[idex_in.RegIdx[1]],
           idex_in.RegData[1], idex_in.Enable);
  } else if (!strcmp(reg, "idex_out") || !strcmp(reg, "idex-out")) {
    FLUSH_IDEX_OUT;

    printf("idex_out: \n\tPC: 0x%08x |\tRd: %s |\tRs1: %s 0x%lx |\tRs2: %s "
           "0x%lx |En: %d",
           (uint32_t)idex_out.PC, regs[idex_out.RegIdx[2]],
           regs[idex_out.RegIdx[0]], idex_out.RegData[0],
           regs[idex_out.RegIdx[1]], idex_out.RegData[1], idex_out.Enable);
  } else if (!strcmp(reg, "exmem_in") || !strcmp(reg, "exmem-in")) {
    FLUSH_EXMEM_IN;

    printf("exmem_in: \n\tPC: 0x%08x |\tPC_Next: 0x%08x |\tRs1: %s|\tRs2: "
           "%s |\tRegWrite: %s |\tMemRead: %s |\tMemWrite: %s |",
           (uint32_t)exmem_in.PC, (uint32_t)exmem_in.PC_Next,
           regs[exmem_in.RegIdx[0]], regs[exmem_in.RegIdx[1]],
           exmem_in.Reg_WEn ? "true" : "false",
           exmem_in.Mem_REn ? "true" : "false",
           exmem_in.Mem_WEn ? "true" : "false");
  } else if (!strcmp(reg, "exmem_out") || !strcmp(reg, "exmem-out")) {
    FLUSH_EXMEM_OUT;

    printf("exmem_out: \n\tPC: 0x%08x |\tPC_Next: 0x%08x |\tRs1: %s |\tRs2: "
           "%s |\tRegWrite: %s |\tMemRead: %s |\tMemWrite: %s |",
           (uint32_t)exmem_out.PC, (uint32_t)exmem_out.PC_Next,
           regs[exmem_out.RegIdx[0]], regs[exmem_out.RegIdx[1]],
           exmem_out.Reg_WEn ? "true" : "false",
           exmem_out.Mem_REn ? "true" : "false",
           exmem_out.Mem_WEn ? "true" : "false");
  } else if (!strcmp(reg, "memwb_in") || !strcmp(reg, "memwb-in")) {
    FLUSH_MEMWB_IN;

    printf("memwb_in: \n\tPC: 0x%08x |\tPC_Next: 0x%08x |\tRd: %s |\tRegWrite: "
           "%s |",
           (uint32_t)memwb_in.PC, (uint32_t)memwb_in.PC_Next,
           regs[memwb_in.RD_Addr], memwb_in.Reg_WEn ? "true" : "false");
  } else if (!strcmp(reg, "memwb_out") || !strcmp(reg, "memwb-out")) {
    FLUSH_MEMWB_OUT;

    printf("memwb_out: \n\tPC: 0x%08x |\tPC_Next: 0x%08x |\tRd: %s|\tRegWrite: "
           "%s |\tRegData: 0x%lx",
           (uint32_t)memwb_out.PC, (uint32_t)memwb_out.PC_Next,
           regs[memwb_out.RD_Addr], memwb_out.Reg_WEn ? "true" : "false",
           memwb_out.WB_Data);
  } else {
    Log("Invalid pipeline register of cmd_pipe");
    return 1;
  }

  printf("\n");
  return 0;
}

static int cmd_w_impl(paddr_t expr) {

  if (cpu_watch_points.find(expr) != cpu_watch_points.end()) {
    Log("Already has a watch point(4 bytes) on 0x%08lx", expr);
    return 3;
  }

  cpu_watch_points.insert(expr);

  Log("WatchPoint on 0x%08lx", expr);

  return 0;
}

static int cmd_wreg_impl(unsigned reg) {

  if (cpu_reg_watch_points.find(reg) != cpu_reg_watch_points.end()) {
    Log("Already has a watch point on x%0u", reg);
    return 3;
  }

  cpu_reg_watch_points.insert(reg);

  Log("WatchPoint on x%0u", reg);

  return 0;
}