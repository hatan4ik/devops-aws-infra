aws_region            = "us-east-2"
aws_account_id        = "448871779014"
environment           = "dev"
log_retention_in_days = 365

# Add a reviewed immutable image-digest service map only after the application
# image, task contract, secret ARNs, and (if needed) HTTPS OAuth URLs are approved.
applications = {}
