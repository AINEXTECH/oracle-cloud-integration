# Oracle Cloud Integration

Houses code for Myrmex's OCI integration. Includes two integration modes and a logging stack.

## Stacks

### 1. `myrmex-oci-orm` — Logging Only
Creates OCI policies for log collection via Service Connector Hub.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/AINEXTECH/oracle-cloud-integration/releases/latest/download/myrmex-oci-orm.zip)

---

### 2. `oci-integration-key` — IAM User + API Key
Creates an IAM user, group and broad management policies so Myrmex can discover and manage OCI resources. No compute instance is created — authentication is done via API Key.

**Resources created:**
- IAM User (`myrmex-integration-user`)
- IAM Group (`MyrmexIntegrationGroup`)
- IAM Policy with management permissions across the tenancy

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/AINEXTECH/oracle-cloud-integration/releases/latest/download/myrmex-oci-integration-key.zip)

> After deploying, generate an API Key for the user in **Identity > Users > myrmex-integration-user > API Keys** and add the credentials to the Myrmex platform.

---

### 3. `oci-integration-vm` — IAM User + VM Agent (Recommended)
Creates the same IAM resources as Mode 2, plus a Compute Instance (Ubuntu 22.04) that automatically installs and runs the Myrmex agent. The VM uses only a private IP — no public IP is assigned.

**Resources created:**
- IAM User, Group, and Policy (same as Mode 2)
- Dynamic Group (allows the VM to authenticate via Instance Principal)
- Compute Instance with Myrmex agent installed via cloud-init

**Requirements:**
- A private subnet with outbound internet access via NAT Gateway (so the agent can reach `api.myrmex.ai`)
- Myrmex installation token and context ID (found in the Myrmex console)

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/AINEXTECH/oracle-cloud-integration/releases/latest/download/myrmex-oci-integration-vm.zip)

---

## Permissions Granted (Modes 2 & 3)

| Category | OCI Policy Statement |
|---|---|
| Compute | `manage instance-family in tenancy` |
| Network Security | `manage network-security-groups in tenancy` |
| Object Storage | `manage object-family in tenancy` |
| Block Storage | `manage volume-family in tenancy` |
| IAM | `manage policies / groups / dynamic-groups in tenancy` |
| Monitoring | `manage metrics / alarms in tenancy` |
| Logging | `manage log-groups / log-content in tenancy` |
| Database | `manage database-family in tenancy` |
| Kubernetes (OKE) | `manage cluster-family in tenancy` |
| Networking | `manage virtual-network-family in tenancy` |
| Read-all | `read all-resources / audit-events in tenancy` |
