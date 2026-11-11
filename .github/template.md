# TerraGoat - Vulnerable Terraform Infrastructure

[![Maintained by Bridgecrew.io](https://img.shields.io/badge/maintained%20by-bridgecrew.io-blueviolet)](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat)
[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/general)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=INFRASTRUCTURE+SECURITY)
[![CIS Azure](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_azure)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+AZURE+V1.1)
[![CIS GCP](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_gcp)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+GCP+V1.1)
[![CIS AWS](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_aws)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+AWS+V1.2)
[![PCI](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/pci)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=PCI-DSS+V3.2)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg) 
[![slack-community](https://img.shields.io/badge/Slack-4A154B?style=plastic&logo=slack&logoColor=white)](https://slack.bridgecrew.io/)


TerraGoat is Bridgecrew's "Vulnerable by Design" Terraform repository.
![Terragoat](terragoat-logo.png)

TerraGoat is Bridgecrew's "Vulnerable by Design" Terraform repository.
TerraGoat is a learning and training project that demonstrates how common configuration errors can find their way into production cloud environments.

## Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [AWS](#aws-setup)
  * [Azure](#azure-setup)
  * [GCP](#gcp-setup)
* [Contributing](#contributing)
* [Support](#support)

## Introduction

TerraGoat was built to enable DevSecOps design and implement a sustainable misconfiguration prevention strategy. It can be used to test a policy-as-code framework like [Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) & [Checkov](https://github.com/bridgecrewio/checkov/), inline-linters, pre-commit hooks or other code scanning methods.

TerraGoat follows the tradition of existing *Goat projects that provide a baseline training ground to practice implementing secure development best practices for cloud infrastructure.

## Important notes

* **Where to get help:** the [Bridgecrew Community Slack](https://slack.bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat)

Before you proceed please take a not of these warning:
> :warning: TerraGoat creates intentionally vulnerable AWS resources into your account. **DO NOT deploy TerraGoat in a production environment or alongside any sensitive AWS resources.**

## Requirements

* Terraform >= 1.9 (the Azure stack uses the azurerm provider 4.x)
* aws cli
* azure cli (>= 2.60)

To prevent vulnerable infrastructure from arriving to production see: [Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) & [checkov](https://github.com/bridgecrewio/checkov/), the open source static analysis tool for infrastructure as code.

## Getting started

### AWS Setup

#### Installation (AWS)

You can deploy multiple TerraGoat stacks in a single AWS account using the parameter `TF_VAR_environment`.

#### Create an S3 Bucket backend to keep Terraform state

```bash
export TERRAGOAT_STATE_BUCKET="mydevsecops-bucket"
export TF_VAR_company_name=acme
export TF_VAR_environment=mydevsecops
export TF_VAR_region="us-west-2"

aws s3api create-bucket --bucket $TERRAGOAT_STATE_BUCKET \
    --region $TF_VAR_region --create-bucket-configuration LocationConstraint=$TF_VAR_region

# Enable versioning
aws s3api put-bucket-versioning --bucket $TERRAGOAT_STATE_BUCKET --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket $TERRAGOAT_STATE_BUCKET --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      }
    }
  ]
}'
```

#### Apply TerraGoat (AWS)

```bash
cd terraform/aws/
terraform init \
-backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
-backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
-backend-config="region=$TF_VAR_region"

terraform apply
```

#### Remove TerraGoat (AWS)

```bash
terraform destroy
```

#### Creating multiple TerraGoat AWS stacks

```bash
cd terraform/aws/
export TERRAGOAT_ENV=$TF_VAR_environment
export TERRAGOAT_STACKS_NUM=5
for i in $(seq 1 $TERRAGOAT_STACKS_NUM)
do
    export TF_VAR_environment=$TERRAGOAT_ENV$i
    terraform init \
    -backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform apply -auto-approve
done
```

#### Deleting multiple TerraGoat stacks (AWS)

```bash
cd terraform/aws/
export TF_VAR_environment = $TERRAGOAT_ENV
for i in $(seq 1 $TERRAGOAT_STACKS_NUM)
do
    export TF_VAR_environment=$TERRAGOAT_ENV$i
    terraform init \
    -backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform destroy -auto-approve
done
```

### Azure Setup

#### Installation (Azure)

You can deploy multiple TerraGoat stacks in a single Azure subscription by giving each one its own `environment` name.

The full Azure guide is [terraform/azure/README.md](terraform/azure/README.md). It covers how the stack is built, every setting, and a **catalog of all misconfigurations with their Checkov / Prisma Cloud / Cortex Cloud check IDs**.

TerraGoat supports two permission modes:

| Mode | You need | Settings in `terraform.tfvars` |
|------|----------|-----|
| **Resource-group mode** (default) | **Contributor on an existing resource group**, nothing at subscription level | `resource_group_name = "<your RG>"` (required) |
| **Subscription mode** | **Owner** on the subscription | `deploy_subscription_resources = true`. If `resource_group_name` is not set, TerraGoat creates its own resource group. It also deploys a custom role, a policy assignment, Defender for Cloud pricing + contact, an activity log export, and a network watcher flow log. |

> :warning: In subscription mode, `security_center.tf` sets the Defender for Cloud plan for **Virtual Machines** to `Free` for the **whole subscription**. Don't use it on a subscription that relies on Defender for Servers.

Other requirements:
* **Resource-group mode:** the needed resource providers must already be registered on the subscription. You cannot do that yourself, so ask a subscription admin; the list and command are in [Permission modes](terraform/azure/README.md#permission-modes). This mode never touches network watchers (no flow log is deployed) and never creates a resource group.
* About 8 vCPUs of quota in the region if you deploy both `aks` and `vms` (2 AKS nodes + 2 VMs, 2 vCPUs each).

#### Log in to Azure

The azurerm 4.x provider needs the subscription ID, so set `ARM_SUBSCRIPTION_ID` after logging in (replace `<SUBSCRIPTION_ID>`):

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

In PowerShell, the last line is `$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv`.

#### Configure TerraGoat (Azure)

All settings go in `terraform/azure/terraform.tfvars` (git-ignored). Start from the example:

```bash
cd terraform/azure/
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars`. At minimum, set:

* `resource_group_name`: your existing resource group.
* `services`: what to deploy. **Nothing is deployed unless you select it.** Use any of `storage`, `networking`, `vms`, `aks`, `app_gateway`, `app_service`, `key_vault`, `sql`, `mysql`, `postgresql`, or `["all"]`. See [service selection](terraform/azure/README.md#variables-and-service-selection) for what each one contains and costs.

```hcl
resource_group_name = "my-resource-group"
environment         = "dev"
services            = ["storage", "networking", "sql"]
```

The example file also lists the optional settings: `location`, `vm_size`, `aks_node_size`, `zone`, `web_apps_via_azapi` and `deploy_subscription_resources`. Keeping everything in this file means `terraform plan` / `apply` need no `-var` arguments, which avoids shell quoting problems.

#### Apply TerraGoat (Azure)

```bash
terraform init
terraform plan
terraform apply
```

A full apply with `["all"]` takes about 15-25 minutes; the AKS cluster, Application Gateway and database servers are the slowest resources.

<details>
<summary>Optional: keep the Terraform state in an Azure storage account</summary>

By default the state is a local `terraform.tfstate` file in `terraform/azure/`. To keep it in Azure instead, create a storage account and container in your resource group (replace the names; the account name must be globally unique, 3-24 lowercase letters/numbers):

```bash
az storage account create --name mystateaccount123 --resource-group my-resource-group --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2
az storage container create --name tfstate --account-name mystateaccount123 --auth-mode key
cp backend.tf.example backend.tf
```

Edit `backend.tf` (git-ignored) with the same names, then run `terraform init`. If you already have local state, run `terraform init -migrate-state` instead to move it.

</details>

#### Remove TerraGoat (Azure)

```bash
terraform destroy
```

In resource-group mode, `terraform destroy` removes only what TerraGoat created. Your resource group (and a state storage account, if you made one) stays. The Key Vault stays soft-deleted for 7 days, because purging it needs subscription permissions.

#### Troubleshooting (Azure)

Settings below refer to `terraform/azure/terraform.tfvars`.

* **`Too many command line arguments`**: the shell passed extra words to Terraform. Common causes: a pasted command with a trailing `# comment` in **zsh** (the macOS default shell, which doesn't treat `#` as a comment when you paste), or PowerShell splitting arguments such as `-var=...` or `-out=plan.tfplan`. Run `terraform plan` / `terraform apply` without extra arguments and put your settings in `terraform.tfvars`. If you do need an argument in PowerShell, quote it whole, for example `terraform plan "-out=tg.tfplan"`.
* **`SkuNotAvailable` (409) when creating the VMs or AKS**: that VM size isn't available for your subscription in that region, or only in some availability zones. In the Azure portal (Virtual machines > Create), choose your region to see which sizes and zones you can use, then set `vm_size` / `aks_node_size` and, if needed, `zone`, e.g. `vm_size = "Standard_D2s_v3"` and `zone = "2"`.
* **`subscription ID could not be determined`**: set `ARM_SUBSCRIPTION_ID` (see above) or `subscription_id`.
* **`AADSTS50076` ... you must use multi-factor authentication** (on any create/update/delete): Azure requires MFA for write operations, and your CLI sign-in has none. Run `az logout`, then the `az login --tenant ... --claims-challenge ...` command printed in the error, and complete the MFA prompt in the browser. Terraform reuses the Azure CLI sign-in.
* **`AuthorizationFailed` on a subscription-level resource** (role definition, policy, security center, diagnostic setting, network watcher): you're not Owner. Use resource-group mode (`deploy_subscription_resources = false`, the default).
* **`AuthorizationFailed` ... `Microsoft.Web/checknameavailability/action` over scope `/subscriptions/...`** when creating the web apps: the azurerm web app resource checks the name at subscription level, which Contributor on your resource group doesn't allow. Set `web_apps_via_azapi = true` and apply again: the same apps are created through the `azapi` provider. (Choosing a different name doesn't help; the check itself is refused.)
* **`Invalid value for variable` ... `resource_group_name`**: you're in resource-group mode without `resource_group_name`. Set it to your existing resource group. Only subscription mode creates a resource group (`terragoat-<environment>`).
* **`MissingSubscriptionRegistration`**: a resource provider isn't registered. Ask a subscription admin to run `az provider register --namespace <namespace from the error>`, or leave that service out of `services`.
* **`QuotaExceeded` / `Operation could not be completed as it results in exceeding approved ... Cores quota`**: request more vCPU quota, choose a smaller `vm_size`, another `location`, or leave `aks` / `vms` out of `services`.
* **`LocationIsOfferRestricted` / `ProvisioningDisabled` / `RegionDoesNotAllowProvisioning`** for SQL, MySQL or PostgreSQL: Azure doesn't allow new servers of that type in that region for your subscription type. Choose another `location`.
* **A name is already taken**: names include `environment` plus a random number. Pick another `environment`.
* **`NetworkWatcherCountLimitReached` / network watcher already exists**: Azure allows one network watcher per region per subscription (usually `NetworkWatcher_<region>` in `NetworkWatcherRG`). In resource-group mode TerraGoat never creates or looks up a network watcher, so this cannot happen there. In subscription mode it reuses the existing watcher, and creates its own (before the VNet and AKS) only when the region has none; if a failed run hit this error, run `terraform apply` again.

### GCP Setup

#### Installation (GCP)

You can deploy multiple TerraGoat stacks in a single GCP project using the parameter `TF_VAR_environment`.

#### Create a GCS backend to keep Terraform state

To use terraform, a Service Account and matching set of credentials are required.
If they do not exist, they must be manually created for the relevant project.
To create the Service Account:
1. Sign into your GCP project, go to `IAM` > `Service Accounts`.
2. Click the `CREATE SERVICE ACCOUNT`.
3. Give a name to your service account (for example - `terragoat`) and click `CREATE`.
4. Grant the Service Account the `Project` > `Editor` role and click `CONTINUE`.
5. Click `DONE`.

To create the credentials:
1. Sign into your GCP project, go to `IAM` > `Service Accounts` and click on the relevant Service Account.
2. Click `ADD KEY` > `Create new key` > `JSON` and click `CREATE`. This will create a `.json` file and download it to your computer.

We recommend saving the key with a nicer name than the auto-generated one (i.e. `terragoat_credentials.json`), and storing the resulting JSON file inside `terraform/gcp` directory of terragoat.
Once the credentials are set up, create the BE configuration as follows:

```bash
export TF_VAR_environment="dev"
export TF_TERRAGOAT_STATE_BUCKET=remote-state-bucket-terragoat
export TF_VAR_credentials_path=<PATH_TO_CREDNETIALS_FILE> # example: export TF_VAR_credentials_path=terragoat_credentials.json
export TF_VAR_project=<YOUR_PROJECT_NAME_HERE>

# Create storage bucket
gsutil mb gs://${TF_TERRAGOAT_STATE_BUCKET}
```

#### Apply TerraGoat (GCP)

```bash
cd terraform/gcp/
terraform init -reconfigure -backend-config="bucket=$TF_TERRAGOAT_STATE_BUCKET" \
    -backend-config "credentials=$TF_VAR_credentials_path" \
    -backend-config "prefix=terragoat/${TF_VAR_environment}"

terraform apply
```

#### Remove TerraGoat (GCP)

```bash
terraform destroy
```

## Bridgecrew's IaC herd of goats

* [CfnGoat](https://github.com/bridgecrewio/cfngoat) - Vulnerable by design Cloudformation template
* [TerraGoat](https://github.com/bridgecrewio/terragoat) - Vulnerable by design Terraform stack
* [CDKGoat](https://github.com/bridgecrewio/cdkgoat) - Vulnerable by design CDK application
* [kustomizegoat](https://github.com/bridgecrewio/kustomizegoat) - Vulnerable by design kustomize deployment
## Contributing

Contribution is welcomed!

We would love to hear about more ideas on how to find vulnerable infrastructure-as-code design patterns.

## Support

[Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) builds and maintains TerraGoat to encourage the adoption of policy-as-code.

If you need direct support you can contact us at [info@bridgecrew.io](mailto:info@bridgecrew.io).

## Existing vulnerabilities (Auto-Generated)
