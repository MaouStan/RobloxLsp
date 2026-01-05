#!/usr/bin/env node
/**
 * @import Feature Test Script
 * Tests the @import annotation autocomplete functionality
 *
 * Usage: node test_import.js
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// ANSI colors for output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
};

function log(color, ...args) {
    console.log(color + args.join(' ') + colors.reset);
}

function header(text) {
    console.log();
    log(colors.bright, '='.repeat(60));
    log(colors.bright, '  ' + text);
    log(colors.bright, '='.repeat(60));
    console.log();
}

// Test files content
const testFiles = {
    'lib1.lua': `local GG = {}

function GG.greet(name)
    return "Hello, " .. name .. "!"
end

function GG.farewell(name)
    return "Goodbye, " .. name .. "!"
end

return GG
`,
    'main.lua': `---@import "./lib1.lua" as lib1

lib1.g

---@import "./lib1.lua" as Utils
Utils.f
`
};

// LSP message handling - properly parse Content-Length protocol
class LSPClient {
    constructor(process) {
        this.process = process;
        this.messageId = 1;
        this.pendingRequests = new Map();
        this.buffer = '';

        this.process.stdout.on('data', (data) => {
            this.buffer += data.toString();
            this.processMessages();
        });
    }

    processMessages() {
        while (this.buffer.length > 0) {
            // Look for Content-Length header
            const lengthMatch = this.buffer.match(/Content-Length: (\d+)\r\n\r\n/i);
            if (!lengthMatch) {
                // Not enough data yet
                return;
            }

            const contentLength = parseInt(lengthMatch[1]);
            const headerEnd = lengthMatch.index + lengthMatch[0].length;
            const messageStart = headerEnd;

            // Check if we have the full message
            if (this.buffer.length < messageStart + contentLength) {
                return;
            }

            // Use Buffer for proper byte handling
            const buffer = Buffer.from(this.buffer, 'utf8');
            const messageContent = buffer.subarray(messageStart, messageStart + contentLength).toString('utf8');

            // Update buffer by removing processed bytes
            this.buffer = buffer.subarray(messageStart + contentLength).toString('utf8');

            // Try to parse the JSON message
            try {
                const msg = JSON.parse(messageContent);
                this.handleMessage(msg);
            } catch (e) {
                // Try to find valid JSON objects in the content
                let found = false;
                let depth = 0;
                let start = -1;

                for (let i = 0; i < messageContent.length; i++) {
                    const ch = messageContent[i];
                    if (ch === '{' && start === -1) {
                        start = i;
                        depth = 1;
                    } else if (ch === '{') {
                        depth++;
                    } else if (ch === '}') {
                        depth--;
                        if (depth === 0 && start !== -1) {
                            try {
                                const jsonStr = messageContent.substring(start, i + 1);
                                const msg = JSON.parse(jsonStr);
                                this.handleMessage(msg);
                                found = true;
                                start = -1;
                            } catch (e2) {
                                // Not valid JSON
                            }
                        }
                    }
                }

                if (!found) {
                    log(colors.red, '[ERROR] Failed to parse message:', e.message);
                    log(colors.gray, '[RAW]', messageContent.substring(0, 200));
                }
            }
        }
    }

    handleMessage(msg) {
        if (msg.method) {
            // Notification
            if (msg.method === 'window/logMessage') {
                const message = msg.params?.message || '';
                if (message.includes('[@import]') || message.includes('import')) {
                    log(colors.cyan, '[LSP LOG]', message);
                }
            }
        } else if (msg.id !== undefined) {
            // Response
            const pending = this.pendingRequests.get(msg.id);
            if (pending) {
                this.pendingRequests.delete(msg.id);
                if (msg.error) {
                    pending.reject(new Error(msg.error.message));
                } else {
                    log(colors.gray, '[LSP <-]', pending.method, '->', JSON.stringify(msg.result).substring(0, 100) + '...');
                    pending.resolve(msg.result);
                }
            }
        }
    }

    sendRequest(method, params, timeout = 10000) {
        const id = this.messageId++;
        const message = {
            jsonrpc: '2.0',
            id: id,
            method: method,
            params: params
        };

        const content = JSON.stringify(message);
        const header = `Content-Length: ${content.length}\r\n\r\n`;

        log(colors.gray, '[LSP ->]', method, JSON.stringify(params).substring(0, 80) + '...');
        this.process.stdin.write(header + content);

        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                this.pendingRequests.delete(id);
                reject(new Error('Timeout waiting for response to ' + method));
            }, timeout);

            this.pendingRequests.set(id, {
                resolve: (result) => {
                    clearTimeout(timer);
                    resolve(result);
                },
                reject: (err) => {
                    clearTimeout(timer);
                    reject(err);
                },
                method
            });
        });
    }

    sendNotification(method, params) {
        const message = {
            jsonrpc: '2.0',
            method: method,
            params: params
        };

        const content = JSON.stringify(message);
        const header = `Content-Length: ${content.length}\r\n\r\n`;
        this.process.stdin.write(header + content);
    }
}

// Test functions
async function testCompletion(client, uri, line, char) {
    const position = { line, character: char };
    const result = await client.sendRequest('textDocument/completion', {
        textDocument: { uri },
        position
    });
    return result;
}

async function runTests() {
    header('@import Feature Test Script');

    const testDir = path.join(__dirname, 'test_temp');
    if (fs.existsSync(testDir)) {
        fs.rmSync(testDir, { recursive: true, force: true });
    }
    fs.mkdirSync(testDir, { recursive: true });

    log(colors.blue, '[SETUP] Creating test files...');

    for (const [name, content] of Object.entries(testFiles)) {
        const filePath = path.join(testDir, name);
        fs.writeFileSync(filePath, content);
        log(colors.blue, '  Created:', name);
    }
    console.log();

    // Start LSP server
    const serverExe = path.join(__dirname, 'server/bin/Windows/lua-language-server.exe');
    if (!fs.existsSync(serverExe)) {
        log(colors.red, '[ERROR] LSP server not found at:', serverExe);
        log(colors.yellow, '[INFO] Please build the server first or run from the correct directory');
        process.exit(1);
    }

    log(colors.blue, '[START] Starting LSP server:', serverExe);
    console.log();

    const lspProcess = spawn(serverExe, [], {
        stdio: ['pipe', 'pipe', 'pipe'],
        windowsHide: true
    });

    lspProcess.stderr.on('data', (data) => {
        const output = data.toString();
        if (output.includes('[@import]') || output.includes('import') || output.includes('ERROR')) {
            log(colors.cyan, '[LSP STDERR]', output);
        }
    });

    lspProcess.on('error', (err) => {
        log(colors.red, '[ERROR] LSP process error:', err.message);
    });

    const client = new LSPClient(lspProcess);

    // Give the server time to start
    await new Promise(resolve => setTimeout(resolve, 500));

    const results = { test1: false, test2: false };

    try {
        // Initialize LSP
        log(colors.blue, '[INIT] Initializing LSP...');
        await client.sendRequest('initialize', {
            processId: process.pid,
            rootUri: null,
            capabilities: {}
        });
        client.sendNotification('initialized', {});
        console.log();

        // Open the main file - use file:/// URI format
        const mainPath = path.join(testDir, 'main.lua');
        const mainUri = 'file:///' + mainPath.replace(/\\/g, '/');
        const mainContent = fs.readFileSync(mainPath, 'utf8');

        log(colors.blue, '[OPEN] Opening main.lua...');
        log(colors.gray, '[URI]', mainUri);
        client.sendNotification('textDocument/didOpen', {
            textDocument: {
                uri: mainUri,
                languageId: 'lua',
                version: 1,
                text: mainContent
            }
        });
        console.log();

        // Wait for processing - LSP needs time to parse and cache
        log(colors.yellow, '[WAIT] Waiting for LSP to process file...');
        await new Promise(resolve => setTimeout(resolve, 3000));
        console.log();

        // Test 1: lib1. completion (line 3, char 7 - after "lib1.g")
        header('Test 1: lib1.g - completion');
        log(colors.yellow, '[TEST] Requesting completion at line 3, character 7');
        console.log();

        try {
            const completions = await testCompletion(client, mainUri, 3, 7);

            if (completions && completions.items) {
                log(colors.blue, '[RESULT] Found ' + completions.items.length + ' completion items:');

                const items = {};
                for (const item of completions.items.slice(0, 20)) {
                    const label = item.label || '?';
                    const kind = item.kind ? ' (kind: ' + item.kind + ')' : '';
                    log(colors.green, '  - ' + label + kind);
                    items[label] = item;
                }
                if (completions.items.length > 20) {
                    log(colors.gray, '  ... and ' + (completions.items.length - 20) + ' more');
                }
                console.log();

                if (items.greet || items.farewell) {
                    log(colors.green, '[PASS] Found export(s):',
                        items.greet ? 'greet ' : '',
                        items.farewell ? 'farewell' : '');
                    results.test1 = true;
                } else {
                    log(colors.red, '[FAIL] Expected exports (greet, farewell) not found!');
                    log(colors.yellow, '[INFO] Check if @import parsing is working');
                }
            } else {
                log(colors.red, '[FAIL] No completions returned');
            }
        } catch (e) {
            log(colors.red, '[ERROR]', e.message);
        }
        console.log();

        // Test 2: Utils. completion (line 6, char 8 - after "Utils.f")
        header('Test 2: Utils.f - completion');
        log(colors.yellow, '[TEST] Requesting completion at line 6, character 8');
        console.log();

        try {
            const completions = await testCompletion(client, mainUri, 6, 8);

            if (completions && completions.items) {
                log(colors.blue, '[RESULT] Found ' + completions.items.length + ' completion items:');

                const items = {};
                for (const item of completions.items.slice(0, 20)) {
                    const label = item.label || '?';
                    const kind = item.kind ? ' (kind: ' + item.kind + ')' : '';
                    log(colors.green, '  - ' + label + kind);
                    items[label] = item;
                }
                console.log();

                if (items.farewell) {
                    log(colors.green, '[PASS] "farewell" found in completion!');
                    results.test2 = true;
                } else {
                    log(colors.red, '[FAIL] "farewell" not found!');
                }
            } else {
                log(colors.red, '[FAIL] No completions returned');
            }
        } catch (e) {
            log(colors.red, '[ERROR]', e.message);
        }
        console.log();

    } finally {
        // Cleanup
        header('Cleanup');
        lspProcess.kill();
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true, force: true });
        }
        log(colors.blue, '[DONE] Test files removed');
        console.log();
    }

    // Summary
    header('Test Summary');
    const total = Object.keys(results).length;
    const passed = Object.values(results).filter(v => v).length;

    for (const [name, result] of Object.entries(results)) {
        const status = result ? colors.green + '✅ PASSED' : colors.red + '❌ FAILED';
        log(colors.reset, '  ' + name + ': ' + status);
    }
    console.log();
    log(colors.bright, '  Total: ' + passed + '/' + total + ' tests passed');
    console.log();

    if (passed === total) {
        log(colors.green, '🎉 All tests passed!');
        process.exit(0);
    } else {
        log(colors.red, '⚠️  Some tests failed - check the debug output above');
        process.exit(1);
    }
}

// Run
runTests().catch(err => {
    log(colors.red, '[FATAL]', err.message);
    console.error(err);
    process.exit(1);
});
