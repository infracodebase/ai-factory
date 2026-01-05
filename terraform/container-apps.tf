# Azure Container Apps for agent UI and API

# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                           = var.container_apps_environment_name != "" ? var.container_apps_environment_name : "cae-ai-factory-${random_string.suffix.result}"
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = var.enable_private_endpoints

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = var.tags
}

# Container App for Agent API
resource "azurerm_container_app" "agent_api" {
  name                         = "ca-agent-api-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  template {
    min_replicas = 1
    max_replicas = 10

    container {
      name   = "agent-api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container_apps.client_id
      }

      env {
        name        = "COSMOS_CONNECTION_STRING"
        secret_name = "cosmos-connection-string"
      }

      env {
        name        = "AI_SERVICES_KEY"
        secret_name = "ai-services-key"
      }

      env {
        name        = "AI_SERVICES_ENDPOINT"
        secret_name = "ai-services-endpoint"
      }

      env {
        name        = "SEARCH_ENDPOINT"
        secret_name = "search-endpoint"
      }

      env {
        name        = "SEARCH_KEY"
        secret_name = "search-query-key"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    }
  }

  ingress {
    external_enabled = !var.enable_private_endpoints
    target_port      = 80
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name                = "cosmos-connection-string"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.cosmos_connection_string.versionless_id
  }

  secret {
    name                = "ai-services-key"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.ai_services_key.versionless_id
  }

  secret {
    name                = "ai-services-endpoint"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.ai_services_endpoint.versionless_id
  }

  secret {
    name                = "search-endpoint"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.search_endpoint.versionless_id
  }

  secret {
    name                = "search-query-key"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.search_query_key.versionless_id
  }

  tags = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.container_apps
  ]
}

# Container App for Agent UI
resource "azurerm_container_app" "agent_ui" {
  name                         = "ca-agent-ui-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  template {
    min_replicas = 1
    max_replicas = 5

    container {
      name   = "agent-ui"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container_apps.client_id
      }

      env {
        name  = "API_ENDPOINT"
        value = "https://${azurerm_container_app.agent_api.ingress[0].fqdn}"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    }
  }

  ingress {
    external_enabled = !var.enable_private_endpoints
    target_port      = 80
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_container_app.agent_api
  ]
}

# Container App for Background Agent Workers
resource "azurerm_container_app" "agent_workers" {
  name                         = "ca-agent-workers-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  template {
    min_replicas = 0
    max_replicas = 20

    container {
      name   = "agent-workers"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container_apps.client_id
      }

      env {
        name        = "COSMOS_CONNECTION_STRING"
        secret_name = "cosmos-connection-string"
      }

      env {
        name        = "AI_SERVICES_KEY"
        secret_name = "ai-services-key"
      }

      env {
        name        = "AI_SERVICES_ENDPOINT"
        secret_name = "ai-services-endpoint"
      }

      env {
        name        = "SEARCH_ENDPOINT"
        secret_name = "search-endpoint"
      }

      env {
        name        = "SEARCH_KEY"
        secret_name = "search-admin-key"
      }

      env {
        name        = "STORAGE_CONNECTION_STRING"
        secret_name = "storage-connection-string"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    }
  }

  secret {
    name                = "cosmos-connection-string"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.cosmos_connection_string.versionless_id
  }

  secret {
    name                = "ai-services-key"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.ai_services_key.versionless_id
  }

  secret {
    name                = "ai-services-endpoint"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.ai_services_endpoint.versionless_id
  }

  secret {
    name                = "search-endpoint"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.search_endpoint.versionless_id
  }

  secret {
    name                = "search-admin-key"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.search_admin_key.versionless_id
  }

  secret {
    name                = "storage-connection-string"
    identity            = azurerm_user_assigned_identity.container_apps.id
    key_vault_secret_id = azurerm_key_vault_secret.storage_connection_string.versionless_id
  }

  tags = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.container_apps
  ]
}