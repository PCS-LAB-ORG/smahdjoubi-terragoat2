# TerraGoat – Azure

> :warning: Everything in this folder is **intentionally insecure**. Deploy it only into an isolated lab subscription or resource group, and destroy it when you are done.

* [How the stack is built](#how-the-stack-is-built)
* [Permission modes](#permission-modes)
* [Variables and service selection](#variables-and-service-selection)
* [Misconfiguration catalog](#misconfiguration-catalog)
* [What Prisma Cloud / Cortex Cloud will report](#what-prisma-cloud--cortex-cloud-will-report)

Setup and deployment steps are in the [main README](../../README.md#azure-setup).

## How the stack is built

`terraform/azure` is a single, flat Terraform root module (no sub-modules), and each file is one Azure service. **Nothing is deployed by default.** You pick services with the `services` variable (see [below](#variables-and-service-selection)), and Terraform orders the selected resources from their references.

| Service (`services` value) | File | Resources | Approx. cost |
|----------------------------|------|-----------|--------------|
| – | `resource_group.tf` | Resource group, or a lookup of an existing one | – |
| `storage` | `storage.tf` | 2 storage accounts (queue logging, firewall rules), managed disk | low |
| `networking` | `networking.tf` | VNet, subnet, NSG, network watcher (only if needed), VNet flow log | low |
| `vms` | `instance.tf` | Linux VM + Windows VM (`Standard_F2`) + NICs | medium |
| `aks` | `aks.tf` | AKS cluster, 2 × `Standard_D2_v2` nodes | **high** |
| `app_gateway` | `application_gateway.tf` | Application Gateway `Standard_v2`, public IP, subnet | **high** |
| `app_service` | `app_service.tf` | App Service plan `B1`, 2 Linux web apps | low |
| `key_vault` | `key_vault.tf` | Key Vault (premium), RSA key, secret | low |
| `sql` | `sql.tf` | Azure SQL server + firewall rule + threat detection policy | low (no database) |
| `mysql` | `sql.tf` | MySQL flexible server (`B_Standard_B1ms`) + parameter | low |
| `postgresql` | `sql.tf` | PostgreSQL flexible server (`B_Standard_B1ms`) + parameters | low |
| (`deploy_subscription_resources`) | `roles.tf`, `policies.tf`, `security_center.tf`, `logging.tf` | Subscription-scoped: custom role, policy, Defender pricing/contact, activity log export | – |

Shared pieces are created automatically when a selected service needs them:
* The **VNet and default subnet** come with `networking`, `vms` or `app_gateway`.
* The **`tgsa…` storage account** comes with `storage`, `networking`, `sql` or `deploy_subscription_resources`. The flow log, SQL threat detection and activity log export write to it.

The logic is in `services.tf`. Deploying with `["all"]` takes about 15–25 minutes (verified: 35 resources applied and destroyed cleanly in resource-group mode, France Central, azurerm 4.81, November 2026); AKS, the App Gateway and the database servers are the slowest. Resource names include `environment` plus a random number, so several stacks can coexist.

## Permission modes

| | **Resource-group mode** (default) | **Subscription mode** |
|---|---|---|
| Required role | Reader on the subscription + **Contributor on one existing resource group** | **Owner** on the subscription |
| Settings | `TF_VAR_resource_group_name=<your RG>` | `TF_VAR_deploy_subscription_resources=true` (and optionally leave `resource_group_name` unset so TerraGoat creates `terragoat-<env>`) |
| Subscription-scoped resources (role, policy, Defender, security contact, activity log export) | skipped | deployed |
| Resource provider registration | **none**: providers must already be registered (see below) | done automatically by the provider |
| VNet flow log | created only if the region's network watcher is in your RG, or no watcher exists yet (TerraGoat then creates one in your RG) | always created |
| Key Vault on destroy | left soft-deleted for 7 days (purging needs subscription permissions) | purged |

In resource-group mode, these resource providers must already be registered on the subscription. A Reader can check them, but an admin has to register any that are missing:

```bash
for ns in Microsoft.ContainerService Microsoft.Network Microsoft.Compute Microsoft.Storage Microsoft.Web \
          Microsoft.KeyVault Microsoft.Sql Microsoft.DBforMySQL Microsoft.DBforPostgreSQL Microsoft.Insights; do
  echo "$ns: $(az provider show -n $ns --query registrationState -o tsv)"
done
# admin: az provider register --namespace <namespace>
```

## Variables and service selection

| Variable | Default | Description |
|----------|---------|-------------|
| `services` | `[]` (nothing) | Services to deploy: any of `storage`, `networking`, `vms`, `aks`, `app_gateway`, `app_service`, `key_vault`, `sql`, `mysql`, `postgresql`, or `all` |
| `resource_group_name` | `null` | Existing resource group to deploy into; `null` = create `terragoat-<env>` |
| `deploy_subscription_resources` | `false` | Enables subscription-scoped resources (needs Owner) |
| `environment` | `dev` | 1–10 lowercase letters/numbers, part of every resource name |
| `location` | RG location, or `East US` | Azure region |
| `subscription_id` | `null` | Falls back to `ARM_SUBSCRIPTION_ID` |

Examples:

```bash
export TF_VAR_services='["storage","networking","sql"]'   # cheap: storage, NSG/flow log, Azure SQL
export TF_VAR_services='["all"]'                          # everything
```

```powershell
$env:TF_VAR_services = '["storage","networking","sql"]'
```

Or pass it on the command line: `terraform plan -var='services=["key_vault","app_service"]'`. An unknown service name fails validation. With an empty list, `terraform plan` shows a warning and plans nothing.

## Misconfiguration catalog

**Check IDs** are [Checkov](https://www.checkov.io/) policy IDs, verified by scanning this folder with Checkov. A scan with `deploy_subscription_resources=true` reports **112 failed checks** across 88 distinct checks; with the default settings it reports 106.

Two kinds of finding:

* **Intentional**: the core misconfigurations TerraGoat is about. The table describes each one.
* **Hardening**: findings caused by a missing hardening feature (private endpoints, customer-managed keys, zone redundancy, ...). They are listed by ID only.

### Networking (`networking.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_network_security_group.bad_sg` | SSH (22) open to `*` (the internet) | CKV_AZURE_10 |
| `azurerm_network_security_group.bad_sg` | RDP (3389) open to `*` (the internet) | CKV_AZURE_9 |
| `azurerm_network_watcher_flow_log.flow_log` | Flow log **disabled**, retention disabled | CKV_AZURE_12 |
| `azurerm_subnet.example` | Subnet has no NSG associated | CKV2_AZURE_31 |

### Storage (`storage.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_storage_account_queue_properties.example` | Queue logging records writes only, not reads or deletes | CKV_AZURE_33 |
| `azurerm_storage_account_network_rules.test` | Firewall without the "Trusted Microsoft Services" (`AzureServices`) bypass | CKV_AZURE_36 |
| all storage accounts | Public network access allowed, blob public access not disabled, shared-key auth enabled, no SAS expiration policy, no blob soft-delete | CKV_AZURE_59, CKV_AZURE_190, CKV2_AZURE_47, CKV2_AZURE_40, CKV2_AZURE_41, CKV2_AZURE_38 |
| all storage accounts | Minimum TLS version not set explicitly ¹ | CKV_AZURE_44 |
| `azurerm_managed_disk.example` | No disk encryption set / CMK, no Azure Disk Encryption, public network access not disabled | CKV_AZURE_93, CKV_AZURE_251 |

Hardening: CKV2_AZURE_1 (CMK), CKV2_AZURE_33 (private endpoint), CKV_AZURE_206 (LRS replication).

### Virtual machines (`instance.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_linux_virtual_machine.linux_machine` | Password authentication enabled, no SSH key | CKV_AZURE_1, CKV_AZURE_149, CKV_AZURE_178 |
| `azurerm_windows_virtual_machine.windows_machine` | No encryption at host | CKV_AZURE_151 |
| both VMs | VM extensions allowed | CKV_AZURE_50 |

### AKS (`aks.tf`)

| Intentional misconfiguration | Check IDs |
|------------------------------|-----------|
| Kubernetes RBAC disabled | CKV_AZURE_5 |
| No Azure Monitor (Container Insights) logging | CKV_AZURE_4 |
| Public API server without authorized IP ranges, not a private cluster | CKV_AZURE_6, CKV_AZURE_115 |
| No network policy, kubenet instead of Azure CNI | CKV_AZURE_7, CKV2_AZURE_29 |
| Local admin account enabled | CKV_AZURE_141 |
| No Azure Policy add-on | CKV_AZURE_116 |

Hardening: CKV_AZURE_117, CKV_AZURE_168, CKV_AZURE_170, CKV_AZURE_171, CKV_AZURE_172, CKV_AZURE_226, CKV_AZURE_227, CKV_AZURE_232.

### App Service (`app_service.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `app-service1` | HTTPS not enforced (`https_only = false`) | CKV_AZURE_14 |
| `app-service1` | Minimum TLS 1.1 | CKV_AZURE_15 |
| `app-service2` | App Service authentication disabled | CKV_AZURE_13 |
| both apps | FTP(S) deployments allowed, no managed identity, no client certificates, no HTTP/2, no HTTP logs / detailed errors / failed request tracing, public network access | CKV_AZURE_78, CKV_AZURE_71, CKV_AZURE_17, CKV_AZURE_18, CKV_AZURE_63, CKV_AZURE_65, CKV_AZURE_66, CKV_AZURE_222 |

Hardening: CKV_AZURE_13 (app1), CKV_AZURE_16, CKV_AZURE_88, CKV_AZURE_213, CKV_AZURE_211, CKV_AZURE_212, CKV_AZURE_225.

### Application Gateway (`application_gateway.tf`)

| Intentional misconfiguration | Check IDs |
|------------------------------|-----------|
| No WAF (`Standard_v2` instead of `WAF_v2`) | CKV_AZURE_120 |
| Plain HTTP listener, no SSL policy | CKV_AZURE_217, CKV_AZURE_218 |
| Gateway subnet without NSG | CKV2_AZURE_31 |

### Key Vault (`key_vault.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_key_vault.example` | No purge protection, minimum soft-delete retention | CKV_AZURE_110, CKV_AZURE_42 |
| `azurerm_key_vault.example` | Public network access, no firewall (network ACLs), no private endpoint | CKV_AZURE_189, CKV_AZURE_109, CKV2_AZURE_32 |
| `azurerm_key_vault_key.generated` | No expiration date, software-protected (not HSM) key | CKV_AZURE_40, CKV_AZURE_112 |
| `azurerm_key_vault_secret.secret` | No expiration date, no content type | CKV_AZURE_41, CKV_AZURE_114 |

### Azure SQL (`sql.tf`)

A single server carries all SQL misconfigurations. Older TerraGoat versions deployed 7 more, nearly identical servers (`mssql.tf`); they added cost but no unique findings.

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_mssql_server.example` | SQL-auth admin with **hard-coded password** in code | CKV_SECRET_6 (secrets scan) ² |
| `azurerm_mssql_server.example` | Auditing off (and no ≥ 90 day retention) | CKV_AZURE_23, CKV_AZURE_24 |
| `azurerm_mssql_server.example` | Public network access enabled, no private endpoint | CKV_AZURE_113, CKV2_AZURE_45 |
| `azurerm_mssql_server.example` | No Entra ID (Azure AD) admin / authentication | CKV2_AZURE_27 |
| `azurerm_mssql_server.example` | Minimum TLS not set explicitly ¹ | CKV_AZURE_52 |
| `azurerm_mssql_server_security_alert_policy.example` | Threat detection types `Sql_Injection` and `Data_Exfiltration` disabled | CKV_AZURE_25 |
| `azurerm_mssql_server_security_alert_policy.example` | "Email service and co-administrators" disabled | CKV_AZURE_27 |
| `azurerm_mssql_server_security_alert_policy.example` | No alert recipient email address | CKV_AZURE_26 |
| `azurerm_mssql_firewall_rule.example` | Firewall rule on the server | – |

### MySQL / PostgreSQL flexible servers (`sql.tf`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| MySQL | `require_secure_transport = OFF` (TLS not enforced) | – ³ |
| MySQL | Public network access, no private endpoint, no geo-redundant backups | CKV_AZURE_53, CKV2_AZURE_56, CKV_AZURE_94 |
| PostgreSQL | `require_secure_transport = off`, `log_checkpoints = off`, `connection_throttle.enable = off` | – ³ |
| PostgreSQL | Public network access, no private endpoint, no geo-redundant backups, hard-coded admin password | CKV2_AZURE_57, CKV_AZURE_136 |

### Subscription-scoped (only with `deploy_subscription_resources = true`)

| Resource | Intentional misconfiguration | Check IDs |
|----------|------------------------------|-----------|
| `azurerm_role_definition.example` | Custom role with `actions = ["*"]` at subscription scope (custom owner role) | CKV_AZURE_39 |
| `azurerm_security_center_subscription_pricing.pricing` | Defender for Servers set to **Free** | CKV_AZURE_19, CKV_AZURE_55 |
| `azurerm_security_center_contact.contact` | Alert notifications and alerts-to-admins disabled, no phone number | CKV_AZURE_20, CKV_AZURE_21, CKV_AZURE_22 |
| `azurerm_monitor_diagnostic_setting.activity_log` | Activity log export captures only the `Administrative` category | – ³ |
| `azurerm_subscription_policy_assignment.example` | Policy with `audit` effect only (no enforcement) | – |

¹ The azurerm 4.x provider defaults minimum TLS to 1.2 on storage accounts and SQL servers, so the **deployed** resources use TLS 1.2. IaC scanners still flag them because the attribute is not set explicitly. Runtime (CSPM) scanners will **not** flag them.<br>
² Checkov's secrets scanner flags the SQL server password as a high-entropy string. The PostgreSQL password is just as hard-coded but is not detected.<br>
³ There's no Checkov check for this misconfiguration on this resource type, so it shows up only in a runtime (CSPM) scan of the deployed resource. Older TerraGoat versions flagged it on resources Azure has since retired: MySQL/PostgreSQL Single Server (CKV_AZURE_28/29/30/32) and log profiles (CKV_AZURE_37/38).

**No longer reproducible**, because Azure removed the feature: the AKS Kubernetes Dashboard add-on (was CKV_AZURE_8), and disabling disk encryption via `encryption_settings.enabled = false` (was CKV_AZURE_2).

## What Prisma Cloud / Cortex Cloud will report

TerraGoat is meant to be used both ways. You can scan the **code**, and you can **deploy** it and scan the live resources. The `yor_trace` / `git_*` tags on the resources link a cloud finding back to the line of code that created it.

The two scans see different things. An IaC scan reads the Terraform files; a runtime (CSPM) scan reads the deployed configuration from the Azure API. So:

* Some findings appear in only one of them (see below).
* An IaC scan reports every service in the code. A runtime scan reports only the services you deployed.

* **IaC scanning (Prisma Cloud Application Security / Code Security, Cortex Cloud Application Security).** Palo Alto Networks' IaC scanning is built on Checkov, so a scan of this folder reports the same misconfigurations as the tables above. The console shows its own policy names and severities, but each policy maps to the Checkov ID above.
  * **Service selection:** Checkov does not evaluate the `services` selection, so a repo scan reports all services even though nothing is deployed by default. That's 106 findings.
  * **Subscription-scoped resources:** these use a plain boolean, which Checkov does evaluate. They're reported only when the scan sets `deploy_subscription_resources = true`, for example `checkov -d . --var-file sub.tfvars`. That brings the total to 112.
* **Runtime posture (CSPM) on the deployed resources.** After `terraform apply`, a connected Azure account is scanned on the actual resource configuration. Expect most of the intentional misconfigurations above to show up there too, notably:
  * the internet-exposed SSH/RDP NSG rules
  * the storage firewall without trusted services, and public blob access
  * SQL auditing off and the disabled threat-detection types
  * MySQL/PostgreSQL without enforced TLS
  * Key Vault without purge protection, and keys/secrets without expiration
  * AKS without RBAC
  * web apps without HTTPS-only / with TLS 1.1
  * the App Gateway without WAF
  * the disabled flow log

  The resource configuration of a runtime scan comes from the Azure API, so it differs from an IaC scan in two ways:
  * Settings that only exist in code (the hard-coded passwords, the "TLS not set explicitly" findings¹) won't appear.
  * Settings Terraform doesn't model (like `require_secure_transport`) will.
* In **resource-group mode**, subscription-level detections (Defender plan, security contact, custom owner role, activity log) are not created by TerraGoat. A runtime scan may still report them if your subscription is already configured that way.
