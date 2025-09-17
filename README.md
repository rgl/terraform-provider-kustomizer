# About

[![build](https://github.com/rgl/terraform-provider-kustomizer/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/terraform-provider-kustomizer/actions/workflows/build.yml)
[![terraform provider](https://img.shields.io/badge/terraform%20provider-rgl%2Fkustomizer-blue)](https://registry.terraform.io/providers/rgl/kustomizer)

This generates a Kubernetes Manifest using the [Kustomize Go library](https://github.com/kubernetes-sigs/kustomize) through the [`kustomizer_manifest` data source](docs/data-sources/manifest).

## Usage (Ubuntu 22.04 host)

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/1.13.2/terraform_1.13.2_linux_amd64.zip
unzip terraform_1.13.2_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

Build the development version of this provider and install it:

**NB** This is only needed when you want to develop this plugin. If you just want to use it, let `terraform init` install it [from the terraform registry](https://registry.terraform.io/providers/rgl/kustomizer).

```bash
make
```

Configure terraform to use the local provider by editing your `~/.terraformrc` as, e.g.:

```hcl
# see https://developer.hashicorp.com/terraform/cli/config/config-file#development-overrides-for-provider-developers
# see https://developer.hashicorp.com/terraform/cli/config/config-file
provider_installation {
  dev_overrides {
    # ...
    "rgl/kustomizer" = "/home/vagrant/Projects/terraform-provider-kustomizer"
  }
  direct {
  }
}
```

Create the infrastructure:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
rm -f *.log
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Show the resulting Kubernetes Manifest:

```bash
terraform output manifest
```

Destroy the infrastructure:

```bash
terraform destroy -auto-approve # destroy everything.
```
