all: build

init:
	terraform init

validate: init
	terraform validate -var-file=terraform.tfvars

build: validate
	terraform apply -auto-approve -var-file=terraform.tfvars

debug: validate
ifeq ($(OS),Windows_NT)
	$(set TF_LOG=trace)
else
	$(TF_LOG=trace)
endif
	terraform apply -var-file=terraform.tfvars

destroy:
	echo "yes" | terraform destroy
