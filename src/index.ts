import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

// Get configuration
const config = new pulumi.Config();
const environment = pulumi.getStack();

// Create DynamoDB table for users
const usersTable = new aws.dynamodb.Table("users-table", {
    name: `users-${environment}`,
    billingMode: "PAY_PER_REQUEST",
    hashKey: "id",
    attributes: [
        { name: "id", type: "S" }
    ],
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Create S3 bucket for file uploads
const bucket = new aws.s3.Bucket("uploads-bucket", {
    bucket: `uploads-${environment}-${Math.random().toString(36).substring(7)}`,
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Block public access to S3 bucket
new aws.s3.BucketPublicAccessBlock("uploads-bucket-pab", {
    bucket: bucket.id,
    blockPublicAcls: true,
    blockPublicPolicy: true,
    ignorePublicAcls: true,
    restrictPublicBuckets: true
});

// Create IAM role for Lambda
const lambdaRole = new aws.iam.Role("lambda-role", {
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: { Service: "lambda.amazonaws.com" }
        }]
    })
});

// Attach basic Lambda execution policy
new aws.iam.RolePolicyAttachment("lambda-basic-execution", {
    role: lambdaRole.name,
    policyArn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
});

// Create policy for DynamoDB and S3 access
const lambdaPolicy = new aws.iam.RolePolicy("lambda-policy", {
    role: lambdaRole.id,
    policy: pulumi.all([usersTable.arn, bucket.arn]).apply(([tableArn, bucketArn]) =>
        JSON.stringify({
            Version: "2012-10-17",
            Statement: [
                {
                    Effect: "Allow",
                    Action: [
                        "dynamodb:PutItem",
                        "dynamodb:GetItem",
                        "dynamodb:Scan",
                        "dynamodb:Query",
                        "dynamodb:UpdateItem",
                        "dynamodb:DeleteItem"
                    ],
                    Resource: tableArn
                },
                {
                    Effect: "Allow",
                    Action: [
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:ListBucket"
                    ],
                    Resource: [bucketArn, `${bucketArn}/*`]
                }
            ]
        })
    )
});

// Lambda function code using AWS SDK v3 (matching your package.json)
const lambdaCode = `
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { randomUUID } = require('crypto');

// Initialize AWS SDK v3 clients
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

const TABLE_NAME = process.env.TABLE_NAME;
const BUCKET_NAME = process.env.BUCKET_NAME;

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
};

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    // API Gateway v2 uses different event structure
    const httpMethod = event.requestContext.http.method;
    const rawPath = event.rawPath || event.path;
    const body = event.body;
    
    // Remove stage prefix from path (e.g., /dev/health -> /health)
   const path = rawPath.replace(new RegExp('^\\/[^\\/]+'), '') || '/';

    console.log('Method:', httpMethod, 'Raw Path:', rawPath, 'Cleaned Path:', path);
    
    try {
        // Handle CORS preflight
        if (httpMethod === 'OPTIONS') {
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: ''
            };
        }
        
        // Health check
        if (httpMethod === 'GET' && path === '/health') {
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify({ 
                    ok: true, 
                    timestamp: new Date().toISOString(),
                    environment: process.env.NODE_ENV || 'development',
                    sdkVersion: 'v3'
                })
            };
        }
        
        // Get bucket info
        if (httpMethod === 'GET' && path === '/bucket') {
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify({ 
                    bucketName: BUCKET_NAME,
                    region: process.env.AWS_REGION
                })
            };
        }
        
        // Create user
        if (httpMethod === 'POST' && path === '/users') {
            const userData = JSON.parse(body || '{}');
            
            if (!userData.name || !userData.email) {
                return {
                    statusCode: 400,
                    headers: corsHeaders,
                    body: JSON.stringify({ error: 'Name and email are required' })
                };
            }
            
            const user = {
                id: randomUUID(),
                name: userData.name,
                email: userData.email,
                createdAt: new Date().toISOString()
            };
            
            const command = new PutCommand({
                TableName: TABLE_NAME,
                Item: user
            });
            
            await docClient.send(command);
            
            return {
                statusCode: 201,
                headers: corsHeaders,
                body: JSON.stringify(user)
            };
        }
        
        // Get all users
        if (httpMethod === 'GET' && path === '/users') {
            const command = new ScanCommand({
                TableName: TABLE_NAME
            });
            
            const result = await docClient.send(command);
            
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify({
                    users: result.Items || [],
                    count: result.Count || 0
                })
            };
        }
        
        // Get user by ID
        if (httpMethod === 'GET' && path.startsWith('/users/')) {
            const userId = path.split('/')[2];
            
            const command = new GetCommand({
                TableName: TABLE_NAME,
                Key: { id: userId }
            });
            
            const result = await docClient.send(command);
            
            if (!result.Item) {
                return {
                    statusCode: 404,
                    headers: corsHeaders,
                    body: JSON.stringify({ error: 'User not found' })
                };
            }
            
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify(result.Item)
            };
        }
        
        // Route not found
        return {
            statusCode: 404,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Route not found' })
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ 
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};
`;

// Create Lambda function with proper package.json matching your dependencies
const lambda = new aws.lambda.Function("api-lambda", {
    name: `api-lambda-${environment}`,
    runtime: "nodejs18.x",
    handler: "index.handler",
    role: lambdaRole.arn,
    code: new pulumi.asset.AssetArchive({
        "index.js": new pulumi.asset.StringAsset(lambdaCode),
        "package.json": new pulumi.asset.StringAsset(JSON.stringify({
            name: "simple-serverless-app-lambda",
            version: "1.0.0",
            description: "Lambda function for simple serverless app",
            main: "index.js",
            dependencies: {
                "@aws-sdk/client-dynamodb": "3.400.0",
                "@aws-sdk/client-s3": "3.400.0",
                "@aws-sdk/lib-dynamodb": "3.400.0",
                "@aws-sdk/util-dynamodb": "3.400.0"
            }
        }, null, 2))
    }),
    environment: {
        variables: {
            TABLE_NAME: usersTable.name,
            BUCKET_NAME: bucket.bucket,
            NODE_ENV: environment
        }
    },
    timeout: 30,
    memorySize: 256,
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Create API Gateway HTTP API
const api = new aws.apigatewayv2.Api("http-api", {
    name: `http-api-${environment}`,
    protocolType: "HTTP",
    corsConfiguration: {
        allowOrigins: ["*"],
        allowHeaders: ["content-type"],
        allowMethods: ["*"]
    },
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Create Lambda integration
const integration = new aws.apigatewayv2.Integration("lambda-integration", {
    apiId: api.id,
    integrationType: "AWS_PROXY",
    integrationUri: lambda.arn,
    payloadFormatVersion: "2.0"
});

// Create catch-all route
const route = new aws.apigatewayv2.Route("api-route", {
    apiId: api.id,
    routeKey: "$default",
    target: pulumi.interpolate`integrations/${integration.id}`
});

// Create API stage
const stage = new aws.apigatewayv2.Stage("api-stage", {
    apiId: api.id,
    name: environment,
    autoDeploy: true,
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Give API Gateway permission to invoke Lambda
new aws.lambda.Permission("api-lambda-permission", {
    statementId: "AllowExecutionFromAPIGateway",
    action: "lambda:InvokeFunction",
    function: lambda.name,
    principal: "apigateway.amazonaws.com",
    sourceArn: pulumi.interpolate`${api.executionArn}/*/*`
});

// CloudWatch Log Group for Lambda
new aws.cloudwatch.LogGroup("lambda-logs", {
    name: pulumi.interpolate`/aws/lambda/${lambda.name}`,
    retentionInDays: 7,
    tags: {
        Environment: environment,
        Project: "simple-serverless-app"
    }
});

// Exports
export const apiUrl = pulumi.interpolate`${api.apiEndpoint}/${stage.name}`;
export const tableName = usersTable.name;
export const bucketName = bucket.bucket;
export const lambdaFunctionName = lambda.name;
export const region = aws.config.region;