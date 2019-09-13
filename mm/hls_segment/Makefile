# Change the absolute path to your own one.
VIVADO_HLS=vivado_hls

# DO NOT CHANGE THIS. This is coded through the repo
project_path=generated_hls_project

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

all:
	$(VIVADO_HLS) -f run_hls_$(TARGET_BOARD).tcl

g:
	$(VIVADO_HLS) -p $(project_path)

clean:
	rm -rf $(project_path)
	rm -rf $(shell pwd)/*.log

help:
	@echo "Help"
	@echo "  # make       <- Compile projects"
	@echo "  # make g     <- Open GUI"
