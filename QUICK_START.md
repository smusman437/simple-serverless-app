# 🚀 Quick Start Guide

This guide will get your serverless application running in under 10 minutes!

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] **Node.js 18+** installed ([Download here](https://nodejs.org/))
- [ ] **AWS CLI** installed ([Installation guide](https://aws.amazon.com/cli/))
- [ ] **Pulumi CLI** installed ([Installation guide](https://www.pulumi.com/docs/get-started/install/))
- [ ] **AWS Account** with programmatic access
- [ ] **Git** (optional, for cloning)

## 🏁 Step-by-Step Setup

### Step 1: Get the Code

Choose one of these options:

**Option A: Clone from Git**
```bash
git clone <your-repo-url>
cd simple-serverless-app
```

**Option B: Create manually**
```bash
mkdir simple-serverless-app
cd simple-serverless-app
# Copy all the provided files into this directory
```

### Step 2: Install Dependencies

```bash
# Install Node.js packages
npm install
```

**Expected output:**
```
added 95 packages, and audited 96 packages in 3s
```

### Step 3: Configure AWS

**Check if AWS is already configured:**
```bash
aws sts get-caller-identity
```

**If not configured, set it up:**
```bash
aws configure
```

**Enter your credentials when prompted:**
```
AWS Access Key ID [None]: AKIA...
AWS Secret Access Key [None]: wJalr...
Default region name [None]: us-east-1
Default output format [None]: json
```

**Verify it worked:**
```bash
aws sts get-caller-identity
```

You should see something like:
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Step 4: Setup Pulumi

**Login to Pulumi:**

Choose one of these options:

**Option A: Pulumi Cloud (Recommended)**
```bash
pulumi login
```
- Opens browser for signup/login
- Free tier includes 2000 resources
- Provides web dashboard

**Option B: Local State**
```bash
pulumi login --local
```
- Stores state locally
- No account needed
- Good for testing

**Verify login:**
```bash
pulumi whoami
```

### Step 5: Deploy Your App

**Run the deployment script:**
```bash
chmod +x deploy.sh
./deploy.sh dev
```

**What you'll see:**
```
🚀 Deploying Simple Serverless App
Stack: dev

Checking prerequisites...
✅ All prerequisites installed

Checking AWS credentials...
✅ AWS Account: 123456789012
✅ AWS Region: us-east-1

Installing dependencies...
Building TypeScript...
Checking Pulumi login...
Setting up Pulumi stack...
Deploying infrastructure...
This may take 2-3 minutes...

Updating (dev)

View Live: https://app.pulumi.com/your-org/simple-serverless-app/dev/updates/1

     Type                             Name                           Status      
 +   pulumi:pulumi:Stack              simple-serverless-app-dev     created     
 +   ├─ aws:iam:Role                  lambda-role                    created     
 +   ├─ aws:dynamodb:Table            users-table                    created     
 +   ├─ aws:s3:Bucket                 uploads-bucket                 created     
 +   ├─ aws:apigatewayv2:Api          http-api                       created     
 +   ├─ aws:s3:BucketPublicAccessBlock uploads-bucket-pab           created     
 +   ├─ aws:iam:RolePolicyAttachment  lambda-basic-execution         created     
 +   ├─ aws:iam:RolePolicy            lambda-policy                  created     
 +   ├─ aws:cloudwatch:LogGroup       lambda-logs                    created     
 +   ├─ aws:lambda:Function           api-lambda                     created     
 +   ├─ aws:apigatewayv2:Integration  lambda-integration             created     
 +   ├─ aws:lambda:Permission         api-lambda-permission          created     
 +   ├─ aws:apigatewayv2:Route        api-route                      created     
 +   └─ aws:apigatewayv2:Stage        api-stage                      created     

Outputs:
    apiUrl           : "https://abc123def.execute-api.us-east-1.amazonaws.com/dev"
    bucketName       : "uploads-dev-xyz789"
    lambdaFunctionName: "api-lambda-dev"
    region           : "us-east-1"
    tableName        : "users-dev"

Resources:
    + 14 created

Duration: 1m23s

🎉 Deployment complete!

📋 Stack Information:
  Stack Name: dev
  API URL: https://abc123def.execute-api.us-east-1.amazonaws.com/dev
  DynamoDB Table: users-dev
  S3 Bucket: uploads-dev-xyz789
  Lambda Function: api-lambda-dev

Testing API...
Testing health endpoint:
{
  "ok": true,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "environment": "dev"
}

Testing users endpoint (should be empty):
{
  "users": [],
  "count": 0
}

🔗 Useful Commands:
  Test API:     curl "https://abc123def.execute-api.us-east-1.amazonaws.com/dev/health"
  Create user:  curl -X POST "https://abc123def.execute-api.us-east-1.amazonaws.com/dev/users" -H "Content-Type: application/json" -d '{"name":"John","email":"john@example.com"}'
  List users:   curl "https://abc123def.execute-api.us-east-1.amazonaws.com/dev/users"
  View logs:    pulumi logs --follow
  Update:       ./deploy.sh dev
  Destroy:      pulumi destroy

✨ Your serverless app is ready!
```

### Step 6: Test Your API

**Copy your API URL from the deployment output, then test it:**

```bash
# Replace YOUR_API_URL with the actual URL from deployment
export API_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/dev"

# Test health endpoint
curl "$API_URL/health"
```

**Expected response:**
```json
{
  "ok": true,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "environment": "dev"
}
```

**Test user creation:**
```bash
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
```

**Expected response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Alice",
  "email": "alice@example.com",
  "createdAt": "2024-01-15T10:35:00.000Z"
}
```

**List users:**
```bash
curl "$API_URL/users"
```

### Step 7: Run Automated Tests

**Run the test suite:**
```bash
npm test
```

**Expected output:**
```
🔗 API URL: https://abc123def.execute-api.us-east-1.amazonaws.com/dev

🧪 Running API Tests...

1️⃣ Testing health endpoint...
✅ Health check passed
   Response: {
  "ok": true,
  "timestamp": "2024-01-15T10:40:00.000Z",
  "environment": "dev"
}

2️⃣ Testing empty users list...
✅ Users list retrieved
   Count: 0

3️⃣ Testing user creation...
✅ User created successfully
   User ID: 550e8400-e29b-41d4-a716-446655440000
   Name: Test User
   Email: test@example.com

4️⃣ Testing user retrieval...
✅ User retrieved successfully
   Retrieved user: Test User

5️⃣ Testing users list with data...
✅ Users list with data retrieved
   Count: 1
   First user: Test User

6️⃣ Testing bucket endpoint...
✅ Bucket info retrieved
   Bucket: uploads-dev-xyz789
   Region: us-east-1

7️⃣ Testing 404 handling...
✅ 404 handling works correctly

🎉 All tests completed!
```

## ✅ Success! You're Done!

Your serverless application is now running on AWS! Here's what you have:

### 🎯 What Got Created

- **API Gateway**: Public HTTPS endpoint for your API
- **Lambda Function**: Serverless compute running your application code
- **DynamoDB Table**: NoSQL database for storing users
- **S3 Bucket**: Object storage for file uploads
- **CloudWatch Logs**: Automatic logging and monitoring
- **IAM Roles**: Secure permissions for all services

### 🔗 Your Resources

Save these for later use:

```bash
# Get all your resource information
pulumi stack output

# Your specific URLs and names:
# API URL: [from deployment output]
# DynamoDB Table: users-dev
# S3 Bucket: uploads-dev-[random-suffix]
# Lambda Function: api-lambda-dev
```

## 🚀 What's Next?

### Development Workflow

1. **Make changes** to `src/index.ts`
2. **Redeploy**: `./deploy.sh dev`
3. **Test**: `npm test`
4. **Monitor**: `pulumi logs --follow`

### Deploy to Production

```bash
./deploy.sh prod
```

This creates a completely separate production environment.

### Add Features

- **File uploads**: The S3 bucket is ready for file storage
- **Authentication**: Add AWS Cognito for user auth
- **Database**: Add more fields to the DynamoDB schema
- **Monitoring**: CloudWatch dashboards and alerts

### Monitor Your App

```bash
# View live logs
pulumi logs --follow

# Check AWS Console
# Lambda: https://console.aws.amazon.com/lambda/
# API Gateway: https://console.aws.amazon.com/apigateway/
# DynamoDB: https://console.aws.amazon.com/dynamodb/
```

## 🧹 Cleanup (When Done Testing)

To avoid any charges, destroy the resources:

```bash
pulumi destroy
```

Type "yes" when prompted. This removes everything from AWS.

## 🆘 Troubleshooting

### Common Issues

**❌ "AWS credentials not found"**
```bash
aws configure
# Enter your credentials
```

**❌ "Pulumi login failed"**
```bash
# Try local state instead
pulumi login --local
```

**❌ "Permission denied on deploy.sh"**
```bash
chmod +x deploy.sh
```

**❌ "Stack already exists"**
```bash
# Use a different stack name
./deploy.sh my-unique-name
```

**❌ "Region not supported"**
```bash
# Set a different AWS region
aws configure set region us-west-2
```

### Get Help

- **Check logs**: `pulumi logs --follow`
- **View AWS Console**: Check the specific service that's failing
- **Pulumi Community**: [Join Slack](https://slack.pulumi.com/)
- **AWS Support**: [AWS Documentation](https://docs.aws.amazon.com/)

## 🎉 Congratulations!

You've successfully deployed a production-ready serverless application! 

The entire stack is:
- ✅ **Scalable**: Handles traffic spikes automatically
- ✅ **Cost-effective**: Pay only for what you use
- ✅ **Secure**: IAM roles with least-privilege access
- ✅ **Monitored**: CloudWatch logging built-in
- ✅ **Maintainable**: Infrastructure as Code with Pulumi

**Next steps**: Check out the main README.md for customization options and advanced features!