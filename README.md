# hcdd412-w7-iac

HCDD 412 Week 7: provision a cloud resource with Infrastructure as Code (Azure + Bicep) and call a real AI service.

## What the template creates

`main.bicep` deploys three resources into the resource group `rg-hcdd412-w7`:

| Resource | Type | SKU |
|---|---|---|
| `plan-<appName>-<env>` | Linux App Service plan | F1 (Free) |
| `app-<appName>-<env>-<suffix>` | Linux web app (Node 20 LTS): HTTPS only, TLS 1.2, FTP disabled | none (runs on the plan) |
| `lang-<appName>-<env>` | Azure AI Language (TextAnalytics) | F0 (Free) |

`<suffix>` comes from `uniqueString(resourceGroup().id)`. Web app names must be unique across all of Azure, and the suffix stays the same on redeploys, so redeploying is idempotent.

Parameters: `appName` (required), `env` (dev / staging / prod, default dev), `location`, `planSku`, `deployLanguage`, `languageSku`.

The template contains no secrets. The AI Language key is read at runtime into an environment variable and is never committed.

## How to deploy

```powershell
az login
az group create -n rg-hcdd412-w7 -l eastus
az bicep build --file main.bicep
az deployment group what-if -g rg-hcdd412-w7 -f main.bicep -p appName=<jpy5426>
az deployment group create  -g rg-hcdd412-w7 -f main.bicep -p appName=<jpy5426> -n w7
```

Clean up: `az group delete -n rg-hcdd412-w7 --yes`

## AI Service Proof of Concept

A sentiment-analysis call to Azure AI Language (API version 2023-04-01), with the key held in `$env:LANG_KEY`:

```powershell
$env:LANG_KEY = az cognitiveservices account keys list -g rg-hcdd412-w7 -n lang-<yourid>-dev --query key1 -o tsv
Invoke-RestMethod -Method Post -Uri "$env:LANG_ENDPOINT/language/:analyze-text?api-version=2023-04-01" `
  -Headers @{ "Ocp-Apim-Subscription-Key" = $env:LANG_KEY } -ContentType "application/json" -Body $body
```

Real response:

```json
{
  "kind": "SentimentAnalysisResults",
  "results": {
    "documents": [
      {
        "id": "1",
        "sentiment": "positive",
        "confidenceScores": { "positive": 1.0, "neutral": 0.0, "negative": 0.0 },
        "sentences": [
          {
            "sentiment": "positive",
            "confidenceScores": { "positive": 1.0, "neutral": 0.0, "negative": 0.0 },
            "offset": 0,
            "length": 57,
            "text": "The deployment finished cleanly and the team is thrilled."
          }
        ],
        "warnings": []
      }
    ],
    "errors": [],
    "modelVersion": "2025-01-01"
  }
}
```

**Where it fits:** In our resume analyzer, this managed AI service sits behind the Week 6 inference boundary. The backend sends text to it server-side, so the key is never exposed to the browser.

## AI usage disclosure

GitHub Copilot Chat generated the first draft of the Bicep template. I fixed the issues (outdated API versions, a B1 SKU instead of the free F1, a web app name that wasn't unique, missing TLS/FTP settings).