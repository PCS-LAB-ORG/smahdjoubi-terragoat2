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

* Terraform >= 1.5 (the Azure stack uses the azurerm provider 4.x)
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

You can deploy multiple TerraGoat stacks in a single Azure subscription using the parameter `TF_VAR_environment`.

The full Azure guide is [terraform/azure/README.md](terraform/azure/README.md). It covers how the stack is built, how to pick services, and a **catalog of all misconfigurations with their Checkov / Prisma Cloud / Cortex Cloud check IDs**.

TerraGoat supports two permission modes:

| Mode | You need | How |
|------|----------|-----|
| **Resource-group mode** (default) | Reader on the subscription + **Contributor on an existing resource group** | `TF_VAR_resource_group_name=<your RG>` |
| **Subscription mode** | **Owner** on the subscription | `TF_VAR_deploy_subscription_resources=true`; TerraGoat creates its own resource group if `TF_VAR_resource_group_name` is unset. It also deploys a custom role, a policy assignment, Defender for Cloud pricing + contact, and an activity log export. |

> :warning: In subscription mode, `security_center.tf` sets the Defender for Cloud plan for **Virtual Machines** to `Free` for the **whole subscription**. Don't use it on a subscription that relies on Defender for Servers.

Other requirements:
* **Resource-group mode:** the needed resource providers must already be registered on the subscription. See [Permission modes](terraform/azure/README.md#permission-modes) for the list and a check command.
* About 8 vCPUs of quota in the region if you deploy both `aks` and `vms` (2 AKS nodes + 2 VMs, 2 vCPUs each).

#### Log in to Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# The azurerm 4.x provider requires the subscription ID to be set explicitly
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

#### Create an Azure Storage Account backend to keep Terraform state

The state storage account goes in your resource group. In subscription mode you can also create a separate group for it with `az group create`.

```bash
export TERRAGOAT_RESOURCE_GROUP="<your-resource-group>"
export TERRAGOAT_STATE_STORAGE_ACCOUNT="mydevsecopssa"   # globally unique, 3-24 lowercase letters/numbers
export TERRAGOAT_STATE_CONTAINER="mydevsecops"
export TF_VAR_environment="dev"                         # 1-10 lowercase letters/numbers
export TF_VAR_resource_group_name=$TERRAGOAT_RESOURCE_GROUP
export TF_VAR_services='["storage","networking","sql"]'   # what to deploy, or '["all"]'; nothing is deployed by default
# optional: export TF_VAR_location="westeurope"         # defaults to the resource group's region

# Create storage account
az storage account create --name $TERRAGOAT_STATE_STORAGE_ACCOUNT --resource-group $TERRAGOAT_RESOURCE_GROUP --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2

# Create blob container
az storage container create --name $TERRAGOAT_STATE_CONTAINER --account-name $TERRAGOAT_STATE_STORAGE_ACCOUNT --auth-mode key
```

#### Apply TerraGoat (Azure)

**Nothing is deployed unless you select it.** Set `TF_VAR_services` to a list of services: `storage`, `networking`, `vms`, `aks`, `app_gateway`, `app_service`, `key_vault`, `sql`, `mysql`, `postgresql`, or `all`. See [service selection](terraform/azure/README.md#variables-and-service-selection) for what each one contains and costs.

```bash
cd terraform/azure/
terraform init -reconfigure \
    -backend-config="resource_group_name=$TERRAGOAT_RESOURCE_GROUP" \
    -backend-config="storage_account_name=$TERRAGOAT_STATE_STORAGE_ACCOUNT" \
    -backend-config="container_name=$TERRAGOAT_STATE_CONTAINER" \
    -backend-config="key=$TF_VAR_environment.terraform.tfstate"

terraform plan     # review what will be created
terraform apply
```

A full apply takes about 20-30 minutes; the AKS cluster, Application Gateway and database servers are the slowest resources.

<details>
<summary>PowerShell (Windows) equivalent</summary>

```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv

$env:TERRAGOAT_RESOURCE_GROUP = "<your-resource-group>"
$env:TERRAGOAT_STATE_STORAGE_ACCOUNT = "mydevsecopssa"
$env:TERRAGOAT_STATE_CONTAINER = "mydevsecops"
$env:TF_VAR_environment = "dev"
$env:TF_VAR_resource_group_name = $env:TERRAGOAT_RESOURCE_GROUP
$env:TF_VAR_services = '["storage","networking","sql"]'

az storage account create --name $env:TERRAGOAT_STATE_STORAGE_ACCOUNT --resource-group $env:TERRAGOAT_RESOURCE_GROUP --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2
az storage container create --name $env:TERRAGOAT_STATE_CONTAINER --account-name $env:TERRAGOAT_STATE_STORAGE_ACCOUNT --auth-mode key

cd terraform/azure/
terraform init -reconfigure `
    "-backend-config=resource_group_name=$env:TERRAGOAT_RESOURCE_GROUP" `
    "-backend-config=storage_account_name=$env:TERRAGOAT_STATE_STORAGE_ACCOUNT" `
    "-backend-config=container_name=$env:TERRAGOAT_STATE_CONTAINER" `
    "-backend-config=key=$env:TF_VAR_environment.terraform.tfstate"

terraform plan
terraform apply
```

</details>

<details>
<summary>Using local state instead of a storage account</summary>

If you don't need remote state, skip the backend storage account and create `terraform/azure/override.tf` (it is git-ignored):

```hcl
terraform {
  backend "local" {}
}
```

Then run `terraform init` and `terraform apply`.

</details>

#### Remove TerraGoat (Azure)

```bash
terraform destroy
```

In resource-group mode, `terraform destroy` removes only what TerraGoat created. Your resource group and the state storage account stay. The Key Vault stays soft-deleted for 7 days, because purging it needs subscription permissions.

#### Troubleshooting (Azure)

* **`subscription ID could not be determined`**: set `ARM_SUBSCRIPTION_ID` (see above) or `TF_VAR_subscription_id`.
* **`AuthorizationFailed` on a subscription-level resource** (role definition, policy, security center, diagnostic setting): you're not Owner. Use resource-group mode (`TF_VAR_deploy_subscription_resources=false`, the default).
* **`MissingSubscriptionRegistration`**: a resource provider isn't registered. Ask a subscription admin to run `az provider register --namespace <namespace from the error>`, or leave that service out of `TF_VAR_services`.
* **`QuotaExceeded` / `Operation could not be completed as it results in exceeding approved ... Cores quota`**: request more vCPU quota, choose another region with `TF_VAR_location`, or leave `aks` / `vms` out of `TF_VAR_services`.
* **`LocationIsOfferRestricted` / `ProvisioningDisabled` / `RegionDoesNotAllowProvisioning`** for SQL, MySQL or PostgreSQL: Azure doesn't allow new servers of that type in that region for your subscription type. Choose another region with `TF_VAR_location`.
* **A name is already taken**: names include `TF_VAR_environment` plus a random number. Pick another environment name.
* **The network watcher**: Azure allows one per region per subscription. TerraGoat reuses an existing one, usually `NetworkWatcher_<region>` in `NetworkWatcherRG`. In resource-group mode, the (disabled) VNet flow log is skipped when that watcher sits outside your resource group.

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
