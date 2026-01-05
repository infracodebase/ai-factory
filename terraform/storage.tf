# Storage Account for AI Factory

# User-assigned identity for storage account Key Vault access
resource "azurerm_user_assigned_identity" "storage" {
  name                = "id-storage-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name != "" ? var.storage_account_name : "staifactory${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant storage for high availability
  account_kind             = "StorageV2"

  # Enhanced security settings
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false # Disable public access completely

  # Customer-managed key encryption
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.storage_encryption.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
  }

  # Managed identity for Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage.id]
  }

  # Enable blob storage logging and security features
  blob_properties {
    delete_retention_policy {
      days = 7
    }

    versioning_enabled  = true
    change_feed_enabled = true
  }

  # Enable queue service logging (inline for checkov compliance)
  queue_properties {
    logging {
      version               = "1.0"
      delete                = true
      read                  = true
      write                 = true
      retention_policy_days = 7
    }
  }

  # Network access
  network_rules {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = ["AzureServices"]

    # Allow access from Container Apps subnet
    virtual_network_subnet_ids = var.enable_private_endpoints ? [azurerm_subnet.container_apps.id] : []
  }

  tags = var.tags
}

# Advanced Threat Protection for Storage Account
resource "azurerm_security_center_storage_defender" "this" {
  storage_account_id = azurerm_storage_account.this.id
}

# Blob container for AI models and artifacts
resource "azurerm_storage_container" "ai_models" {
  name                  = "ai-models"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Blob container for agent data
resource "azurerm_storage_container" "agent_data" {
  name                  = "agent-data"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# File share for shared storage
resource "azurerm_storage_share" "shared" {
  name                 = "shared-storage"
  storage_account_name = azurerm_storage_account.this.name
  quota                = 100
}

# Private endpoint for Storage Account (if enabled)
resource "azurerm_private_endpoint" "storage" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-st-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-st-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-st-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-st-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.storage[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Store storage connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_connection_string" {
  name            = "storage-connection-string"
  value           = azurerm_storage_account.this.primary_connection_string
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}
# Queue service properties moved inline to storage account for checkov compliance
