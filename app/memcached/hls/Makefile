HLS_PRJ      = generated_hls_project
VIV_PRJ_PATH = generated_vivado_project
VIVADO_PRJ   = generated_vivado_project/memcached_pipeline.xpr

VIVADO_HLS = vivado_hls
VIVADO     = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

.DEFAULT_GOAL := mcd_top

mcd_top: mcd_comp ip mcd_prj
.PHONY: mcd_top

mcd_prj:
	$(VIVADO) -mode tcl -source run_vivado.tcl

ip:
	$(Q)./generate_hls.sh $(TARGET_BOARD)

mcd_comp:
	$(VIVADO_HLS) -f run_hls_mcd_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_writeConverter_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_readConverter_$(TARGET_BOARD).tcl

dummy:
	$(VIVADO_HLS) -f run_hls_flash_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_dummyPCIe_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_dram_$(TARGET_BOARD).tcl

g_hls:
	$(VIVADO_HLS) -p $(HLS_PRJ)

g_prj:
	$(VIVADO) $(VIVADO_PRJ)

clean:
	rm -rf $(HLS_PRJ)
	rm -rf $(VIV_PRJ_PATH)
	find . -name "*_prj" -type d | xargs rm -rf
	find . -name "*_project" -type d | xargs rm -rf
	find . -name "vivado*.jou" -type f | xargs rm -rf
	find . -name "vivado*.log" -type f | xargs rm -rf

all: mcd_top dummy

help:
	@echo "Help"
	@echo "  # make mcd_top  <- Compile HLS for the pipeline readconverter and writeconverter and create a top level bd with Vivado project"
	@echo "  # make mcd_comp <- Compile HLS for the pipeline readconverter and writeconverter"
	@echo "  # make ip       <- Move the HLS of pipeline , *converters and the Top to the IpRepository"
	@echo "  # make dummy    <- Compile HLS for the model for Flash,DRAM and pcie mem allocation"
	@echo "  # make g_hls    <- Open GUI for memchache pipeline HLS"
	@echo "  # make g_prj    <- Open GUI for memchache pipeline top BlockDesign with data_mover and converters"
