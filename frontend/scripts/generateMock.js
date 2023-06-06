import fs from 'fs';

// ミリ秒を秒に変換するための定数
const MS_TO_SEC = 1e3;

// モックデータを生成するための関数
const generateMockData = (sinceHour, teamCount) => {
	// 時間を調整するための定数（3時間を秒単位で表現）
	const THREE_HOURS_IN_SEC = sinceHour * 60 * 60;

	const currentTimeSec = Math.floor(Date.now() / MS_TO_SEC);
	const threeHoursAgoTimestamp = currentTimeSec - THREE_HOURS_IN_SEC;

	const scores = [];

	for (let i = 0; i < teamCount; i++) {
		let score = 0;
		for (
			let timestamp = threeHoursAgoTimestamp;
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
