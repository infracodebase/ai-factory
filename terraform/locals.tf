# Local values for common calculations and references

locals {
  # Common naming conventions
  name_suffix = random_string.suffix.result

  # Resource names with fallbacks
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-ai-factory-${local.name_suffix}"

  # Network configuration
  vnet_address_space       = "10.0.0.0/16"
  container_apps_subnet    = "10.0.1.0/24"
  private_endpoints_subnet = "10.0.2.0/24"

  # Common tags merged with var.tags
  common_tags = merge(var.tags, {
    DeployedBy = "Terraform"
    CreatedOn  = timestamp()
  })

  # Service endpoints for private connectivity
  private_dns_zones = var.enable_private_endpoints ? {
    key_vault          = "privatelink.vaultcore.azure.net"
    storage            = "privatelink.blob.core.windows.net"
    cosmos_db          = "privatelink.documents.azure.com"
    ai_search          = "privatelink.search.windows.net"
    cognitive_services = "privatelink.cognitiveservices.azure.com"
    ml_workspace       = "privatelink.api.azureml.ms"
  } : {}
}