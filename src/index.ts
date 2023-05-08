import { DynamoDBClient } from '@aws-sdk/client-dynamodb';

const dynamoDBClient = new DynamoDBClient({
  region: 'us-west-2',
  credentials: {
    accessKeyId: 'dummy',
    secretAccessKey: 'dummy',
  },
  endpoint: 'http://localhost:8000',
});
