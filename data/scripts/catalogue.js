// Index available user agents, and save it as JSON.


const fs = require('fs');
const path = require('path');

// Function to read JSON files from a directory
function crawlDirectory(directory) {
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
        } else if (path.extname(file) === '.json') {
            const value = loadJson(filePath);
            return value;
        } else if (path.extname(file) === '.txt') {
            const value = loadText(filePath);
            return value;
        }
        return 0;
    });
    return entries.reduce((a, b) => a + b, 0);
}

function loadJson(filePath) {
    const data = fs.readFileSync(filePath, 'utf8');
    try {
        const jsonData = JSON.parse(data);
        // console.log(`Extracted data from ${filePath}:`, jsonData.length, 'entries');
        // console.log(jsonData.length);
        return jsonData.length;
    } catch (err) {
        console.error(`Error parsing JSON from ${filePath}: ${err}`);
        return 0;
    }
}

function loadText(filePath) {
    const data = fs.readFileSync(filePath, 'utf8');
    const lines = data.split(/[\r\n]+/);
    // console.log(lines.length);
    return lines.length;
}

// Example usage
const directoryPath = __dirname + "/../raw";
const total = crawlDirectory(directoryPath);
console.log(total, 'total entries')
