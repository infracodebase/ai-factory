# Cosmos DB for agent state and conversation history

resource "azurerm_cosmosdb_account" "this" {
  name                = var.cosmos_db_name != "" ? var.cosmos_db_name : "cosmos-ai-factory-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Enable automatic failover for high availability
  automatic_failover_enabled = true

  # Disable privileged escalation by restricting management plane changes
  access_key_metadata_writes_enabled = false
  local_authentication_disabled      = true

  # Consistency level for AI agents
  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  # Primary region
  geo_location {
    location          = azurerm_resource_group.this.location
    failover_priority = 0
    zone_redundant    = false
  }

  # Network access configuration
  is_virtual_network_filter_enabled = var.enable_private_endpoints
  public_network_access_enabled     = var.enable_private_endpoints ? false : true
  ip_range_filter                   = var.enable_private_endpoints ? [] : ["0.0.0.0/0"]

  dynamic "virtual_network_rule" {
    for_each = var.enable_private_endpoints ? [1] : []
    content {
      id                                   = azurerm_subnet.container_apps.id
      ignore_missing_vnet_service_endpoint = false
    }
  }

  # Customer-managed key encryption
  key_vault_key_id = azurerm_key_vault_key.cosmos_encryption.id

  # Backup configuration
  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Local"
  }

  tags = var.tags
}

# Enterprise Memory Database for AI Foundry Agent Service
resource "azurerm_cosmosdb_sql_database" "enterprise_memory" {
  name                = "enterprise_memory"
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = var.cosmos_db_throughput
}

# Container for thread messages
resource "azurerm_cosmosdb_sql_container" "thread_message_store" {
  name                  = "thread-message-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/threadId"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Container for system thread messages
resource "azurerm_cosmosdb_sql_container" "system_thread_message_store" {
  name                  = "system-thread-message-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/systemThreadId"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Container for agent entity store
resource "azurerm_cosmosdb_sql_container" "agent_entity_store" {
  name                  = "agent-entity-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/agentId"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Additional database for application data
resource "azurerm_cosmosdb_sql_database" "app_data" {
  name                = "app-data"
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = 400
}

# Container for use case data
resource "azurerm_cosmosdb_sql_container" "use_cases" {
  name                  = "use-cases"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.app_data.name
  partition_key_paths   = ["/useCaseId"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Private endpoint for Cosmos DB (if enabled)
resource "azurerm_private_endpoint" "cosmos" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-cosmos-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-cosmos-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-cosmos-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos[0].id]
  }

  tags = var.tags
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdns-link-cosmos-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name            = "cosmos-connection-string"
  value           = azurerm_cosmosdb_account.this.primary_sql_connection_string
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = var.tags
}