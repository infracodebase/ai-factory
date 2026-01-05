# Azure AI Factory

This Terraform configuration deploys a complete AI Factory architecture on Azure, designed for developing and deploying AI agents and use cases in an isolated, repeatable environment.

## Architecture Overview

The AI Factory includes:

- **Azure AI Foundry Hub** (ML Workspace) - Central hub for AI model development and agent orchestration
- **Azure Container Apps** - Hosting for agent UI, API, and worker services with auto-scaling
- **Azure Cosmos DB** - Storage for agent state, conversation history, and application data
- **Azure AI Search** - Intelligent search capabilities with semantic search
- **Azure Key Vault** - Centralized secrets and configuration management
- **Azure Storage Account** - Blob storage for AI models, artifacts, and shared data
- **Azure Cognitive Services** - Multi-service AI capabilities for foundational AI access
- **Virtual Network** - Private networking with subnets for complete isolation
- **Enhanced Monitoring** - Comprehensive alerting, diagnostics, and observability
- **Enterprise RBAC** - Role-based access control with managed identities

## Key Features

- **Production-Ready Infrastructure** - Enterprise-grade security, monitoring, and RBAC foundation
- **AI Agent Optimized** - Cosmos DB pre-configured for Azure AI Foundry Agent Service
- **Scalable Container Platform** - Auto-scaling web applications and background workers
- **Complete Observability** - Comprehensive monitoring, alerting, and diagnostic logging
- **Portal-Managed AI Workloads** - Users create projects and deploy models through AI Foundry portal
- **Zero-Configuration Security** - Managed identities, private endpoints, Key Vault integration
- **Flexible Development** - Infrastructure foundation supporting multiple AI use cases

## Quick Start

1. **Prerequisites**
   - Azure CLI installed and authenticated
   - Terraform >= 1.0 installed
   - Appropriate Azure permissions (Contributor or Owner)

2. **Deploy the Infrastructure**
   ```bash
   # Initialize Terraform
   terraform init

   # Review the plan
   terraform plan

   # Deploy the resources
   terraform apply
   ```

3. **Configure Your Environment**
   ```bash
   # Create a terraform.tfvars file for customization
   cat > terraform.tfvars << EOF
   location     = "East US"
   environment  = "dev"

   # Optional: Custom resource names
   # ai_foundry_name = "my-ai-factory"
   # cosmos_db_name  = "my-cosmos-db"

   tags = {
     Project     = "AI-Factory"
     Owner       = "YourName"
     Environment = "Development"
   }
   EOF
   ```

## Configuration Options

### Required Variables

No required variables - all have sensible defaults.

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | "East US" |
| `environment` | Environment name | "dev" |
| `enable_private_endpoints` | Enable private networking | `true` |
| `cosmos_db_throughput` | Cosmos DB RU/s (min 3000 for AI Foundry) | 3000 |
| `ai_search_sku` | AI Search service tier | "standard" |

### Custom Resource Names

```hcl
# Override default auto-generated names
ai_foundry_name                = "my-ai-factory-hub"
container_apps_environment_name = "my-container-env"
cosmos_db_name                 = "my-cosmos-db"
ai_search_name                 = "my-ai-search"
key_vault_name                 = "my-key-vault"
storage_account_name           = "mystorageaccount"
```

## Networking

The deployment creates a Virtual Network with two subnets:

- **Container Apps Subnet** (10.0.1.0/24) - For Container Apps with delegation
- **Private Endpoints Subnet** (10.0.2.0/24) - For private endpoint connections

When `enable_private_endpoints = true`:
- All services are accessible only within the VNet
- Private DNS zones are created for service resolution
- External access is disabled for enhanced security

## Container Apps

Three Container Apps are deployed:

1. **Agent API** (`ca-agent-api-*`) - REST API for agent interactions
2. **Agent UI** (`ca-agent-ui-*`) - Web interface for agent management
3. **Agent Workers** (`ca-agent-workers-*`) - Background processing services

All apps have:
- Managed identity for secure access to Azure services
- Key Vault integration for secrets
- Auto-scaling capabilities
- Environment-specific configuration

## Cosmos DB Configuration

The deployment creates a Cosmos DB account optimized for Azure AI Foundry Agent Service:

- **enterprise_memory** database with 3000+ RU/s
  - `thread-message-store` - End-user conversations
  - `system-thread-message-store` - Internal system messages
  - `agent-entity-store` - Model inputs/outputs
- **app-data** database for application-specific data
  - `use-cases` container for use case management

## Security & Access

### Managed Identities

- Container Apps use a User-Assigned Managed Identity
- Key Vault access policies grant secret access to the managed identity
- No secrets stored in environment variables or configuration files

### Key Vault Secrets

The following secrets are automatically stored:

- `cosmos-connection-string` - Cosmos DB connection
- `ai-services-key` - Cognitive Services access key
- `ai-services-endpoint` - Cognitive Services endpoint
- `search-admin-key` / `search-query-key` - AI Search keys
- `search-endpoint` - AI Search endpoint
- `storage-connection-string` - Storage account connection

### Network Security

When private endpoints are enabled:
- All Azure services are isolated to the VNet
- No public internet access to backend services
- Private DNS resolution for service discovery

## Monitoring & Observability

- **Log Analytics Workspace** - Centralized logging
- **Application Insights** - Application performance monitoring
- Container Apps automatically send logs and metrics

## AI Foundry Integration

The ML Workspace serves as the Azure AI Foundry Hub with:

- Compute cluster for agent execution
- Integration with Cosmos DB for agent state storage
- Connection to AI Search for knowledge retrieval
- Access to Cognitive Services for AI capabilities

## Outputs

After deployment, you'll receive:

- Resource names and IDs
- Service endpoints and URLs
- Managed identity information
- Network configuration details

## Advanced Configuration

### Remote State

Uncomment and configure the backend in `terraform.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "sttfstate<unique>"
  container_name       = "tfstate"
  key                  = "ai-factory.terraform.tfstate"
}
```

### Development vs Production

```hcl
# Development environment
enable_private_endpoints = false
cosmos_db_throughput    = 3000
ai_search_sku          = "basic"

# Production environment
enable_private_endpoints = true
cosmos_db_throughput    = 10000
ai_search_sku          = "standard"
```

## Cost Optimization

- Use `ai_search_sku = "basic"` for development
- Set `cosmos_db_throughput = 3000` for minimum viable setup
- Consider serverless Cosmos DB for intermittent workloads
- Use consumption-based Container Apps pricing

## Troubleshooting

### Common Issues

1. **Key Vault Access Denied**
   - Ensure you have appropriate permissions
   - Check access policies are properly configured

2. **Private Endpoint DNS Resolution**
   - Verify private DNS zones are linked to VNet
   - Check network configuration

3. **Container Apps Not Starting**
   - Check managed identity has Key Vault access
   - Verify secrets are properly configured

### Useful Commands

```bash
# Check deployment status
terraform output

# View Container Apps logs
az containerapp logs show --name <app-name> --resource-group <rg-name>

# Test Key Vault access
az keyvault secret list --vault-name <vault-name>
```

## Next Steps

After deployment:

1. **Access Azure AI Foundry Portal** - Navigate to [ai.azure.com](https://ai.azure.com) to access your AI Factory
2. **Create AI Projects** - Use the portal to create isolated development environments for your AI use cases
3. **Deploy AI Models** - Deploy OpenAI models (GPT-4o, embeddings) through the portal with quota management
4. **Develop AI Agents** - Use the AI Foundry Agent Service with automatic Cosmos DB storage integration
5. **Configure Search Indexes** - Set up AI Search indexes for knowledge retrieval through the portal
6. **Customize Container Apps** - Deploy your custom agent UI and API code to the Container Apps environment
7. **Monitor and Scale** - Use the built-in monitoring and alerting to track your AI workloads

## Architecture Philosophy

This infrastructure follows a **foundation-first approach**:

- **Infrastructure as Code** - Terraform manages the underlying Azure services and networking
- **Portal-Managed AI Workloads** - Users manage AI projects, models, and agents through Azure AI Foundry
- **Separation of Concerns** - Infrastructure team manages the platform, AI teams manage the workloads
- **Enterprise Ready** - Built-in security, monitoring, and compliance features

This approach provides the best balance of infrastructure automation while leveraging Azure AI Foundry's managed capabilities for AI-specific operations.

## Contributing

This infrastructure serves as a foundation. Customize the Terraform configurations to match your specific requirements and organizational standards.