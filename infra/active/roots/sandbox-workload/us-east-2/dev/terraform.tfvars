aws_region            = "us-east-2"
aws_account_id        = "448871779014"
environment           = "dev"
log_retention_in_days = 365

applications = {
  "auth-demo" = {
    image_digest         = "448871779014.dkr.ecr.us-east-2.amazonaws.com/sandbox-platform-dev-application@sha256:7237ac7b52235a281d32a2d327016cd8387547c2572bbf962c286536bf38a13d"
    cpu                  = 512
    memory               = 1024
    desired_count        = 2
    force_new_deployment = true
    autoscaling = {
      min_capacity       = 2
      max_capacity       = 12
      cpu_target_percent = 60
    }
    container_port = 8080
    environment = {
      PORT = "8080"
    }
    health_check = {
      command      = ["CMD-SHELL", "node -e \"fetch('http://127.0.0.1:8080/healthz').then((response) => process.exit(response.ok ? 0 : 1)).catch(() => process.exit(1))\""]
      interval     = 30
      timeout      = 5
      retries      = 3
      start_period = 15
    }
    cognito = {
      callback_urls        = ["https://localhost:3000/auth/callback"]
      logout_urls          = ["https://localhost:3000/auth/logout"]
      allowed_oauth_scopes = ["openid", "email"]
    }
    tags = {
      Application = "sandbox-auth-demo"
      Owner       = "hatan4ik"
      Source      = "hatan4ik/sandbox-auth-demo@731e18339b14ee1593c9c9eab4c5e001800ba700"
    }
  }
}
