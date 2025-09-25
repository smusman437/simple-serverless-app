#!/bin/bash

# Simple Serverless App Deployment Script - M1 Mac Optimized
# Usage: ./deploy.sh [stack_name]

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

echo -e "${BLUE}🚀 Deploying Simple Serverless App (M1 Mac Optimized)${NC}"
echo -e "${BLUE}Stack: ${STACK_NAME}${NC}"
echo ""

# M1 Mac specific Pulumi configuration
if [[ "$(uname -s)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${YELLOW}🍎 M1/M2/M3 Mac detected - applying optimizations${NC}"
    
    # Check if Rosetta is installed (required for Pulumi stability)
    if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
        echo -e "${YELLOW}Installing Rosetta 2 (required for Pulumi)...${NC}"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        echo -e "${GREEN}✅ Rosetta 2 installed${NC}"
    fi
    
    # Find Pulumi binary location
    PULUMI_PATH=""
    if [ -f "$HOME/.pulumi/bin/pulumi" ]; then
        PULUMI_PATH="$HOME/.pulumi/bin/pulumi"
    elif command -v pulumi >/dev/null 2>&1; then
        PULUMI_PATH="$(command -v pulumi)"
    fi
    
    if [ -z "$PULUMI_PATH" ]; then
        echo -e "${RED}❌ Pulumi not found. Installing Intel version for M1 compatibility...${NC}"
        # Install Intel version of Pulumi under Rosetta
        arch -x86_64 /bin/bash -c "$(curl -fsSL https://get.pulumi.com)"
        
        # Add to PATH
        export PATH="$HOME/.pulumi/bin:$PATH"
        echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> ~/.zshrc
        
        PULUMI_PATH="$HOME/.pulumi/bin/pulumi"
        echo -e "${GREEN}✅ Intel Pulumi installed for M1 compatibility${NC}"
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
    echo -e "${BLUE}   - Pulumi running under Rosetta (x86_64)${NC}"
    echo -e "${BLUE}   - ARM crash prevention enabled${NC}"
    echo -e "${BLUE}   - Performance optimizations applied${NC}"
else
    echo -e "${BLUE}ℹ️  Non-ARM Mac detected - using standard configuration${NC}"
fi

# Check if required tools are installed
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v pulumi &> /dev/null; then
    echo -e "${RED}❌ Pulumi is not installed. Installing Intel version for M1 compatibility...${NC}"
    if [[ "$(uname -m)" == "arm64" ]]; then
        arch -x86_64 /bin/bash -c "$(curl -fsSL https://get.pulumi.com)"
        export PATH="$HOME/.pulumi/bin:$PATH"
        echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> ~/.zshrc
    else
        curl -fsSL https://get.pulumi.com | bash
    fi
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first:${NC}"
    echo -e "${RED}   For M1 Mac: brew install awscli${NC}"
    echo -e "${RED}   Or visit: https://aws.amazon.com/cli/${NC}"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install it first:${NC}"
    echo -e "${RED}   For M1 Mac: brew install node${NC}"
    echo -e "${RED}   Or visit: https://nodejs.org/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites installed${NC}"

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run:${NC}"
    echo -e "${RED}   aws configure${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo -e "${GREEN}✅ AWS Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}✅ AWS Region: ${AWS_REGION}${NC}"

# Install Pulumi dependencies (no need for TypeScript build since we use inline code)
echo -e "${YELLOW}Installing Pulumi dependencies...${NC}"
if [[ "$(uname -m)" == "arm64" ]]; then
    # Use native ARM npm for better performance
    npm install --prefer-offline --no-audit --progress=false
else
    npm install
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Login to Pulumi (if not already logged in)
echo -e "${YELLOW}Checking Pulumi login...${NC}"
if ! pulumi whoami &> /dev/null; then
    echo -e "${YELLOW}Not logged into Pulumi.${NC}"
    echo -e "${BLUE}Choose login method:${NC}"
    echo -e "  1) Pulumi Cloud (recommended for teams)"
    echo -e "  2) Local backend (no account needed)"
    echo ""
    read -p "Enter 1 for Cloud or 2 for Local [default: 2]: " choice
    choice=${choice:-2}
    
    case $choice in
        1)
            echo -e "${YELLOW}Logging into Pulumi Cloud...${NC}"
            pulumi login
            ;;
        *)
            echo -e "${YELLOW}Using local backend...${NC}"
            pulumi login --local
            ;;
    esac
else
    echo -e "${GREEN}✅ Already logged into Pulumi as: $(pulumi whoami)${NC}"
fi

# Select or create stack with proper secrets provider
echo -e "${YELLOW}Setting up Pulumi stack...${NC}"
if ! pulumi stack select $STACK_NAME 2>/dev/null; then
    echo -e "${YELLOW}Creating new stack: ${STACK_NAME}${NC}"
    pulumi stack init $STACK_NAME --secrets-provider passphrase
fi

# Set AWS region config
pulumi config set aws:region $AWS_REGION

# M1 Mac specific pre-deployment checks
if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${YELLOW}Running M1 Mac pre-deployment checks...${NC}"
    
    # Verify Pulumi is working under Rosetta
    if ! pulumi version >/dev/null 2>&1; then
        echo -e "${RED}❌ Pulumi test failed. Please check installation.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ M1 compatibility verified${NC}"
fi

# Deploy infrastructure with M1 optimizations
echo -e "${YELLOW}Deploying infrastructure...${NC}"
echo -e "${BLUE}This may take 2-3 minutes...${NC}"
echo -e "${BLUE}Lambda will be created with AWS SDK v3 and all required dependencies${NC}"

if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${BLUE}Using M1-optimized deployment with timeout protection...${NC}"
    # Use timeout to prevent ARM-related hangs
    timeout 1800 pulumi up --debug --yes --refresh --skip-preview --diff 2>&1 | tee deploy.log
    DEPLOY_STATUS=${PIPESTATUS[0]}
    
    # Handle timeout
    if [ $DEPLOY_STATUS -eq 124 ]; then
        echo -e "${RED}❌ Deployment timed out (30 minutes). This may indicate ARM compatibility issues.${NC}"
        echo -e "${YELLOW}Trying alternative deployment method...${NC}"
        pulumi cancel --yes >/dev/null 2>&1 || true
        sleep 5
        pulumi up --yes --refresh --diff 2>&1 | tee deploy.log
        DEPLOY_STATUS=${PIPESTATUS[0]}
    fi
else
    pulumi up --debug --yes --refresh --skip-preview --diff 2>&1 | tee deploy.log
    DEPLOY_STATUS=${PIPESTATUS[0]}
fi

if [ $DEPLOY_STATUS -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed. Check deploy.log for details.${NC}"
    tail -n 50 deploy.log
    exit $DEPLOY_STATUS
fi

# Get outputs
echo ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""

API_URL=$(pulumi stack output apiUrl 2>/dev/null || echo "Not available")
TABLE_NAME=$(pulumi stack output tableName 2>/dev/null || echo "Not available")
BUCKET_NAME=$(pulumi stack output bucketName 2>/dev/null || echo "Not available")
LAMBDA_NAME=$(pulumi stack output lambdaFunctionName 2>/dev/null || echo "Not available")

echo -e "${BLUE}📋 Stack Information:${NC}"
echo -e "  Stack Name: ${STACK_NAME}"
echo -e "  API URL: ${API_URL}"
echo -e "  DynamoDB Table: ${TABLE_NAME}"
echo -e "  S3 Bucket: ${BUCKET_NAME}"
echo -e "  Lambda Function: ${LAMBDA_NAME}"
echo ""

# Test the API
if [ "$API_URL" != "Not available" ]; then
    echo -e "${YELLOW}Testing API (AWS SDK v3)...${NC}"
    
    echo -e "${BLUE}Testing health endpoint:${NC}"
    curl -s "${API_URL}/health" | jq '.' 2>/dev/null || curl -s "${API_URL}/health"
    echo ""
    
    echo -e "${BLUE}Testing users endpoint (should be empty):${NC}"
    curl -s "${API_URL}/users" | jq '.' 2>/dev/null || curl -s "${API_URL}/users"
    echo ""
    echo ""
fi

echo -e "${GREEN}🔗 Useful Commands:${NC}"
echo -e "  Test API:     curl \"${API_URL}/health\""
echo -e "  Create user:  curl -X POST \"${API_URL}/users\" -H \"Content-Type: application/json\" -d '{\"name\":\"John\",\"email\":\"john@example.com\"}'"
echo -e "  List users:   curl \"${API_URL}/users\""
echo -e "  Get user:     curl \"${API_URL}/users/{user_id}\""
echo -e "  View logs:    pulumi logs --follow"
echo -e "  Update:       ./deploy.sh ${STACK_NAME}"
echo -e "  Destroy:      pulumi destroy"
echo ""

if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "${GREEN}🍎 M1 Mac deployment completed successfully!${NC}"
    echo -e "${BLUE}Note: Pulumi is running under Rosetta for optimal compatibility${NC}"
    echo -e "${BLUE}Lambda is deployed with AWS SDK v3 and all required dependencies${NC}"
else
    echo -e "${GREEN}✨ Your serverless app is ready with AWS SDK v3!${NC}"
fi