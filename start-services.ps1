# Set working directory to the script's location for robust path handling
$scriptDir = $PSScriptRoot
Set-Location $scriptDir

# Function to gracefully stop any existing cloudflared processes
function Stop-CloudflaredProcess {
    $processes = Get-Process cloudflared -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Stopping existing cloudflared process(es)..."
        $processes | Stop-Process -Force
    }
}

# --- Main Execution ---

# 1. Clean up previous runs
Stop-CloudflaredProcess
$logFile = "cloudflared.log"
if (Test-Path $logFile) {
    Remove-Item $logFile
}

# 2. Start the Cloudflare Tunnel
Write-Host "Starting Cloudflare tunnel for http://localhost:5678..."
$process = Start-Process -FilePath ".\cloudflared.exe" `
    -ArgumentList "tunnel --url http://localhost:5678" `
    -RedirectStandardError $logFile `
    -PassThru -NoNewWindow

# 3. Wait for the tunnel URL to be generated
Write-Host "Waiting for tunnel URL..."
$tunnelUrl = $null
$maxAttempts = 15
$attempts = 0

while (-not $tunnelUrl -and $attempts -lt $maxAttempts) {
    $attempts++
    Start-Sleep -Seconds 2
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile -Raw
        if ($logContent -match '(https?://[a-zA-Z0-9-]+\.trycloudflare\.com)') {
            $tunnelUrl = $matches[0]
            Write-Host "Successfully found tunnel URL: $tunnelUrl"
        }
    }
    Write-Host "Attempt $($attempts): Still waiting for URL..."
}

# 4. Update .env file and restart Docker if URL was found
if ($tunnelUrl) {
    # Update .env file
    $envPath = ".\.env"
    if (Test-Path $envPath) {
        $envContent = Get-Content $envPath -Raw
        $newEnvContent = $envContent -replace '^(WEBHOOK_URL=).*', "WEBHOOK_URL=$tunnelUrl"
        Set-Content -Path $envPath -Value $newEnvContent
        Write-Host ".env file has been updated."
    } else {
        Write-Host "WEBHOOK_URL=$tunnelUrl" | Set-Content -Path $envPath
        Write-Host ".env file created and updated."
    }

    # Restart Docker containers in a new terminal
    Write-Host "Restarting Docker containers in a new terminal..."
    Start-Process powershell -ArgumentList "-Command", "docker-compose down; docker-compose up -d"
    
    Write-Host "Setup complete. The tunnel is running in this window."
} else {
    Write-Error "Failed to obtain tunnel URL after $maxAttempts attempts. Please check '$logFile' for errors."
    Stop-CloudflaredProcess
}

# Keep the script running to maintain the tunnel
Write-Host "Press Ctrl+C to stop the tunnel."
$process.WaitForExit()

# Final cleanup
Stop-CloudflaredProcess
if (Test-Path $logFile) {
    Remove-Item $logFile
}
