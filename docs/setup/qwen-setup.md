# Qwen Coder CLI Setup

This document explains how to set up Qwen Coder CLI with Ollama integration for local model inference.

## Overview

Qwen Coder is a CLI tool based on the Gemini CLI that provides code generation and assistance capabilities. It can be configured to work with local models through Ollama.

## Prerequisites

1. **Ollama installed and running** on your host machine
2. **Models loaded** in Ollama (e.g., `qwen3-coder:30b`, `deepseek-r1:8b-0528-qwen3-q8_0`)
3. **Network access** from your development environment to the Ollama host

## Installation

The Qwen CLI is installed automatically by the `install-ai-tools.sh` script:

```bash
./install-ai-tools.sh
```

Or install only Qwen:

```bash
./install-ai-tools.sh --qwen-only
```

## Configuration

### Automatic Configuration

The installer automatically creates a configuration file at `~/.qwen/config.json` with Ollama integration:

```json
{
  "openai": {
    "baseURL": "http://127.0.0.1:11434/v1",
    "apiKey": "ollama"
  },
  "models": {
    "default": "qwen3-coder:30b"
  },
  "settings": {
    "temperature": 0.1,
    "maxTokens": 4096,
    "topP": 0.9
  }
}
```

### Custom Ollama Host/Port

If your Ollama is running on a different host or port:

```bash
./install-ai-tools.sh --ollama-host=192.168.1.100 --ollama-port=11434
```

### Manual Configuration

You can manually edit the configuration file at `~/.qwen/config.json`:

```json
{
  "openai": {
    "baseURL": "http://YOUR_OLLAMA_HOST:YOUR_OLLAMA_PORT/v1",
    "apiKey": "ollama"
  },
  "models": {
    "default": "qwen3-coder:30b",
    "alternative": "deepseek-r1:8b-0528-qwen3-q8_0"
  },
  "settings": {
    "temperature": 0.1,
    "maxTokens": 4096,
    "topP": 0.9
  }
}
```

## DevContainer Integration

### Port Forwarding

If running in a devcontainer, you need to forward the Ollama port from the host:

```json
{
  "forwardPorts": [11434],
  "remoteEnv": {
    "OLLAMA_HOST": "host.docker.internal"
  }
}
```

### Host Network Access

Alternatively, configure the devcontainer to use the host network:

```json
{
  "runArgs": ["--network=host"]
}
```

## Usage

### Basic Usage

```bash
# Interactive chat
qwen

# Generate code for a specific file
qwen --file=src/main.py

# Ask a specific question
qwen "Write a Python function to sort a list"
```

### Model Selection

```bash
# Use a specific model
qwen --model=qwen3-coder:30b "Explain this code"

# Use alternative model
qwen --model=deepseek-r1:8b-0528-qwen3-q8_0 "Generate a React component"
```

### Configuration Options

```bash
# Set temperature
qwen --temperature=0.2 "Generate creative code"

# Set max tokens
qwen --max-tokens=2048 "Write a long function"
```

## Troubleshooting

### Connection Issues

1. **Check Ollama is running:**
   ```bash
   curl http://127.0.0.1:11434/api/tags
   ```

2. **Verify port forwarding in devcontainer:**
   ```bash
   curl http://host.docker.internal:11434/api/tags
   ```

3. **Check firewall settings** on the host machine

### Model Issues

1. **List available models:**
   ```bash
   ollama list
   ```

2. **Pull required models:**
   ```bash
   ollama pull qwen3-coder:30b
   ollama pull deepseek-r1:8b-0528-qwen3-q8_0
   ```

### CLI Issues

1. **Check Qwen CLI installation:**
   ```bash
   qwen --version
   ```

2. **Verify configuration:**
   ```bash
   cat ~/.qwen/config.json
   ```

3. **Test with verbose output:**
   ```bash
   qwen --verbose "Hello"
   ```

## NixOS Configuration

For NixOS users, ensure Ollama is properly configured:

```nix
{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "127.0.0.1";
    user = "ollama";
    group = "ollama";
    acceleration = "rocm";
    openFirewall = true;
    loadModels = [
      "deepseek-r1:8b-0528-qwen3-q8_0"
      "qwen3-coder:30b"
    ];
  };
}
```

## Performance Tips

1. **Use appropriate model sizes** for your hardware
2. **Enable GPU acceleration** in Ollama when possible
3. **Monitor resource usage** during inference
4. **Consider model quantization** for better performance

## Integration with Other Tools

Qwen CLI can be used alongside other AI tools:

- **Claude CLI** for different model capabilities
- **Gemini CLI** for Google's models
- **MCP servers** for enhanced functionality (Claude only)

## Resources

- [Qwen Coder GitHub Repository](https://github.com/QwenLM/qwen-code)
- [Ollama Documentation](https://ollama.ai/docs)
- [OpenAI API Compatibility](https://github.com/QwenLM/qwen-code/blob/main/docs/cli/openai-auth.md)
