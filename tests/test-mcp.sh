#!/bin/bash
export PATH="$HOME/.npm-global/bin:$PATH"

echo "Testing MCP servers individually..."

echo -e "\n1. Testing git server:"
timeout 5 npx @modelcontextprotocol/server-git --help 2>&1 || echo "Exit code: $?"

echo -e "\n2. Testing fetch server:"
timeout 5 npx @modelcontextprotocol/server-fetch --help 2>&1 || echo "Exit code: $?"

echo -e "\n3. Testing time server:"
timeout 5 npx @modelcontextprotocol/server-time --help 2>&1 || echo "Exit code: $?"

echo -e "\n4. Testing if servers exist in npm cache:"
ls -la ~/.npm/_npx/ 2>/dev/null | head -20

echo -e "\n5. Testing with stdio initialization (how Claude starts them):"
echo '{"jsonrpc": "2.0", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}}, "id": 1}' | timeout 2 npx @modelcontextprotocol/server-git 2>&1 || echo "Exit code: $?"