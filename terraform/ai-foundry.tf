# Azure AI Foundry Hub and Project for agent development

# User-assigned identity for Cognitive Services Key Vault access
resource "azurerm_user_assigned_identity" "cognitive_services" {
  name                = "id-cognitive-services-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Cognitive Services Multi-Service Account for AI Foundry
resource "azurerm_cognitive_account" "this" {
  name                  = "cog-ai-factory-${random_string.suffix.result}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = "cog-ai-factory-${random_string.suffix.result}"

  # Disable public network access for enhanced security
  public_network_access_enabled = false
  local_auth_enabled            = false

  # Customer-managed key encryption
  customer_managed_key {
    key_vault_key_id   = azurerm_key_vault_key.cognitive_services_encryption.id
    identity_client_id = azurerm_user_assigned_identity.cognitive_services.client_id
  }

  # Encryption is handled via customer_managed_key block above

  # Network access configuration
  network_acls {
    default_action = "Deny"

    virtual_network_rules {
      subnet_id                            = azurerm_subnet.container_apps.id
      ignore_missing_vnet_service_endpoint = false
    }
  }

  # Managed identity for secure access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cognitive_services.id]
  }

  tags = var.tags
}

# Machine Learning Workspace (required for AI Foundry Hub)
resource "azurerm_machine_learning_workspace" "this" {
  name                    = var.ai_foundry_name != "" ? var.ai_foundry_name : "ml-ai-factory-${random_string.suffix.result}"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  storage_account_id      = azurerm_storage_account.this.id
  key_vault_id            = azurerm_key_vault.this.id
  application_insights_id = azurerm_application_insights.this.id

  # Managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  public_network_access_enabled = var.enable_private_endpoints ? false : true

  tags = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]
}

# AI Foundry Hub configuration (using ML Workspace as base)
resource "azurerm_machine_learning_compute_cluster" "agents" {
  name                          = "agents-cluster"
  location                      = azurerm_resource_group.this.location
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.this.id
  subnet_resource_id            = azurerm_subnet.container_apps.id
  local_auth_enabled            = false

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT30S"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Private endpoint for Cognitive Services (if enabled)
resource "azurerm_private_endpoint" "cognitive" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-cog-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-cog-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-cog-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cognitive[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for Cognitive Services
resource "azurerm_private_dns_zone" "cognitive" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "cognitive" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-cog-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Private endpoint for ML Workspace (if enabled)
resource "azurerm_private_endpoint" "ml_workspace" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-ml-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-ml-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_machine_learning_workspace.this.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-ml-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.ml_workspace[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for ML Workspace
resource "azurerm_private_dns_zone" "ml_workspace" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "ml_workspace" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-ml-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.ml_workspace[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Store AI Services key in Key Vault
resource "azurerm_key_vault_secret" "ai_services_key" {
  name            = "ai-services-key"
  value           = azurerm_cognitive_account.this.primary_access_key
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}

# Store AI Services endpoint in Key Vault
resource "azurerm_key_vault_secret" "ai_services_endpoint" {
  name            = "ai-services-endpoint"
  value           = azurerm_cognitive_account.this.endpoint
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}