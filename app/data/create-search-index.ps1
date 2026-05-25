# create-search-index.ps1
# Creates the AI Search index for Nordlux product catalog RAG

$searchName = 'nx-prod-ai-swc-srch-001'
$indexName = 'nordlux-catalog'
$apiVersion = '2024-05-01-preview'

$token = (Get-AzAccessToken -ResourceUrl 'https://search.azure.com').Token
$headers = @{
  'Authorization' = "Bearer $token"
  'Content-Type'  = 'application/json'
}

$indexBody = @{
  name = $indexName
  fields = @(
    @{ name = 'id'; type = 'Edm.String'; key = $true; searchable = $false }
    @{ name = 'content'; type = 'Edm.String'; searchable = $true; analyzer = 'en.microsoft' }
    @{ name = 'category'; type = 'Edm.String'; searchable = $true; filterable = $true }
    @{ name = 'productCode'; type = 'Edm.String'; searchable = $true; filterable = $true }
    @{ name = 'price'; type = 'Edm.Double'; filterable = $true; sortable = $true }
    @{ name = 'embedding'; type = 'Collection(Edm.Single)';
       dimensions = 1536; vectorSearchProfile = 'vector-profile' }
  )
  vectorSearch = @{
    profiles = @(@{ name = 'vector-profile'; algorithm = 'hnsw-config' })
    algorithms = @(@{ name = 'hnsw-config'; kind = 'hnsw' })
  }
  semanticSearch = @{
    configurations = @(@{
      name = 'semantic-config'
      prioritizedFields = @{
        contentFields = @(@{ fieldName = 'content' })
      }
    })
  }
} | ConvertTo-Json -Depth 10

$uri = "https://$searchName.search.windows.net/indexes/$indexName`?api-version=$apiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $indexBody
Write-Host "Index '$indexName' created successfully."
