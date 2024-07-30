export const getAllScores = `
  query GetAllScores($limit: Int, $nextToken: String) {
    getAllScores(limit: $limit, nextToken: $nextToken) {
      scores {
        team_id
        score
        timestamp
        messages
      }
      nextToken
    }
  }
`;
