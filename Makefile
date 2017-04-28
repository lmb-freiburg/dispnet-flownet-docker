
default: dispflownet

.PHONY: dispflownet

dispflownet:
	docker build -f Dockerfile -t dispflownet .

