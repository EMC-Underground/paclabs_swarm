all: build

init:
	terraform init

validate: init
	terraform validate

build: validate
	terraform apply

debug: validate
ifeq ($(OS),Windows_NT)
	$(set TF_LOG=trace)
else
	$(TF_LOG=trace)
endif
	terraform apply

destroy:
	echo "yes" | terraform destroy
