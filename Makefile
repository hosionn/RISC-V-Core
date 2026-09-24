# Compatibility entry point. The actual E603-style simulation project lives in vsim/.
.PHONY: all help install compile run_test wave tests regress list disasm clean
all help install compile run_test wave tests regress list disasm clean:
	@$(MAKE) -C vsim $@
