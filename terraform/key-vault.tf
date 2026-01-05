# Key Vault for secrets management

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name != "" ? var.key_vault_name : "kv-ai-factory-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  # Enable soft delete and purge protection for production
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # Network access configuration
  network_acls {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = "AzureServices"

    # Allow access from Container Apps subnet
    virtual_network_subnet_ids = var.enable_private_endpoints ? [azurerm_subnet.container_apps.id] : []
  }

  tags = var.tags
}

# Access policy for the current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# Managed Identity for Container Apps to access Key Vault
resource "azurerm_user_assigned_identity" "container_apps" {
  name                = "id-container-apps-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Access policy for Container Apps managed identity
resource "azurerm_key_vault_access_policy" "container_apps" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_user_assigned_identity.container_apps.tenant_id
  object_id    = azurerm_user_assigned_identity.container_apps.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Private endpoint for Key Vault (if enabled)
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-kv-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-kv-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-kv-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Key for Cosmos DB encryption
resource "azurerm_key_vault_key" "cosmos_encryption" {
  name            = "cosmos-encryption-key"
  key_vault_id    = azurerm_key_vault.this.id
  key_type        = "RSA-HSM"
  key_size        = 2048
  expiration_date = timeadd(timestamp(), "17520h") # 2 years from now
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}

# Key for Storage Account encryption
resource "azurerm_key_vault_key" "storage_encryption" {
  name            = "storage-encryption-key"
  key_vault_id    = azurerm_key_vault.this.id
  key_type        = "RSA-HSM"
  key_size        = 2048
  expiration_date = timeadd(timestamp(), "17520h") # 2 years from now
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}
# Access policy for storage account managed identity
resource "azurerm_key_vault_access_policy" "storage_identity" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.storage.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

# Key for Cognitive Services encryption
resource "azurerm_key_vault_key" "cognitive_services_encryption" {
  name            = "cognitive-services-encryption-key"
  key_vault_id    = azurerm_key_vault.this.id
  key_type        = "RSA-HSM"
  key_size        = 2048
  expiration_date = timeadd(timestamp(), "17520h") # 2 years from now
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}

# Access policy for Cognitive Services managed identity
resource "azurerm_key_vault_access_policy" "cognitive_services_identity" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.cognitive_services.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}
