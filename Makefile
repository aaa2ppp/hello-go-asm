MODULE := $(shell sed -n '1s/module //p' go.mod)

help:
	@echo build run clean

.build: *.go *.s
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/app
	docker build -q -t $(MODULE) . > .image-id
	touch .build

build: .build

run: .build
	$(eval IMAGE_ID := $(shell cat .image-id))
	$(eval CONTAINER_ID := $(shell docker ps -aq --filter ancestor='$(IMAGE_ID)' --latest))
	@docker stop '$(CONTAINER_ID)' >/dev/null 2>&1 && docker start -a '$(CONTAINER_ID)' || docker run '$(IMAGE_ID)'

clean:
	$(eval IMAGE_ID := $(shell cat .image-id))
	$(eval CONTAINER_ID := $(shell docker ps -aq --filter ancestor='$(IMAGE_ID)'))
	test -z '$(CONTAINER_ID)' || ( docker stop $(CONTAINER_ID) && docker rm $(CONTAINER_ID) )
	test -z '$(IMAGE_ID)' || docker rmi $(IMAGE_ID)
	-rm -fr .build .image-id bin