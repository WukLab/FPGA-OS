HLS_PRJ      		= generated_hls_project
HLS_BUDDY_PRJ  		= generated_mcd_buddy_project
VIV_PRJ_PATH 		= generated_vivado_project
VIV_BUDDY_PRJ_PATH	= generated_vivado_buddy_project
VIVADO_PRJ   		= generated_vivado_project/memcached_pipeline.xpr
VIVADO_BUDDY_PRJ 	= generated_vivado_buddy_project/memcached_buddy.xpr

VIVADO_HLS = vivado_hls
VIVADO     = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

.DEFAULT_GOAL := mcd_buddy_top

mcd_top: mcd_comp ip mcd_prj
mcd_buddy_top: mcd_buddy_comp buddy_ip ip mcd_buddy_prj
.PHONY: mcd_buddy_top

mcd_prj:
	$(VIVADO) -mode tcl -source run_vivado.tcl

mcd_buddy_prj:
	$(VIVADO) -mode tcl -source run_vivado_buddy.tcl

ip:
	$(Q)./generate_hls.sh $(TARGET_BOARD)

mcd_comp:
	$(VIVADO_HLS) -f run_hls_mcd_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_writeConverter_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_readConverter_$(TARGET_BOARD).tcl

buddy_ip:
	make -C "../../../alloc"

temp:
	$(VIVADO_HLS) -f run_hls.memcachedBuddy_$(TARGET_BOARD).tcl
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	$(VIVADO) -mode tcl -source run_vivado_buddy.tcl

mcd_buddy_comp:
	#$(VIVADO_HLS) -f run_hls.memcachedBuddy_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_writeConverter_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_readConverter_$(TARGET_BOARD).tcl

dummy:
	$(VIVADO_HLS) -f run_hls_flash_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_dummyPCIe_$(TARGET_BOARD).tcl
	$(VIVADO_HLS) -f run_hls_dram_$(TARGET_BOARD).tcl

g_hls:
	$(VIVADO_HLS) -p $(HLS_PRJ)

g_buddy_hls:
	$(VIVADO_HLS) -p $(HLS_BUDDY_PRJ)

g_prj:
	$(VIVADO) $(VIVADO_PRJ)

g_buddy_prj:
	$(VIVADO) $(VIVADO_BUDDY_PRJ)

clean:
	rm -rf $(HLS_PRJ)
	rm -rf $(VIV_PRJ_PATH)
	rm -rf $(HLS_BUDDY_PRJ)
	rm -rf $(VIV_BUDDY_PRJ_PATH)
	rm -rf generated_readConverter_project/
	rm -rf generated_writeConverter_project/
	find . -name "*_prj" -type d | xargs rm -rf
	find . -name "*_project" -type d | xargs rm -rf
	find . -name "vivado*.jou" -type f | xargs rm -rf
	find . -name "vivado*.log" -type f | xargs rm -rf

all: mcd_top mcd_buddy_top dummy

help:
	@echo "Help"
	@echo "  # make mcd_top	<- Compile HLS for the pipeline readconverter and writeconverter and create a top level bd with Vivado project"
	@echo "  # make mcd_buddy_top	<- make mcd_top with buddy allocator"
	@echo "  # make mcd_comp 	<- Compile HLS for the pipeline readconverter and writeconverter"
	@echo "  # make mcd_buddy_comp	<- make mcd_comp with buddy allocator"
	@echo "  # make ip		<- Move the HLS of pipeline , *converters and the Top to the IpRepository"
	@echo "  # make dummy		<- Compile HLS for the model for Flash,DRAM and pcie mem allocation"
	@echo "  # make g_hls		<- Open GUI for memchache pipeline HLS"
	@echo "  # make g_buddy_hls	<- Open GUI for memchache pipeline with buddy HLS"
	@echo "  # make g_prj		<- Open GUI for memchache pipeline top BlockDesign with data_mover and converters"
	@echo "  # make g_buddy_prj	<- Open GUI for memchache pipeline top with Buddy, BlockDesign, data_mover, and converters"
