import fs from 'fs';
import { exec } from 'child_process';

// APIの設定
const API_KEY = process.env.API_KEY;
const API_ENDPOINT = process.env.API_ENDPOINT;

let count = 0;

// JSONファイルを読み込む
fs.readFile('./src/mocks/scores.json', 'utf8', (err, data) => {
    if (err) {
        console.error("Error reading file:", err);
        return;
    }

    const jsonData = JSON.parse(data);

    // 各エントリに対してcurlコマンドを生成し実行
    jsonData.forEach(entry => {
        const { team_id, score, timestamp, messages } = entry;

        const query = `mutation {
            updateTeamScore(
                team_id: ${team_id},
                pass: true,
                score: ${score},
                success: 1,
                fail: 0,
                messages: ${JSON.stringify(messages)},
                timestamp: ${timestamp}
            ) {
                team_id
                pass
                score
                success
                fail
                messages
                timestamp
            }
        }`;

        const curlCommand = `curl -XPOST -H "Content-Type:application/json" -H "x-api-key:${API_KEY}" -d '{"query": ${JSON.stringify(query)}}' '${API_ENDPOINT}'`;

        // curlコマンドを実行
        
        exec(curlCommand, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error executing curl command: ${error}`);
                return;
            }
            console.log(`Curl command executed successfully for team_id: ${team_id}`);
            console.log(`stdout: ${stdout}`);
            if (stderr) {
                console.error(`stderr: ${stderr}`);
            }
        });
        count++;
        console.log("Count:", count);
    });
});
