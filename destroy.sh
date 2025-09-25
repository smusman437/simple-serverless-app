#!/bin/bash

# Simple Serverless App Destroy Script - M1 Mac Optimized
# Usage: ./destroy.sh [stack_name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default stack name
STACK_NAME=${1:-dev}

# Set Pulumi passphrase for local backend (required for secrets)
export PULUMI_CONFIG_PASSPHRASE=${PULUMI_CONFIG_PASSPHRASE:-"pulumi-local-dev-passphrase"}

echo -e "${RED}💥 Destroying Simple Serverless App Infrastructure${NC}"
echo -e "${RED}Stack: ${STACK_NAME}${NC}"
echo ""

# Confirmation prompt
echo -e "${YELLOW}⚠️  WARNING: This will permanently delete all resources including:${NC}"
echo -e "  - Lambda function and logs"
echo -e "  - API Gateway"
echo -e "  - DynamoDB table and ALL data"
echo -e "  - S3 bucket and ALL files"
echo -e "  - IAM roles and policies"
echo ""
read -p "Are you sure you want to destroy everything? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${BLUE}Destruction cancelled. Your infrastructure is safe.${NC}"
    exit 0
fi

# M1 Mac specific Pulumi configuration
if [[ "$(uname -s)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${YELLOW}🍎 M1/M2/M3 Mac detected - applying optimizations${NC}"
    
    # Check if Rosetta is installed
    if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
        echo -e "${RED}❌ Rosetta 2 required but not installed.${NC}"
        echo -e "${RED}Please run: /usr/sbin/softwareupdate --install-rosetta --agree-to-license${NC}"
        exit 1
    fi
    
    # Find Pulumi binary location
    PULUMI_PATH=""
    if [ -f "$HOME/.pulumi/bin/pulumi" ]; then
        PULUMI_PATH="$HOME/.pulumi/bin/pulumi"
    elif command -v pulumi >/dev/null 2>&1; then
        PULUMI_PATH="$(command -v pulumi)"
    fi
    
    if [ -z "$PULUMI_PATH" ]; then
        echo -e "${RED}❌ Pulumi not found. Please install it first.${NC}"
        exit 1
    fi
    
    # Create M1-optimized wrapper function for Pulumi
    pulumi() {
        # Set environment variables for better ARM compatibility
        GODEBUG=asyncpreemptoff=1 \
        PULUMI_SKIP_UPDATE_CHECK=true \
        PULUMI_DISABLE_AUTOMATIC_PLUGIN_ACQUISITION=false \
        arch -x86_64 "$PULUMI_PATH" "$@"
    }
    export -f pulumi
    
    # Set additional M1 optimization environment variables
    export PULUMI_SKIP_UPDATE_CHECK=true
    export GOMAXPROCS=1
    export GODEBUG=asyncpreemptoff=1
    
    echo -e "${GREEN}✅ M1 Mac optimizations applied${NC}"
fi

# Check if Pulumi is installed
if ! command -v pulumi &> /dev/null; then
    echo -e "${RED}❌ Pulumi is not installed.${NC}"
    echo -e "${RED}Please install it first or run ./deploy.sh to set up everything.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites verified${NC}"

# Login to Pulumi (if not already logged in)
echo -e "${YELLOW}Checking Pulumi login...${NC}"
if ! pulumi whoami &> /dev/null; then
    echo -e "${YELLOW}Not logged into Pulumi. Using local backend...${NC}"
    pulumi login --local
else
    echo -e "${GREEN}✅ Already logged into Pulumi as: $(pulumi whoami)${NC}"
fi

# Check if stack exists
echo -e "${YELLOW}Checking if stack exists...${NC}"
if ! pulumi stack select $STACK_NAME 2>/dev/null; then
    echo -e "${RED}❌ Stack '$STACK_NAME' not found.${NC}"
    echo -e "${BLUE}Available stacks:${NC}"
    pulumi stack ls 2>/dev/null || echo "No stacks found"
    exit 1
fi

echo -e "${GREEN}✅ Stack '$STACK_NAME' found${NC}"

# Show what will be destroyed
echo -e "${YELLOW}Current stack resources:${NC}"
echo ""
API_URL=$(pulumi stack output apiUrl 2>/dev/null || echo "Not available")
TABLE_NAME=$(pulumi stack output tableName 2>/dev/null || echo "Not available")
BUCKET_NAME=$(pulumi stack output bucketName 2>/dev/null || echo "Not available")
LAMBDA_NAME=$(pulumi stack output lambdaFunctionName 2>/dev/null || echo "Not available")

echo -e "${BLUE}📋 Resources to be destroyed:${NC}"
echo -e "  Stack Name: ${STACK_NAME}"
echo -e "  API URL: ${API_URL}"
echo -e "  DynamoDB Table: ${TABLE_NAME}"
echo -e "  S3 Bucket: ${BUCKET_NAME}"
echo -e "  Lambda Function: ${LAMBDA_NAME}"
echo ""

# Final confirmation
echo -e "${RED}⚠️  FINAL WARNING: This action cannot be undone!${NC}"
read -p "Type 'DESTROY' in capital letters to proceed: " final_confirmation

if [ "$final_confirmation" != "DESTROY" ]; then
    echo -e "${BLUE}Destruction cancelled. Your infrastructure is safe.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}🚨 Starting destruction process...${NC}"

# Destroy infrastructure with M1 optimizations
if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${BLUE}Using M1-optimized destruction with timeout protection...${NC}"
    # Use timeout to prevent ARM-related hangs
    timeout 1800 pulumi destroy --debug --yes --skip-preview 2>&1 | tee destroy.log
    DESTROY_STATUS=${PIPESTATUS[0]}
    
    # Handle timeout
    if [ $DESTROY_STATUS -eq 124 ]; then
        echo -e "${RED}❌ Destruction timed out (30 minutes). This may indicate ARM compatibility issues.${NC}"
        echo -e "${YELLOW}Trying alternative destruction method...${NC}"
        pulumi cancel --yes >/dev/null 2>&1 || true
        sleep 5
        pulumi destroy --yes 2>&1 | tee destroy.log
        DESTROY_STATUS=${PIPESTATUS[0]}
    fi
else
    pulumi destroy --debug --yes --skip-preview 2>&1 | tee destroy.log
    DESTROY_STATUS=${PIPESTATUS[0]}
fi

if [ $DESTROY_STATUS -ne 0 ]; then
    echo -e "${RED}❌ Destruction failed. Check destroy.log for details.${NC}"
    echo -e "${YELLOW}Common issues and solutions:${NC}"
    echo -e "  1. S3 bucket not empty - delete objects manually in AWS console"
    echo -e "  2. Resources in use - wait a few minutes and try again"
    echo -e "  3. Permission issues - check your AWS credentials"
    echo ""
    echo -e "${YELLOW}To force cleanup, you can try:${NC}"
    echo -e "  - Delete resources manually in AWS console"
    echo -e "  - Run: pulumi refresh && pulumi destroy --yes"
    echo -e "  - Remove stack: pulumi stack rm $STACK_NAME --yes"
    tail -n 50 destroy.log
    exit $DESTROY_STATUS
fi

echo ""
echo -e "${GREEN}🎉 Destruction completed successfully!${NC}"
echo ""
echo -e "${GREEN}✅ All AWS resources have been deleted:${NC}"
echo -e "  ✓ Lambda function and logs removed"
echo -e "  ✓ API Gateway deleted"
echo -e "  ✓ DynamoDB table and data deleted"
echo -e "  ✓ S3 bucket and files deleted"
echo -e "  ✓ IAM roles and policies removed"
echo ""

# Option to remove the stack entirely
echo -e "${YELLOW}Stack cleanup:${NC}"
read -p "Do you also want to remove the Pulumi stack '$STACK_NAME'? (y/N): " remove_stack

if [[ "$remove_stack" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing Pulumi stack...${NC}"
    pulumi stack rm $STACK_NAME --yes
    echo -e "${GREEN}✅ Stack '$STACK_NAME' removed${NC}"
else
    echo -e "${BLUE}Stack '$STACK_NAME' kept (empty but available for reuse)${NC}"
fi

echo ""
if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${GREEN}🍎 M1 Mac destruction completed successfully!${NC}"
    echo -e "${BLUE}Note: Pulumi ran under Rosetta for optimal compatibility${NC}"
else
    echo -e "${GREEN}💥 Infrastructure destruction complete!${NC}"
fi

echo ""
echo -e "${GREEN}💰 AWS Cost Impact:${NC}"
echo -e "  ✓ No more Lambda execution charges"
echo -e "  ✓ No more API Gateway request charges"
echo -e "  ✓ No more DynamoDB storage charges"
echo -e "  ✓ No more S3 storage charges"
echo ""
echo -e "${BLUE}📝 To redeploy in the future, simply run: ./deploy.sh${NC}"