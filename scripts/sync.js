#!/usr/local/bin/node

import { Command } from 'commander';
import chalk from 'chalk';
import fs from 'fs';


function syncMd(prefix, fromFile, toFile) {
    const inFile = fs.readFileSync(fromFile).toString();
    const outFile = fs.readFileSync(toFile).toString();

    const inLines = inFile.split('\n');
    const outLines = outFile.split('\n');
    
    // Enumerate headings in src.
    const headings = [];
    for (const [lineno, l] of inLines.entries()) {
        const match = /^\s*#+\s*(.*?)\s*$/g.exec(l.trim());
        if (match && match.length > 1) {
            headings.push([match[1], lineno]);
            // console.log("H:", match[1]);
        }
    }

    headings.push(['###', inLines.length]); // EOF.


    const get_content_from_src = (tag) => {
        for (const [hno, [h, inno]] of headings.slice(0, -1).entries()) {
            if (tag === h) {
                const [_, outno] = headings[hno + 1];
                // Skip heading -> inno+1
                const content = inLines.slice(inno+1, outno).join('\n');
                console.log(chalk.green(`Found content for [${prefix}:${h}]: L${inno+1}-${outno}`));
                return content;
            }
        }
        console.log(chalk.red(`Could not find heading for [${prefix}:${tag}] in src file.`));
        return undefined;
    };
    
    // Merge and combine to output.
    const lines = [];
    let prevInTag = false;
    for (const l of outLines) {
        const re = new RegExp('<!--\\s*' + prefix + '#+\\s*(.*?)\\s*#\\s*-->', 'g');
        const match = re.exec(l.trim());
        if (match && match.length > 1) {
            lines.push(l);
            prevInTag = true;
            
            const content = get_content_from_src(match[1]);
            lines.push(content);
        } else if (prevInTag) {
            const match_end = /<!--\s*end\s*-->/g.exec(l.trim());
            if (match_end) {
                lines.push(l);
                prevInTag = false;
            }
            // Otherwise, skip the lines inside.
        } else {
            lines.push(l);
        }
    }

    const output = lines.join('\n');

    fs.writeFileSync(toFile, output);
}

function syncHtml(prefix, fromFile, toFile) {
    const inFile = fs.readFileSync(fromFile).toString();
    const outFile = fs.readFileSync(toFile).toString();

    const inLines = inFile.split('\n');
    const outLines = outFile.split('\n');

    const spChars = '.?*+\\^$()[]{}'
    const escape = s => {
        for (const c of spChars)
            s = s.replace(c, '\\' + c);
        return s;
    };
    
    const get_content_from_src = (tag) => {
        const re = new RegExp('<!--\\s*' + prefix + '#\\s*' + escape(tag) + '\\s*#\\s*-->', 'ig');
        const match = re.exec(inFile.trim());
        if (match) {
            const ss = inFile.substring(match.index);
            const match_end = /<!--\s*end\s*-->/g.exec(ss);
            const content = ss.substring(match[0].length, match_end.index);
            console.log(chalk.green(`Found content for [${prefix}:${tag}] in src file (${content.length} chars).`));
            return content;
        }
        console.log(chalk.red(`Could not find heading for [${prefix}:${tag}] in src file.`));
        return undefined;
    };
    
    // Merge and combine to output.
    const lines = [];
    let prevInTag = false;
    for (const l of outLines) {
        const re = new RegExp('<!--\\s*' + prefix + '#+\\s*(.*?)\\s*#\\s*-->', 'g');
        const match = re.exec(l.trim());
        if (match && match.length > 1) {
            lines.push(l);
            prevInTag = true;
            
            const content = get_content_from_src(match[1]);
            lines.push(content);
        } else if (prevInTag) {
            const match_end = /<!--\s*end\s*-->/g.exec(l.trim());
            if (match_end) {
                lines.push(l);
                prevInTag = false;
            }
            // Otherwise, skip the lines inside.
        } else {
            lines.push(l);
        }
    }

    const output = lines.join('\n');
    fs.writeFileSync(toFile, output);
}


async function main() {
    const program = new Command();

    program
        .version('0.0.1')
        .description('Markdown Docs Sync')
        .requiredOption('-f, --from <filename>', 'Specify source filenames')
        .requiredOption('-t, --target <filename>', 'Specify filenames to insert content into')
        .option('-p, --prefix <prefix>', 'Specify a prefix to match in the tag')
        .action(async (options) => {
            const fromFile = options.from;
            const toFile = options.target;
            const prefix = options.prefix ?? '';
            if (fromFile.endsWith('.md') && toFile.endsWith('.md')) {
                syncMd(prefix, fromFile, toFile);
            } else if (fromFile.endsWith('.html') && toFile.endsWith('.html')) {
                syncHtml(prefix, fromFile, toFile);
            } else {
                console.log(chalk.red('Unknown file extensions.'));
            }
        });

    await program.parseAsync(process.argv);
}

main()

