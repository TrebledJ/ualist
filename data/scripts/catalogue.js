// Index available user agents, and save it as JSON.


const fs = require('fs');
const path = require('path');

// Function to read JSON files from a directory
function crawlDirectory(directory, type) {
    type = type || 1;
    const files = fs.readdirSync(directory);
        // if (err) {
        //     console.error(`Error reading directory: ${err}`);
        //     return;
        // }

    const entries = files.map(file => {
        const filePath = path.join(directory, file);
        const stat = fs.statSync(filePath);
            // if (err) {
            //     console.error(`Error getting file stats: ${err}`);
            //     return;
            // }

        // Check if it's a directory
        if (stat.isDirectory()) {
            // Recursively crawl the directory
            return crawlDirectory(filePath);
        } else if (path.extname(file) === '.json' && !(filePath).includes('extension') && type === 1) {
            const value = loadJson(filePath);
            return value;
        } else if (path.extname(file) === '.txt' && type === 2) {
            const value = loadText(filePath);
            return value;
        }
        return new Set();
    });
    // return entries.reduce((a, b) => a + b, 0);
    return entries.reduce((a, b) => {
        const c = new Set();
        a.forEach(e => c.add(e));
        b.forEach(e => c.add(e));
        return c;
    }, new Set());
}

function loadJson(filePath) {
    const data = fs.readFileSync(filePath, 'utf8');
    try {
        const jsonData = JSON.parse(data);
        // console.log(`Extracted data from ${filePath}:`, jsonData.length, 'entries');
        // console.log(jsonData.length);
        return new Set(jsonData.map(e => e.ua));
        // return jsonData.length;
    } catch (err) {
        console.error(`Error parsing JSON from ${filePath}: ${err}`);
        return new Set();
    }
}

function loadText(filePath) {
    const data = fs.readFileSync(filePath, 'utf8');
    const lines = data.split(/[\r\n]+/);
    // console.log(lines.length);
    // return lines.length;
    return new Set(lines);
}

// Example usage
const directoryPath = __dirname + "/../raw";
const total = crawlDirectory(directoryPath, 1);
console.log(total.size, 'total entries');

// fs.writeFileSync(__dirname + '/processed3.txt', [...total].join('\n'));
// fs.writeFileSync(__dirname + '/processed2.txt', [...total].filter(e => !e.startsWith('Mozilla')).join('\n'));

let models = [];
const uap = require('ua-parser-js');
for (const a of total) {
    const ua = uap(a);
    if (a.includes('Linux;') && a.includes('; Android')) {
        let res = a.match(/(?<=Mozilla\/5.0 \()(.*?)(?=\))/gi);
        // console.log(res);
        if (!res) {
            res = a.match(/(?<=\(Linux; )(.*?)(?=\))/gi);
        }
        if (!res)
            continue;
        const tokens = res[0].split(';');
        const left = tokens.map(t => t.trim())
            .filter(t => !t.startsWith('Linux'))
            .filter(t => !t.startsWith('Android'))
            .filter(t => !t.startsWith('arm'))
            .filter(t => t !== 'U')
            .filter(t => t !== 'wv')
            .filter(t => t !== 'K')
            .filter(t => !t.startsWith('zh-') && !t.startsWith('en-'));

        if (ua.device.model === 'K')
            continue;

        if (ua.device.model)
            models.push(ua.device.model);

        // console.log(a);
        // console.log(left, ' :: ', ua.os.name, ua.os.version, ' :: ', ua.device.model, ua.device.vendor);
    }
    // console.log(ua);
}

const uniq = [...new Set(models)];
uniq.sort();
console.log("'" + uniq.join("','") + "'");


