#!/usr/bin/env bash
# Source this from a dedicated local-development shell:
#   source tools/floci/env.sh
# It deliberately points every AWS SDK/CLI/Terraform request at local Floci.

export AWS_ACCESS_KEY_ID="${FLOCI_AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${FLOCI_AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${FLOCI_AWS_REGION:-us-east-2}"
export AWS_REGION="${FLOCI_AWS_REGION:-us-east-2}"
export FLOCI_DEFAULT_REGION="${FLOCI_AWS_REGION:-us-east-2}"
export FLOCI_DEFAULT_AVAILABILITY_ZONE="${FLOCI_AWS_AVAILABILITY_ZONE:-us-east-2a}"
export AWS_ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"
export AWS_EC2_METADATA_DISABLED=true
unset AWS_SESSION_TOKEN
