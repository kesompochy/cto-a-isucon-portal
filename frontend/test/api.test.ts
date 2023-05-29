describe('API mock test', () => {
    const standardMockScores = [
        {
            team_id: '0',
            score: 0,
            timestamp: 12345678
        },
        {
            team_id: '1',
            score: 1,
            timestamp: 13345678,
        },
    ]
    test('mock should be work', () => {
        const getScores = vi.fn(()=>{return standardMockScores})
        const score = getScores()
        expect(score[0].score).toBe(0)
    })
})
