# Variables for Azure AI Factory

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "East US"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group (leave empty for auto-generated)"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Project     = "AI-Factory"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

variable "ai_foundry_name" {
  type        = string
  description = "Name for the AI Foundry hub (leave empty for auto-generated)"
  default     = ""
}

variable "container_apps_environment_name" {
  type        = string
  description = "Name for the Container Apps environment (leave empty for auto-generated)"
  default     = ""
}

variable "cosmos_db_name" {
  type        = string
  description = "Name for the Cosmos DB account (leave empty for auto-generated)"
  default     = ""
}

variable "ai_search_name" {
  type        = string
  description = "Name for the AI Search service (leave empty for auto-generated)"
  default     = ""
}

variable "key_vault_name" {
  type        = string
  description = "Name for the Key Vault (leave empty for auto-generated)"
  default     = ""
}

variable "storage_account_name" {
  type        = string
  description = "Name for the storage account (leave empty for auto-generated)"
  default     = ""
}

variable "enable_private_endpoints" {
  type        = bool
  description = "Enable private endpoints for all services"
  default     = true
}

variable "cosmos_db_throughput" {
  type        = number
  description = "Cosmos DB throughput (minimum 3000 RU/s for AI Foundry Agent Service)"
  default     = 3000

  validation {
    condition     = var.cosmos_db_throughput >= 3000
    error_message = "Cosmos DB throughput must be at least 3000 RU/s for AI Foundry Agent Service."
  }
}

variable "ai_search_sku" {
  type        = string
  description = "AI Search service SKU"
  default     = "standard"

  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3"], var.ai_search_sku)
    error_message = "AI Search SKU must be one of: free, basic, standard, standard2, standard3."
  }
}

variable "admin_email" {
  type        = string
  description = "Admin email for monitoring alerts"
  default     = ""
}