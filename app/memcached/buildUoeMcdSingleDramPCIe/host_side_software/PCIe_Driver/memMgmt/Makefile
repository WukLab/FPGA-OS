commandline_debug:
	mkdir -p ./bin/$@/
	g++ -std=c++0x main.cpp no_hw_uDriver.cpp memManager.cpp -o ./bin/$@/memMgmt -lpthread
commandline_driver:
	mkdir -p ./bin/$@/
	g++ -std=c++0x main.cpp uDriver.cpp memManager.cpp -I ../Linux_Driver/ -o ./bin/$@/memMgmt -lpthread
commandline_hostmem:
	mkdir -p ./bin/$@/
	g++ -std=c++0x main.cpp hostmem_uDriver.cpp memManager.cpp -I ../../handsoff_dma/ -o ./bin/$@/memMgmt -lpthread
commandline_capi:
	mkdir -p ./bin/$@/
	g++ -std=c++0x main.cpp CAPI_devFile_uDriver.cpp memManager.cpp -o ./bin/$@/memMgmt -lpthread
GUI_debug:
	mkdir -p ./bin/$@
	g++ -std=c++11 main.cpp no_hw_uDriver.cpp memManager.cpp Fl_Gauge.cxx Gui.cpp diagram_boxes.cpp -DGUI `fltk-config --cxxflags` `fltk-config --ldflags` -o ./bin/$@/memMgmt -lpthread
GUI_driver:
	mkdir -p ./bin/$@
	g++ -std=c++11 main.cpp uDriver.cpp memManager.cpp Fl_Gauge.cxx Gui.cpp diagram_boxes.cpp -I ../Linux_Driver/  -DGUI `fltk-config --cxxflags` `fltk-config --ldflags` -o ./bin/$@/memMgmt -lpthread
GUI_hostmem:
	mkdir -p ./bin/$@
	g++ -std=c++11 main.cpp hostmem_uDriver.cpp memManager.cpp Fl_Gauge.cxx Gui.cpp diagram_boxes.cpp -I ../../handsoff_dma/  -DGUI `fltk-config --cxxflags` `fltk-config --ldflags` -o ./bin/$@/memMgmt -lpthread
fileOutput_driver:
	mkdir -p ./bin/$@/
	g++ -std=c++0x main.cpp uDriver.cpp memManager.cpp -DFILEOUT -I ../Linux_Driver/ -o ./bin/$@/memMgmt -lpthread
