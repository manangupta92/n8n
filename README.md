# n8n with Ollama and OpenAI OSS

This project sets up a local environment for running n8n, with a Cloudflare tunnel to expose the webhook to the internet.

## Prerequisites

*   [Docker](https://www.docker.com/products/docker-desktop) and Docker Compose
*   [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
*   **Cloudflared:** Download `cloudflared.exe` for Windows from [here](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/). Place the `cloudflared.exe` file in the root of this project directory.

## How to Run

1.  **Open a PowerShell terminal.**
2.  **Navigate to the project directory:**
    ```powershell
    cd path\to\n8n-ollama-openai-oss
    ```
3.  **Execute the setup script:**
    ```powershell
    .\start-services.ps1
    ```

## What the Script Does

The `start-services.ps1` script automates the following:

1.  **Starts a Cloudflare Tunnel:** It creates a public URL that forwards to your local n8n instance (running on port 5678).
2.  **Updates Environment File:** It automatically updates the `WEBHOOK_URL` in the `.env` file with the new Cloudflare tunnel URL.
3.  **Restarts Docker Containers:** It stops any existing services and then starts the n8n and other related services in a new terminal window using `docker-compose`.

After running the script, your n8n instance will be running and accessible via the public webhook URL displayed in the terminal.
