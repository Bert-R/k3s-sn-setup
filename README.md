# Set up k3s on an LXC container on Proxmox through Terraform and Ansible

Next to this checkout, a directory structure of the following form is required:

* ``secrets/``
* ``secrets/id_rsa`` -- Private key to log in to the container
* ``secrets/k3s-sn-setup``
* ``secrets/k3s-sn-setup/ansible-vars.yml`` -- The following is required:
```
mimir_s3_access_key_id: Access key ID/user name for S3 (MinIO)
mimir_s3_secret_access_key: Access key secret/password name for S3 (MinIO)
```
* ``secrets/k3s-sn-setup/terraform.tfvars`` -- The following is required:
```
# See https://spacelift.io/blog/terraform-tfvars

pm_password = "<Proxmox password>"
ct_password = "<Root password of container being created"
ssh_public_keys = <<-EOT
<Public keys that need access to the container
EOT
```

Commands:

* To deploy: ``terraform apply -var-file="../secrets/k3s-sn-setup/terraform.tfvars"``
* To undeploy: ``terraform apply -destroy -var-file="../secrets/k3s-sn-setup/terraform.tfvars"``
* To just run Ansible: ``(cd ansible;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i k3s-sn.home.famroos.nu, --user root --private-key ../../secrets/id_rsa k3s-sn.yml)``

Hints:
* Sometimes, ssh fails with "Failed to connect to the host via ssh: kex_exchange_identification: Connection closed by remote host". In that case, log in the container through the Proxmox UI and perform ``mkdir /run/sshd``.
