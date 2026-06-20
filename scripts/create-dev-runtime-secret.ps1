param(
    [string] $Namespace = "kairoai",
    [string] $SecretName = "kairoai-runtime-secrets",
    [string] $ResourceGroup = "rg-kairoai-dev",
    [string] $ServiceBusNamespace = "sb-kairoai-dev",
    [string] $ServiceBusQueue = "review-analysis",
    [string] $ServiceBusAuthRule = "kairoai-review-dispatch"
)

$ErrorActionPreference = "Stop"

function Get-RequiredEnv {
    param([string] $Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Required environment variable $Name is not set."
    }
    return $value
}

function Get-OptionalEnv {
    param(
        [string] $Name,
        [string] $Default = ""
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value
}

$serviceBusConnectionString = Get-OptionalEnv "SERVICE_BUS_CONNECTION_STRING"
if ([string]::IsNullOrWhiteSpace($serviceBusConnectionString)) {
    $serviceBusConnectionString = az servicebus queue authorization-rule keys list `
        --resource-group $ResourceGroup `
        --namespace-name $ServiceBusNamespace `
        --queue-name $ServiceBusQueue `
        --name $ServiceBusAuthRule `
        --query primaryConnectionString `
        --output tsv
}
if ([string]::IsNullOrWhiteSpace($serviceBusConnectionString)) {
    throw "Could not resolve SERVICE_BUS_CONNECTION_STRING from env or Azure."
}

$githubPrivateKey = Get-OptionalEnv "GITHUB_APP_PRIVATE_KEY"
$githubPrivateKeyPath = Get-OptionalEnv "GITHUB_APP_PRIVATE_KEY_PATH"
if ([string]::IsNullOrWhiteSpace($githubPrivateKey) -and -not [string]::IsNullOrWhiteSpace($githubPrivateKeyPath)) {
    $githubPrivateKey = Get-Content -Raw -Path $githubPrivateKeyPath
}
if ([string]::IsNullOrWhiteSpace($githubPrivateKey)) {
    throw "Set GITHUB_APP_PRIVATE_KEY or GITHUB_APP_PRIVATE_KEY_PATH before creating the secret."
}

kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

$tempKeyFile = New-TemporaryFile
try {
    Set-Content -Path $tempKeyFile.FullName -Value $githubPrivateKey -NoNewline

    kubectl create secret generic $SecretName `
        --namespace $Namespace `
        --from-literal=github-webhook-secret="$(Get-RequiredEnv 'GITHUB_WEBHOOK_SECRET')" `
        --from-literal=github-app-id="$(Get-RequiredEnv 'GITHUB_APP_ID')" `
        --from-file=github-app-private-key="$($tempKeyFile.FullName)" `
        --from-literal=database-url="$(Get-RequiredEnv 'DATABASE_URL')" `
        --from-literal=service-bus-connection-string="$serviceBusConnectionString" `
        --from-literal=azure-ai-foundry-endpoint="$(Get-OptionalEnv 'AZURE_AI_FOUNDRY_ENDPOINT')" `
        --from-literal=azure-ai-foundry-api-key="$(Get-OptionalEnv 'AZURE_AI_FOUNDRY_API_KEY')" `
        --from-literal=azure-ai-foundry-deployment="$(Get-OptionalEnv 'AZURE_AI_FOUNDRY_DEPLOYMENT')" `
        --from-literal=azure-ai-foundry-api-version="$(Get-OptionalEnv 'AZURE_AI_FOUNDRY_API_VERSION')" `
        --from-literal=github-app-client-id="$(Get-OptionalEnv 'GITHUB_APP_CLIENT_ID')" `
        --from-literal=github-app-client-secret="$(Get-OptionalEnv 'GITHUB_APP_CLIENT_SECRET')" `
        --from-literal=dashboard-auth-secret="$(Get-OptionalEnv 'DASHBOARD_AUTH_SECRET')" `
        --dry-run=client `
        -o yaml | kubectl apply -f -
}
finally {
    Remove-Item -Force -Path $tempKeyFile.FullName
}

Write-Output "Created or updated Kubernetes secret $SecretName in namespace $Namespace."
