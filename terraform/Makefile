.PHONY:apply clean init check des


# TF_LOG=TRACE
apply:
	TF_LOG=INFO terraform apply -auto-approve

clean:
	rm -fdr terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl .terraform

init:
	terraform init

check:
	terraform validate

des:
	TF_LOG=INFO terraform destroy -auto-approve
