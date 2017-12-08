# Docker Swarm on Centos 7 using Terraform

Builds any number of Docker managers and workers, joins them to a single swarm cluster, and installs ScaleIO and RexRay driver.

Set your variables in terraform.tfvars (example provided).

The master_setup.sh and worker_setup.sh scripts make use of a FTP server to store the Docker swarm token.

### Add the following files to ./files/
- Any *.pem files you want to add to your CA Certifcate Bundle
- ScaleIO RHEL driver - check that setup.sh has the right SIO driver filename

Add your public ssh key to the files/keys file

Run "make" from the command line

Or:

terraform init
terraform apply
