#include "common.h"
#include "cpu.h"
#include "debug.h"
#include <cstdio>
#include <readline/history.h>
#include <readline/readline.h>
#include <stdlib.h>
#include <string.h>

#ifndef PHYADDR_BEGIN
#define PHYADDR_BEGIN 0x80000000
#endif

extern void isa_reg_display();
extern paddr_t guest_to_host(vaddr_t);

static int is_batch_mode = false; // is_debug_mode = true

void init_regex();
void init_wp_pool();

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

  char *nptr = NULL;
  int i = strtol(arg, &nptr, 10);

  if (nptr != arg + strlen(arg)) {
    Log("Invalid forward number for debugger cmd_si");
    return 1;
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
    TODO(); // no return
  }

  return 0;
}

static int cmd_x(char *args) {
  char *cnt_s = strtok(NULL, " ");
  char *expr_s = strtok(NULL, " ");

  char *nptr_cnt = NULL;
  int cnt = strtol(cnt_s, &nptr_cnt, 10);

  char *nptr_expr = NULL;
  paddr_t expr = strtol(expr_s, &nptr_expr, 16);

  if (nptr_cnt != cnt_s + strlen(cnt_s)) {
    Log("Invalid number of cmd_x");
    return 1;
  }

  if (nptr_expr != expr_s + strlen(expr_s)) {
    Log("Invalid expr of cmd_x");
    return 2;
  }

  paddr_t addr = guest_to_host(expr);

  if (addr < PHYADDR_BEGIN) {
    Log("The input virtual address is not mapped.");
    return 1;
  }

  for (int i = 0; i < cnt; ++i) {
    /// TODO: addr maybe acceed the limit of the neum address?

    printf("0x%x ", (uint32_t)(addr));

    addr += 4; // skip a word
  }
  printf("\n");

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
    {"x", "Scan memory", cmd_x},
};

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