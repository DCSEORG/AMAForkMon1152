![Header image](https://github.com/DougChisholm/App-Mod-Assist/blob/main/repo-header.png)

# App-Mod-Assist - Expense Management System
A project to show how GitHub coding agent can turn screenshots of legacy apps into working proof-of-concepts for cloud native Azure replacements if the legacy database schema is also provided

This modernized application includes AI-powered features through Azure OpenAI and Cognitive Services.

WARNING: COLLABORATORS MUST FORK THE REPO AGAIN EVERY TIME THEY RUN THE CODING AGENT TO TEST IT TO NOT POLLUTE THIS BASE TEMPLATE (< DELETE WHEN HAVE WAY OF WORKING)

## Quick Start

1. Fork this repo then open the coding agent and use app-mod-assist agent telling it "modernise my app" - making sure to replace the screenshots and sql schema first
2. Clone repo when code is generated locally and open VS Code
3. In terminal AZ LOGIN > Set a subscription context
4. Deploy the GenAI infrastructure:
   ```bash
   ./deploy-genai.sh
   ```
5. (Optional) Run additional deployment scripts as they become available

## Features

### AI-Powered Capabilities
- **Intelligent Chat Interface**: GPT-4o powered assistant for expense queries
- **Receipt Analysis**: Automated receipt data extraction
- **Expense Insights**: AI-driven analytics and spending patterns
- **Policy Compliance**: Automated validation

### Infrastructure
- Azure OpenAI Service (GPT-4o model in Sweden Central)
- Cognitive Services for vision and text analytics
- Managed Identity authentication (keyless, secure)
- Cost-optimized S0 SKUs

## Documentation

- [GenAI Infrastructure Guide](docs/GenAI-Infrastructure.md) - Comprehensive documentation for AI resources
- [Infrastructure README](infra/README.md) - Bicep template details
- [Database Schema](Database-Schema/database_schema.sql) - SQL Server schema for expense management

## Project Structure

```
.
├── config/                      # Configuration files
│   ├── GenAISettings.json      # GenAI service configuration
│   └── GenAISettings.schema.json
├── Database-Schema/             # Database schema and sample data
│   └── database_schema.sql
├── docs/                        # Documentation
│   └── GenAI-Infrastructure.md
├── infra/                       # Infrastructure as Code (Bicep)
│   ├── main.bicep              # Main orchestration template
│   ├── genai.bicep             # GenAI resources
│   └── README.md
├── deploy-genai.sh             # GenAI deployment script
└── README.md                   # This file
```

## Requirements

- Azure CLI
- Azure subscription with permissions to create Cognitive Services
- jq (for deployment script)

## License

See [LICENSE](LICENSE) file for details.
