.PHONY:apply clean init check des

pvc:
	cd pvc && make init && make apply && cd ..

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
	# never destroy pvc, or you will lost all the data
	TF_LOG=INFO terraform destroy
