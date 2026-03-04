terraform {
  required_version = ">= 1.2.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "5.46.0"
    }
  }
}

data "oci_identity_tenancy" "tenancy_metadata" {
  tenancy_id = var.tenancy_ocid
}

# Fetch list of Availability Domains in the compartment to resolve AD names
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Fetch latest Ubuntu 22.04 image available in the region
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

locals {
  tenancy_home_region = data.oci_identity_tenancy.tenancy_metadata.home_region_key
  first_ad            = data.oci_identity_availability_domains.ads.availability_domains[0].name
  ubuntu_image_id     = data.oci_core_images.ubuntu.images[0].id

  freeform_tags = {
    "managed-by" = "myrmex-integration"
    "purpose"    = "oci-collector"
  }

  startup_script = <<-SCRIPT
    #!/bin/bash

    # Execution log (important for debugging)
    exec > >(tee /var/log/myrmex-install.log)
    exec 2>&1

    echo "=== Starting Myrmex EDR installation ==="
    date

    # Set hostname
    echo "Configuring hostname..."
    hostnamectl set-hostname myrmex-oci-collector-${var.oci_account_name}
    echo "myrmex-oci-collector-${var.oci_account_name}" > /etc/hostname
    sed -i 's/127.0.0.1.*/127.0.0.1   localhost myrmex-oci-collector-${var.oci_account_name}/' /etc/hosts
    echo "Hostname configured to: myrmex-oci-collector-${var.oci_account_name}"

    # Wait for network to be available
    echo "Waiting for connectivity..."
    MAX_RETRIES=30
    RETRY_COUNT=0
    until ping -c1 google.com &>/dev/null || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
        echo "Waiting for network... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "ERROR: Network not available after $MAX_RETRIES attempts"
        exit 1
    fi
    echo "Network available"

    # Verify required tools
    echo "Checking required tools..."
    command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not installed"; exit 1; }
    echo "curl is available"

    # Set environment variables
    echo "Setting environment variables..."
    export MYRMEX_INSTALL_TOKEN="${var.myrmex_token}"
    export MYRMEX_CONTEXT_ID="${var.context_id}"
    echo "Environment variables set"

    # Download installation script with retry
    echo "Downloading installation script from api.myrmex.ai..."
    INSTALL_SCRIPT_URL="https://api.myrmex.ai/v1/devices/scripts/install.sh"
    MAX_DOWNLOAD_RETRIES=3
    DOWNLOAD_RETRY=0

    while [ $DOWNLOAD_RETRY -lt $MAX_DOWNLOAD_RETRIES ]; do
        echo "Download attempt $((DOWNLOAD_RETRY + 1))/$MAX_DOWNLOAD_RETRIES..."

        if curl -sSL -f "$INSTALL_SCRIPT_URL" -o /tmp/myrmex-install.sh; then
            echo "Installation script downloaded successfully"
            break
        else
            echo "Download failed (attempt $((DOWNLOAD_RETRY + 1)))"
            DOWNLOAD_RETRY=$((DOWNLOAD_RETRY + 1))
            if [ $DOWNLOAD_RETRY -lt $MAX_DOWNLOAD_RETRIES ]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    if [ $DOWNLOAD_RETRY -eq $MAX_DOWNLOAD_RETRIES ]; then
        echo "ERROR: Failed to download installation script after $MAX_DOWNLOAD_RETRIES attempts"
        exit 1
    fi

    # Run installation script
    echo "Running installation script..."
    chmod +x /tmp/myrmex-install.sh
    bash /tmp/myrmex-install.sh
    INSTALL_EXIT_CODE=$?

    # Verify installation
    echo "Verifying installation (exit code: $INSTALL_EXIT_CODE)..."
    if [ $INSTALL_EXIT_CODE -eq 0 ]; then
        echo "Installation script completed successfully"

        if systemctl list-unit-files | grep -q myrmex-endpoint; then
            echo "Myrmex service found"
            sleep 5

            if systemctl is-active --quiet myrmex-endpoint; then
                echo "Myrmex endpoint service is running"
                systemctl status myrmex-endpoint --no-pager
            else
                echo "WARNING: Myrmex endpoint service is not running"
                systemctl status myrmex-endpoint --no-pager || true
                journalctl -u myrmex-endpoint -n 50 --no-pager || true
            fi
        else
            echo "WARNING: Myrmex endpoint service not found after installation"
        fi
    else
        echo "ERROR: Installation script failed with exit code: $INSTALL_EXIT_CODE"
        exit 1
    fi

    date
    echo "=== Installation finished ==="
    echo "Log file: /var/log/myrmex-install.log"
  SCRIPT
}

# ─────────────────────────────────────────────
# IAM User
# ─────────────────────────────────────────────
resource "oci_identity_user" "myrmex_user" {
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] IAM user created for Myrmex integration — used to authenticate and manage OCI resources"
  name           = var.user_name
  email          = var.user_email

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# IAM Group
# ─────────────────────────────────────────────
resource "oci_identity_group" "myrmex_group" {
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Group for Myrmex integration user — grants broad management permissions across the tenancy"
  name           = var.user_group_name

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# Group Membership
# ─────────────────────────────────────────────
resource "oci_identity_user_group_membership" "myrmex_membership" {
  depends_on = [oci_identity_user.myrmex_user, oci_identity_group.myrmex_group]

  group_id = oci_identity_group.myrmex_group.id
  user_id  = oci_identity_user.myrmex_user.id
}

# ─────────────────────────────────────────────
# Dynamic Group (allows the instance to call OCI APIs)
# ─────────────────────────────────────────────
resource "oci_identity_dynamic_group" "myrmex_vm_group" {
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Dynamic group for Myrmex agent Compute Instance — allows the VM to authenticate to OCI APIs"
  name           = var.dynamic_group_name
  matching_rule  = "All {instance.compartment.id = '${var.compartment_ocid}'}"

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# IAM Policy (broad management permissions)
# Equivalent to GCP roles assigned in gcp_integration_vm_quickstart.py
# ─────────────────────────────────────────────
resource "oci_identity_policy" "myrmex_policy" {
  depends_on = [
    oci_identity_group.myrmex_group,
    oci_identity_dynamic_group.myrmex_vm_group,
    oci_identity_user_group_membership.myrmex_membership,
  ]

  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Myrmex integration policy — grants permissions for resource discovery and management"
  name           = var.policy_name

  statements = [
    # Compute (equivalent to roles/compute.admin)
    "Allow group Default/${var.user_group_name} to manage instance-family in tenancy",
    # Network Security (equivalent to roles/compute.securityAdmin)
    "Allow group Default/${var.user_group_name} to manage network-security-groups in tenancy",
    # Object & Block Storage (equivalent to roles/storage.admin)
    "Allow group Default/${var.user_group_name} to manage object-family in tenancy",
    "Allow group Default/${var.user_group_name} to manage volume-family in tenancy",
    # IAM (equivalent to roles/iam.securityAdmin)
    "Allow group Default/${var.user_group_name} to manage policies in tenancy",
    "Allow group Default/${var.user_group_name} to manage groups in tenancy",
    "Allow group Default/${var.user_group_name} to manage dynamic-groups in tenancy",
    # Monitoring (equivalent to roles/monitoring.admin)
    "Allow group Default/${var.user_group_name} to manage metrics in tenancy",
    "Allow group Default/${var.user_group_name} to manage alarms in tenancy",
    # Logging (equivalent to roles/logging.admin)
    "Allow group Default/${var.user_group_name} to manage log-groups in tenancy",
    "Allow group Default/${var.user_group_name} to manage log-content in tenancy",
    # Database (equivalent to roles/cloudsql.admin)
    "Allow group Default/${var.user_group_name} to manage database-family in tenancy",
    # OKE / Kubernetes (equivalent to roles/container.admin)
    "Allow group Default/${var.user_group_name} to manage cluster-family in tenancy",
    # Networking (equivalent to roles/compute.networkAdmin)
    "Allow group Default/${var.user_group_name} to manage virtual-network-family in tenancy",
    # General read access (base visibility)
    "Allow group Default/${var.user_group_name} to read all-resources in tenancy",
    "Allow group Default/${var.user_group_name} to read audit-events in tenancy",
    # Allow the VM instance itself to read OCI resources via instance principal
    "Allow dynamic-group Default/${var.dynamic_group_name} to read all-resources in tenancy",
  ]

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# Compute Instance
# Public IP controlled by var.assign_public_ip (default: false)
# ─────────────────────────────────────────────
resource "oci_core_instance" "myrmex_agent" {
  depends_on = [oci_identity_policy.myrmex_policy]

  compartment_id      = var.compartment_ocid
  availability_domain = local.first_ad
  display_name        = var.instance_name
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = local.ubuntu_image_id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = var.assign_public_ip
    display_name     = "${var.instance_name}-vnic"
    hostname_label   = "myrmex-agent"
  }

  metadata = {
    user_data = base64encode(local.startup_script)
  }

  freeform_tags = local.freeform_tags
  defined_tags  = {}
}
