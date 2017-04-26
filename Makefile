
default: dispflownet

.PHONY: dispflownet

dispflownet:
	docker build -f Dockerfile -t dispflownet . --build-arg CUDA_DRIVER_VER=`modinfo nvidia | grep "^version:" | cut -d':' -f2 | sed 's/ //g'`

