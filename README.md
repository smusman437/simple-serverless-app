# Simple Serverless App

A minimal serverless application built with AWS Lambda, API Gateway, DynamoDB, and S3, deployed using Pulumi.

## 🏗️ Architecture

This application uses a simple serverless architecture with exactly 5 AWS services:

```
Internet → API Gateway → Lambda Function → DynamoDB
                           ↓
                       S3 Bucket
                           ↓
                    CloudWatch Logs
```

### Services Used

- **API Gateway HTTP API**: Public HTTPS endpoint
- **AWS Lambda**: Node.js 18 runtime handling all routes
- **DynamoDB**: NoSQL database for storing user data
- **S3**: Object storage for file uploads
- **CloudWatch**: Logging and monitoring

### Features

- ✅ RESTful API with CORS support
- ✅ User management (create, read, list)
- ✅ Health check endpoint
- ✅ S3 integration for file operations
- ✅ Auto-scaling and pay-per-use pricing
- ✅ Infrastructure as Code with Pulumi
- ✅ TypeScript support
- ✅ Automated testing

## 🚀 Quick Start

### Prerequisites

Make sure you have these installed:
- [Node.js](https://nodejs.org/) (v18+)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Pulumi CLI](https://www.pulumi.com/docs/get-started/install/)

### Setup

1. **Clone and setup the project:**
   ```bash
   git clone <your-repo-url>
   cd simple-serverless-app
   npm install
   ```

2. **Configure AWS credentials:**
   ```bash
   aws configure
   ```

3. **Login to Pulumi:**
   ```bash
   # Option 1: Use Pulumi Cloud (free tier available)
   pulumi login
   
   # Option 2: Use local state
   pulumi login --local
   ```

4. **Deploy the application:**
   ```bash
   ./deploy.sh dev
   ```

That's it! Your serverless app will be deployed in 2-3 minutes.

### What Gets Deployed

The deployment creates:
- API Gateway HTTP API with a custom domain
- Lambda function with your application code
- DynamoDB table for user storage
- S3 bucket for file uploads
- CloudWatch log groups for monitoring
- IAM roles and policies with least-privilege access

## 📡 API Endpoints

After deployment, you'll get an API URL like: `https://abc123.execute-api.us-east-1.amazonaws.com/dev`

### Available Endpoints

| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| GET | `/health` | Health check | `{"ok":true,"timestamp":"2024-01-01T00:00:00.000Z"}` |
| GET | `/users` | List all users | `{"users":[],"count":0}` |
| POST | `/users` | Create a new user | `{"id":"uuid","name":"John","email":"john@example.com"}` |
| GET | `/users/{id}` | Get user by ID | `{"id":"uuid","name":"John","email":"john@example.com"}` |
| GET | `/bucket` | Get S3 bucket info | `{"bucketName":"uploads-dev-abc123","region":"us-east-1"}` |

### Example Usage

```bash
# Health check
curl "https://your-api-url.com/health"

# Create a user
curl -X POST "https://your-api-url.com/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'

# List users
curl "https://your-api-url.com/users"

# Get specific user
curl "https://your-api-url.com/users/user-id-here"
```

## 🧪 Testing

Run the automated test suite:

```bash
npm test
```

This will test all API endpoints and verify the application is working correctly.

## 🛠️ Development

### Project Structure

```
simple-serverless-app/
├── src/
│   └── index.ts          # Pulumi infrastructure code
├── dist/                 # Compiled TypeScript
├── deploy.sh             # Deployment script
├── test.js               # API test suite
├── package.json          # Node.js dependencies
├── tsconfig.json         # TypeScript configuration
├── .env.example          # Environment variables template
├── README.md             # This file
└── QUICK_START.md        # Step-by-step guide
```

### Local Development

To modify the Lambda function code, edit the `lambdaCode` variable in `src/index.ts`. The function includes:

- Express-like routing
- CORS handling
- DynamoDB operations
- S3 integration
- Error handling

### Configuration

Copy `.env.example` to `.env` and adjust settings:

```bash
cp .env.example .env
```

### Useful Commands

```bash
# Deploy to dev environment
./deploy.sh dev

# Deploy to production
./deploy.sh prod

# View live logs
pulumi logs --follow

# Get stack outputs
pulumi stack output

# Destroy everything
pulumi destroy
```

## 🔧 Customization

### Adding New Routes

Edit the Lambda function code in `src/index.ts`:

```javascript
// Add new route in the Lambda handler
if (httpMethod === 'GET' && path === '/my-new-route') {
    return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Hello from new route!' })
    };
}
```

### Environment Variables

Add environment variables to the Lambda function:

```typescript
environment: {
    variables: {
        TABLE_NAME: usersTable.name,
        BUCKET_NAME: bucket.bucket,
        NODE_ENV: environment,
        MY_CUSTOM_VAR: "custom-value"
    }
}
```

### Database Schema

The DynamoDB table uses a simple schema:
- `id` (String): Unique user identifier (UUID)
- `name` (String): User's name  
- `email` (String): User's email
- `createdAt` (String): ISO timestamp

To add fields, modify the user creation code in the Lambda function.

## 💰 Cost Estimation

This serverless architecture is very cost-effective:

- **API Gateway**: ~$1 per million requests
- **Lambda**: ~$0.20 per million requests (128MB memory)
- **DynamoDB**: ~$1.25 per million reads/writes (on-demand)
- **S3**: ~$0.023 per GB stored
- **CloudWatch**: ~$0.50 per GB ingested

**Expected monthly cost for light usage**: $0-5

## 📚 Learn More

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Pulumi AWS Guide](https://www.pulumi.com/docs/clouds/aws/)
- [API Gateway HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

**Deployment fails with ARM64 errors:**
This setup avoids Docker/ECS complexity that can cause ARM64 issues on Apple Silicon Macs.

**AWS credentials not found:**
```bash
aws configure
# or set environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

**Pulumi login issues:**
```bash
# Use local state if you don't want cloud login
pulumi login --local
```

**Permission errors:**
Make sure your AWS user has permissions for: Lambda, API Gateway, DynamoDB, S3, IAM, and CloudWatch.

### Getting Help

- Check the [Pulumi Community](https://slack.pulumi.com/)
- Review [AWS Documentation](https://docs.aws.amazon.com/)
- Open an issue in this repository

---

**Happy serverless development! 🎉**