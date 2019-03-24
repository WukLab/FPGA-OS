# DO NOT CHANGE THIS. This is coded through the repo
project_path=generated_hls_project

VIVADO_HLS = vivado_hls

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

all:
	$(VIVADO_HLS) -f run_hls_$(TARGET_BOARD).tcl

g:
	$(VIVADO_HLS) -p $(project_path)

clean:
	rm -rf $(project_path)

help:
	@echo "Help"
	@echo "  # make       <- Compile projects"
	@echo "  # make g     <- Open GUI"
