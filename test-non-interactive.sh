#!/usr/bin/env bash

# Test script to demonstrate non-interactive mode of install-ai-tools.sh

echo "Testing non-interactive mode of install-ai-tools.sh"
echo "=================================================="

echo ""
echo "1. Running with --non-interactive --check (system check only):"
./install-ai-tools.sh --non-interactive --check

echo ""
echo "2. Running with --non-interactive --claude-only (install Claude CLI only):"
echo "   (This will install Claude CLI without any prompts)"
./install-ai-tools.sh --non-interactive --claude-only

echo ""
echo "3. Running with --non-interactive --gemini-only (install Gemini CLI only):"
echo "   (This will install Gemini CLI without any prompts)"
./install-ai-tools.sh --non-interactive --gemini-only

echo ""
echo "4. Running with --non-interactive --use-standard-filesystem:"
echo "   (This will use standard filesystem MCP instead of Serena)"
./install-ai-tools.sh --non-interactive --use-standard-filesystem --check

echo ""
echo "5. Testing Serena setup:"
echo "   (This will test the enhanced Serena setup)"
./setup-serena.sh

echo ""
echo "5. Running with --non-interactive --exclude=playwright,puppeteer:"
echo "   (This will skip browser automation MCPs)"
./install-ai-tools.sh --non-interactive --exclude=playwright,puppeteer --check

echo ""
echo "Non-interactive mode test complete!"
echo "The script will use defaults for all prompts when --non-interactive is used."
