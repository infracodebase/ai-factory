# Azure AI Search for intelligent search capabilities

resource "azurerm_search_service" "this" {
  name                = var.ai_search_name != "" ? var.ai_search_name : "search-ai-factory-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.ai_search_sku
  replica_count       = var.ai_search_sku == "free" ? 1 : 3 # At least 3 replicas for 99.9% SLA
  partition_count     = var.ai_search_sku == "free" ? 1 : 3 # At least 3 partitions for 99.9% SLA

  # Enable semantic search for advanced AI capabilities
  semantic_search_sku = var.ai_search_sku == "free" ? null : "standard"

  # Network configuration
  public_network_access_enabled = false
  local_authentication_enabled  = false

  # Managed identity for secure access to other services
  identity {
    type = "SystemAssigned"
  }

  # No allowed IPs when using private endpoints
  allowed_ips = []

  tags = var.tags
}

# Private endpoint for AI Search (if enabled)
resource "azurerm_private_endpoint" "search" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-search-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-search-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-search-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.search[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for AI Search
resource "azurerm_private_dns_zone" "search" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-search-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Store AI Search admin key in Key Vault
resource "azurerm_key_vault_secret" "search_admin_key" {
  name            = "search-admin-key"
  value           = azurerm_search_service.this.primary_key
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}

# Store AI Search query key in Key Vault
resource "azurerm_key_vault_secret" "search_query_key" {
  name            = "search-query-key"
  value           = azurerm_search_service.this.query_keys[0].key
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}

# Store AI Search endpoint in Key Vault
resource "azurerm_key_vault_secret" "search_endpoint" {
  name            = "search-endpoint"
  value           = "https://${azurerm_search_service.this.name}.search.windows.net"
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}