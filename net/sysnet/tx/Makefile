# DO NOT CHANGE THIS. This is coded through the repo
project_path=generated_hls_project

VIVADO_HLS = vivado_hls

all:
	$(VIVADO_HLS) -f run_hls.tcl

g:
	$(VIVADO_HLS) -p $(project_path)

clean:
	rm -rf generated_project/

help:
	@echo "Help"
	@echo "  # make       <- Compile projects"
	@echo "  # make g     <- Open GUI"
