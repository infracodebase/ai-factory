# Outputs for Azure AI Factory

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.this.location
}

output "ai_foundry_workspace_name" {
  description = "Name of the AI Foundry workspace (ML Workspace)"
  value       = azurerm_machine_learning_workspace.this.name
}

output "ai_foundry_workspace_id" {
  description = "ID of the AI Foundry workspace"
  value       = azurerm_machine_learning_workspace.this.id
}

output "container_apps_environment_name" {
  description = "Name of the Container Apps environment"
  value       = azurerm_container_app_environment.this.name
}

output "agent_api_url" {
  description = "URL of the Agent API"
  value       = var.enable_private_endpoints ? "Private endpoint enabled - access via VNet" : "https://${azurerm_container_app.agent_api.ingress[0].fqdn}"
}

output "agent_ui_url" {
  description = "URL of the Agent UI"
  value       = var.enable_private_endpoints ? "Private endpoint enabled - access via VNet" : "https://${azurerm_container_app.agent_ui.ingress[0].fqdn}"
}

output "cosmos_db_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.name
}

output "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "ai_search_name" {
  description = "Name of the AI Search service"
  value       = azurerm_search_service.this.name
}

output "ai_search_endpoint" {
  description = "Endpoint of the AI Search service"
  value       = "https://${azurerm_search_service.this.name}.search.windows.net"
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "ai_services_name" {
  description = "Name of the AI Services account"
  value       = azurerm_cognitive_account.this.name
}

output "ai_services_endpoint" {
  description = "Endpoint of the AI Services account"
  value       = azurerm_cognitive_account.this.endpoint
}

output "container_apps_managed_identity_id" {
  description = "ID of the managed identity for Container Apps"
  value       = azurerm_user_assigned_identity.container_apps.id
}

output "container_apps_managed_identity_client_id" {
  description = "Client ID of the managed identity for Container Apps"
  value       = azurerm_user_assigned_identity.container_apps.client_id
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "container_apps_subnet_id" {
  description = "ID of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.id
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "ai_foundry_managed_identity_id" {
  description = "ID of the AI Foundry managed identity"
  value       = azurerm_user_assigned_identity.ai_foundry.id
}

output "monitoring_action_group_id" {
  description = "ID of the monitoring action group"
  value       = azurerm_monitor_action_group.ai_factory.id
}

output "deployment_summary" {
  description = "Summary of the AI Factory deployment"
  value = {
    resource_group       = azurerm_resource_group.this.name
    location             = azurerm_resource_group.this.location
    ai_foundry_workspace = azurerm_machine_learning_workspace.this.name
    container_apps_env   = azurerm_container_app_environment.this.name
    cosmos_db            = azurerm_cosmosdb_account.this.name
    ai_search            = azurerm_search_service.this.name
    key_vault            = azurerm_key_vault.this.name
    storage_account      = azurerm_storage_account.this.name
    ai_services          = azurerm_cognitive_account.this.name
    private_endpoints    = var.enable_private_endpoints
    agent_api_endpoint   = var.enable_private_endpoints ? "Private" : azurerm_container_app.agent_api.ingress[0].fqdn
    agent_ui_endpoint    = var.enable_private_endpoints ? "Private" : azurerm_container_app.agent_ui.ingress[0].fqdn
    monitoring_enabled   = true
  }
}