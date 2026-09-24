# E603-style entry points: install -> compile -> run_test -> wave.
# Run from riscv_project/vsim on Linux (or use the root Makefile wrapper).
RISCV_PREFIX ?= riscv64-unknown-elf-
RISCV_AS := $(RISCV_PREFIX)as
RISCV_LD := $(RISCV_PREFIX)ld
RISCV_OBJDUMP := $(RISCV_PREFIX)objdump
RISCV_OBJCOPY := $(RISCV_PREFIX)objcopy
VCS ?= vcs
VERDI ?= verdi
TESTCASE ?= arith
TEST_NAME := $(basename $(notdir $(TESTCASE)))
MAX_CYCLES ?= 10000
TRACE ?= 0
DUMPWAVE ?= 1
ALLOW_FAIL ?= 0
TESTS := arith branch loadstore hazard pipeline
BUILD_DIR := build
RUN_DIR := run
INSTALL_DIR := install
SOFTWARE_DIR := ../software/tests
RTL_SOURCES := $(wildcard ../rtl/common/*.v ../rtl/soc/*.v \
               ../rtl/memory/*.v ../rtl/core/*.v ../rtl/core/ifu/*.v \
               ../rtl/core/exu/*.v ../rtl/core/exu/units/*.v) \
               ../rtl/core/exu/units/alu_ops.vh
# These paths are interpreted after changing into vsim/run/.
SIM_ARGS = +HEX=../$(BUILD_DIR)/$(TEST_NAME).hex +TESTCASE=$(TEST_NAME) \
           +MAX_CYCLES=$(MAX_CYCLES) \
           $(if $(filter pipeline,$(TEST_NAME)),+CHECK_PIPELINE,) \
           $(if $(filter 1,$(TRACE)),+TRACE,) \
           $(if $(filter 1,$(DUMPWAVE)),+WAVE +WAVE_FILE=$(TEST_NAME)/wave.vcd,)

.PHONY: all help install compile run_test wave tests regress list disasm clean
all: run_test

help:
	@echo 'make install                         prepare directories and check tools'
	@echo 'make compile                         compile RTL/testbench with VCS'
	@echo 'make run_test TESTCASE=arith          assemble and run one local test'
	@echo 'make wave TESTCASE=arith              open an existing VCD in Verdi'
	@echo 'make regress                         run every bundled test'
	@echo 'make disasm TESTCASE=arith            inspect the linked instructions'
	@echo 'Available tests: $(TESTS)'

# Like E603, install prepares a separate simulation area. It does not download
# or install proprietary/host tools; those must already be available on Linux.
install:
	@mkdir -p $(BUILD_DIR) $(RUN_DIR) $(INSTALL_DIR)
	@for tool in $(RISCV_AS) $(RISCV_LD) $(RISCV_OBJCOPY) $(RISCV_OBJDUMP) od $(VCS); do \
	  command -v $$tool >/dev/null 2>&1 || { echo "Missing tool: $$tool"; exit 1; }; \
	done
	@if ! cmp -s filelist.f $(INSTALL_DIR)/filelist.f; then \
	  cp filelist.f $(INSTALL_DIR)/filelist.f; \
	fi
	@echo 'install: ready'

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/%.o: $(SOFTWARE_DIR)/%.s $(SOFTWARE_DIR)/test_macros.inc | $(BUILD_DIR)
	$(RISCV_AS) -march=rv64i -mabi=lp64 -mno-relax -I $(SOFTWARE_DIR) -o $@ $<

$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o
	$(RISCV_LD) -m elf64lriscv --no-relax -Ttext=0x0 -e _start -Map=$(BUILD_DIR)/$*.map -o $@ $<

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(RISCV_OBJCOPY) -O binary $< $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.bin
	od -An -v -tx1 $< > $@

# E603 also builds its absolute-path source list and invokes VCS from run/.
# Absolute source paths keep both VCS and Verdi independent of their cwd.
$(RUN_DIR)/build_file.vf: filelist.f | install
	@sed 's|^\.\./|$(abspath ..)/|' $< > $@

$(RUN_DIR)/simv: $(RUN_DIR)/build_file.vf $(RTL_SOURCES) ../tb/tb_top.v | install
	@cd $(RUN_DIR) && $(VCS) -full64 -sverilog -timescale=1ns/1ps \
	  +incdir+$(abspath ../rtl/core/exu/units) \
	  -debug_access+all -kdb -lca -top tb_top -f build_file.vf \
	  -o simv -l compile.log

compile: $(RUN_DIR)/simv
	@echo 'compile: ready'

# A run is PASS only when the simulator exits successfully AND the testbench
# prints TEST_PASS. A timeout, hardware halt or incorrect tohost value is FAIL.
run_test: compile $(BUILD_DIR)/$(TEST_NAME).hex
	@mkdir -p $(RUN_DIR)/$(TEST_NAME)
	@rm -f $(RUN_DIR)/$(TEST_NAME)/sim.log $(RUN_DIR)/$(TEST_NAME)/wave.vcd
	@status=0; (cd $(RUN_DIR) && ./simv $(SIM_ARGS) -l $(TEST_NAME)/sim.log) || status=$$?; \
	  if [ $$status -eq 0 ] && [ -f $(RUN_DIR)/$(TEST_NAME)/sim.log ] \
	     && grep -q 'TEST_PASS' $(RUN_DIR)/$(TEST_NAME)/sim.log \
	     && ! grep -q 'TEST_FAIL' $(RUN_DIR)/$(TEST_NAME)/sim.log; then \
	    printf 'PASS %s\n' '$(TEST_NAME)'; \
	  else \
	    printf 'FAIL %s (see %s)\n' '$(TEST_NAME)' '$(RUN_DIR)/$(TEST_NAME)/sim.log'; \
	    if [ '$(ALLOW_FAIL)' != '1' ]; then exit 1; fi; \
	  fi

# Only inspect an already generated waveform; never rerun the simulation.
wave:
	@test -s $(RUN_DIR)/$(TEST_NAME)/wave.vcd || { \
	  echo 'No waveform found: $(RUN_DIR)/$(TEST_NAME)/wave.vcd'; \
	  echo 'Run make run_test TESTCASE=$(TEST_NAME) DUMPWAVE=1 first'; exit 1; }
	@test -s $(RUN_DIR)/build_file.vf || { \
	  echo 'No source list found: $(RUN_DIR)/build_file.vf'; exit 1; }
	@command -v $(VERDI) >/dev/null 2>&1 || { echo 'Missing tool: $(VERDI)'; exit 1; }
	@(cd $(RUN_DIR) && $(VERDI) +incdir+$(abspath ../rtl/core/exu/units) \
	  -f build_file.vf -top tb_top -ssf $(TEST_NAME)/wave.vcd -nologo) &

tests: $(addprefix $(BUILD_DIR)/,$(addsuffix .hex,$(TESTS)))
regress:
	@failed=0; for t in $(TESTS); do \
	  $(MAKE) run_test TESTCASE=$$t DUMPWAVE=0 || failed=1; \
	done; \
	if [ $$failed -ne 0 ]; then echo 'FAIL regression'; exit 1; fi; \
	echo 'PASS regression'

list:
	@echo $(TESTS)

disasm: $(BUILD_DIR)/$(TEST_NAME).elf
	$(RISCV_OBJDUMP) -d -M no-aliases $<

clean:
	rm -rf $(BUILD_DIR) $(RUN_DIR) $(INSTALL_DIR)
