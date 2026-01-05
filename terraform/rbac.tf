# Role-Based Access Control (RBAC) for AI Factory

# Get current user data for RBAC assignments
data "azurerm_client_config" "current_user" {}

# Assign Cognitive Services Contributor role to Container Apps managed identity
resource "azurerm_role_assignment" "container_apps_cognitive_contributor" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Assign Cosmos DB Contributor role to Container Apps managed identity
resource "azurerm_role_assignment" "container_apps_cosmos_contributor" {
  scope                = azurerm_cosmosdb_account.this.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Assign Search Service Contributor role to Container Apps managed identity
resource "azurerm_role_assignment" "container_apps_search_contributor" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Assign Storage Blob Data Contributor role to Container Apps managed identity
resource "azurerm_role_assignment" "container_apps_storage_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Assign ML Workspace Contributor role to Container Apps managed identity
resource "azurerm_role_assignment" "container_apps_ml_contributor" {
  scope                = azurerm_machine_learning_workspace.this.id
  role_definition_name = "AzureML Compute Operator"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Assign AI Foundry Hub Owner role to current user
resource "azurerm_role_assignment" "current_user_ai_foundry_owner" {
  scope                = azurerm_machine_learning_workspace.this.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}


# Managed Identity for AI Foundry Hub
resource "azurerm_user_assigned_identity" "ai_foundry" {
  name                = "id-ai-foundry-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Assign Storage Blob Data Contributor role to AI Foundry managed identity
resource "azurerm_role_assignment" "ai_foundry_storage_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_foundry.principal_id
}

# Assign Cosmos DB Contributor role to AI Foundry managed identity
resource "azurerm_role_assignment" "ai_foundry_cosmos_contributor" {
  scope                = azurerm_cosmosdb_account.this.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_foundry.principal_id
}

# Assign AI Search Contributor role to AI Foundry managed identity
resource "azurerm_role_assignment" "ai_foundry_search_contributor" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_foundry.principal_id
}

# Key Vault access policy for AI Foundry managed identity
resource "azurerm_key_vault_access_policy" "ai_foundry" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_user_assigned_identity.ai_foundry.tenant_id
  object_id    = azurerm_user_assigned_identity.ai_foundry.principal_id

  secret_permissions = [
    "Get", "List"
  ]

  certificate_permissions = [
    "Get", "List"
  ]
}