.PHONY : clean
All:
	cd ./build && cmake ..
#	make -f ./build/usermanagement/Makefile
#	make -f ./build/paramconfig/Makefile
#	make -f ./build/devicesearch/Makefile
#	make -f ./build/avmanagement/Makefile
	cd ./build && make
	cp ./userinterface/Include/* ../output/linux/Include
clean:
	rm -rf ./build/*
	rm -rf ../output/linux/lib/*