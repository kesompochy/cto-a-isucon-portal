import fs from 'fs';

// ミリ秒を秒に変換するための定数
const MS_TO_SEC = 1e3;

// モックデータを生成するための関数
const generateMockData = (sinceHour, teamCount) => {
	const HOUR_IN_SEC = sinceHour * 60 * 60;

	const currentTimeSec = Math.floor(Date.now() / MS_TO_SEC);
	const hoursAgoTimestamp = currentTimeSec - HOUR_IN_SEC;

	const scores = [];

	for (let i = 0; i < teamCount; i++) {
		// Assign initial score of 0 to each team at hoursAgoTimestamp
		scores.push({
			team_id: i,
			score: 0,
			timestamp: hoursAgoTimestamp,
		});

		let score = 0;
		for (
			let timestamp = (hoursAgoTimestamp + Math.random() * 3000) | 0;
			timestamp <= currentTimeSec;
			timestamp += (Math.random() * 3000) | 0
		) {
			score += ((Math.random() * 50000) / 100) | 0;
			scores.push({
				team_id: i,
				score: score,
				timestamp: timestamp,
			});
		}
	}

	return scores;
};

// スクリプトの引数から出力ファイルパスとチーム数を取得する
const [hours = 8, teamCount = 10, outputFilePath = './src/mocks/scores.json'] =
	process.argv.slice(2);

// モックデータを生成する
const mockData = generateMockData(Number(hours), Number(teamCount));

// JSONファイルとして保存する
fs.writeFileSync(outputFilePath, JSON.stringify(mockData, null, 4));
