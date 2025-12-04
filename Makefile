all:
	@echo "Write this Makefile by your self."

sim:
	make -C obj_dir -f Vtop.mk Vtop 

include ../Makefile
