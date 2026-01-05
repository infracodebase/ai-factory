# Enhanced Monitoring and Alerting for AI Factory

# Action Group for alerts
resource "azurerm_monitor_action_group" "ai_factory" {
  name                = "ag-ai-factory-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "aifactory"

  email_receiver {
    name                    = "admin"
    email_address           = var.admin_email != "" ? var.admin_email : "admin@example.com"
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Alert for high Container App CPU usage
resource "azurerm_monitor_metric_alert" "container_app_cpu" {
  name                = "alert-container-app-cpu-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_container_app.agent_api.id]
  description         = "Alert when Container App CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "UsagePercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ai_factory.id
  }

  frequency   = "PT5M"
  window_size = "PT15M"

  tags = var.tags
}

# Alert for Cosmos DB high RU consumption
resource "azurerm_monitor_metric_alert" "cosmos_ru_usage" {
  name                = "alert-cosmos-ru-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_cosmosdb_account.this.id]
  description         = "Alert when Cosmos DB RU consumption is high"

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 2500
  }

  action {
    action_group_id = azurerm_monitor_action_group.ai_factory.id
  }

  frequency   = "PT5M"
  window_size = "PT15M"

  tags = var.tags
}

# Alert for AI Search query rate
resource "azurerm_monitor_metric_alert" "search_queries" {
  name                = "alert-search-queries-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_search_service.this.id]
  description         = "Alert when AI Search query rate is high"

  criteria {
    metric_namespace = "Microsoft.Search/searchServices"
    metric_name      = "SearchQueriesPerSecond"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 50
  }

  action {
    action_group_id = azurerm_monitor_action_group.ai_factory.id
  }

  frequency   = "PT5M"
  window_size = "PT15M"

  tags = var.tags
}

# Diagnostic settings for Container Apps Environment
resource "azurerm_monitor_diagnostic_setting" "container_apps_env" {
  name               = "diag-container-apps-env"
  target_resource_id = azurerm_container_app_environment.this.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Cosmos DB
resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name               = "diag-cosmos"
  target_resource_id = azurerm_cosmosdb_account.this.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "MongoRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_metric {
    category = "Requests"
  }
}

# Diagnostic settings for AI Search
resource "azurerm_monitor_diagnostic_setting" "search" {
  name               = "diag-search"
  target_resource_id = azurerm_search_service.this.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "OperationLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name               = "diag-key-vault"
  target_resource_id = azurerm_key_vault.this.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name               = "diag-storage"
  target_resource_id = azurerm_storage_account.this.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}

# Diagnostic settings for Storage Blob service
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name               = "diag-storage-blob"
  target_resource_id = "${azurerm_storage_account.this.id}/blobServices/default"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}

# Additional diagnostic settings for blob containers (checkov compliance)
resource "azurerm_monitor_diagnostic_setting" "blob_ai_models" {
  name               = "diag-blob-ai-models"
  target_resource_id = "${azurerm_storage_account.this.id}/blobServices/default/containers/ai-models"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  depends_on = [azurerm_storage_container.ai_models]
}

resource "azurerm_monitor_diagnostic_setting" "blob_agent_data" {
  name               = "diag-blob-agent-data"
  target_resource_id = "${azurerm_storage_account.this.id}/blobServices/default/containers/agent-data"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  depends_on = [azurerm_storage_container.agent_data]
}
