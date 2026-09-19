#!/bin/bash
set -e

# Pre-flight IAM Permission Check Script
# This script simulates whether the current caller has permission to execute a provided list of AWS actions.

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <action1> <action2> ..."
    echo "Example: $0 s3:CreateBucket kms:CreateKey ec2:RunInstances"
    exit 1
fi

ACTIONS=("$@")
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo "Running Pre-Flight IAM Check for: $CALLER_ARN"
echo "Checking actions: ${ACTIONS[*]}"

# Run the simulator
RESULT=$(aws iam simulate-principal-policy \
  --policy-source-arn "$CALLER_ARN" \
  --action-names "${ACTIONS[@]}" \
  --output json)

# Parse the results
FAILURES=0

for row in $(echo "${RESULT}" | jq -r '.EvaluationResults[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    ACTION=$(_jq '.EvalActionName')
    DECISION=$(_jq '.EvalDecision')
    ORG_ALLOWED=$(_jq '.OrganizationsDecisionDetail.AllowedByOrganizations')

    if [ "$DECISION" != "allowed" ]; then
        echo "❌ DENIED: $ACTION"
        echo "   Reason: $DECISION"
        if [ "$ORG_ALLOWED" == "false" ]; then
            echo "   Blocker: AWS Organizations Service Control Policy (SCP) explicitly denies this action."
        fi
        FAILURES=$((FAILURES+1))
    else
        echo "✅ ALLOWED: $ACTION"
    fi
done

if [ "$FAILURES" -gt 0 ]; then
    echo ""
    echo "🚨 Pre-flight check failed! $FAILURES actions are denied."
    exit 1
else
    echo ""
    echo "🚀 Pre-flight check passed! All actions allowed."
    exit 0
fi

