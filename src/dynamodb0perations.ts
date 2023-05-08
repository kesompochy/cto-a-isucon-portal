import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';

const dynamoDBClient = new DynamoDBClient({
  region: 'us-west-2',
  credentials: {
    accessKeyId: 'dummy',
    secretAccessKey: 'dummy',
  },
  endpoint: 'http://localhost:8000',
});

const ddbDocClient = DynamoDBDocumentClient.from(dynamoDBClient);

async function getItem(tableName: string, id: string) {
  const params = {
    TableName: tableName,
    Key: {
      id,
    },
  };

  try {
    const result = await ddbDocClient.send(new GetCommand(params));
    return result.Item;
  } catch (error) {
    console.error('Error getting item:', error);
  }
}

async function putItem(tableName: string, item: any) {
  const params = {
    TableName: tableName,
    Item: item,
  };

  try {
    await ddbDocClient.send(new PutCommand(params));
    console.log('Item added:', item);
  } catch (error) {
    console.error('Error adding item:', error);
  }
}
