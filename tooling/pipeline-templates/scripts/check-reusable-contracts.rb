#!/usr/bin/env ruby
# Prevent a pipeline edit from silently widening a credential or release boundary.
require "yaml"

def workflow(path)
  YAML.load_file(File.join(".github/workflows", path))
end

def assert(condition, message)
  abort "FAIL: #{message}" unless condition
end

quality = workflow("terraform-quality.yml")
assert(quality.dig("permissions", "contents") == "read", "quality must keep contents: read")
assert(!quality.fetch("permissions").key?("id-token"), "quality must not request an AWS OIDC token")

plan = workflow("terraform-plan.yml")
assert(plan.dig("permissions", "id-token") == "write", "plan must request OIDC")
assert(plan.dig("permissions", "pull-requests") == "write", "plan must scope PR-comment permission")
assert(plan.dig("jobs", "plan", "concurrency", "cancel-in-progress") == false, "plan must serialize state access")

apply = workflow("terraform-apply.yml")
assert(apply.dig("permissions", "id-token") == "write", "apply must request OIDC")
assert(apply.dig("jobs", "apply", "environment") == "${{ inputs.environment }}", "apply must use its protected environment input")
assert(apply.dig("jobs", "apply", "concurrency", "cancel-in-progress") == false, "apply must serialize state access")

drift = workflow("terraform-drift.yml")
assert(drift.dig("permissions", "id-token") == "write", "drift must request OIDC")
assert(drift.dig("jobs", "drift", "concurrency", "cancel-in-progress") == false, "drift must serialize state access")
drift_step = drift.dig("jobs", "drift", "steps").find { |step| step["name"].include?("Fail loudly") }
assert(drift_step && drift_step["run"].include?("no remediation was performed"), "drift must not contain automatic remediation")

release = workflow("module-release.yml")
assert(release.dig("permissions", "contents") == "write", "module release must have only release content write permission")
assert(release.dig("jobs", "release", "environment") == "module-release", "module release must require its protected environment")
verify_step = release.dig("jobs", "release", "steps").find { |step| step["name"].include?("GitHub-verified annotated tag") }
assert(verify_step && verify_step["run"].include?(".verification.verified"), "module release must verify tag signatures")

puts "PASS: reusable workflow credential, environment, concurrency, and release boundaries are intact"
