all: build

build:
	@docker build --tag=rickrussell/mysql .
