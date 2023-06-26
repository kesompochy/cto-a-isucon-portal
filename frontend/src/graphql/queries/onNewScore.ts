export const onNewScore = `
    subscription OnNewScore {
        onNewScore {
            team_id
            score
            timestamp
            messages
        }
    }
`;
