# LeePick Homebrew Tap

Homebrew tap for LeePick development tools.

## Quick Start

```bash
# One-time setup (requires LeePick org access)
export HOMEBREW_GITHUB_API_TOKEN="your-github-token"
brew tap leepickdev/tap

# Install
brew install handshake
brew services start handshake

# Verify
curl http://localhost:5757/health
```

## Available Formulae

### handshake

Multi-agent swarm orchestration for parallel development with Claude Code.

| Component | Description |
|-----------|-------------|
| `handshaked` | Background daemon service (port 5757) |
| `hive-client` | CLI for crew/agent management |
| `handshake-init` | Project initialization script |

### etiquette

Multi-LLM agent swarms with Claude, Codex, or Gemini. Lighter than handshake - pure bash, no daemon required.

```bash
# Install
brew install leepickdev/tap/etiquette

# Initialize in any project
cd your-project
etiquette-init

# For Codex/Gemini users - start launch daemon
.etiquette/bin/hive-launch-daemon
```

| Component | Description |
|-----------|-------------|
| `etiquette-init` | Project initialization script |
| `.etiquette/hive` | Main CLI for crew management |
| `.etiquette/bin/hive-launch-daemon` | Terminal spawner for non-TTY agents |

## Prerequisites

### 1. GitHub Token (Required for handshake)

The handshake source is in a private repo. You need a GitHub token with `repo` scope:

```bash
# Create token at: https://github.com/settings/tokens
# Required scope: repo (Full control of private repositories)

# Set permanently in your shell profile (~/.zshrc or ~/.bashrc):
export HOMEBREW_GITHUB_API_TOKEN="ghp_your_token_here"
```

### 2. System Requirements

- macOS 12.0+ (Monterey or later)
- Python 3.11+ (installed automatically by Homebrew)
- iTerm2 or tmux (for terminal management)
- Claude Code CLI (for plugin integration)

## Installation

```bash
# Ensure token is set
echo $HOMEBREW_GITHUB_API_TOKEN

# Add tap
brew tap leepickdev/tap

# Install handshake
brew install handshake

# Start daemon as background service
brew services start handshake

# Verify daemon is running
curl -s http://localhost:5757/health | jq .
```

## Usage

### Initialize a Project

```bash
cd your-project
handshake-init
```

This creates the `.handshake/` directory with all necessary scripts and configuration.

### Launch a Crew

```bash
# From your project directory
hive-client crew launch haack --tier haiku --mode auto

# Or with desktop spaces (macOS)
hive-client crew launch haack --tier sonnet --mode auto --desktop
```

### With Claude Code

After installing the handshake plugin:

```
/handshake:hive-bootstrap
```

The plugin detects the Homebrew-installed daemon automatically.

## Updating

```bash
brew update
brew upgrade handshake
brew services restart handshake
```

## Troubleshooting

### "404 Not Found" during install

Your GitHub token doesn't have access to the private repo:

```bash
# Verify token is set
echo $HOMEBREW_GITHUB_API_TOKEN

# Test repo access
curl -H "Authorization: token $HOMEBREW_GITHUB_API_TOKEN" \
  https://api.github.com/repos/leepickdev/handshake

# If 404, contact admin for org access
```

### Daemon Not Starting

```bash
# Check service status
brew services list | grep handshake

# View logs
tail -f $(brew --prefix)/var/log/handshake.log

# Restart service
brew services restart handshake

# Manual start (for debugging)
handshaked --debug
```

### Port Already in Use

```bash
# Check what's using port 5757
lsof -i :5757

# Kill existing process
pkill -f handshaked

# Restart service
brew services restart handshake
```

## Uninstalling

```bash
brew services stop handshake
brew uninstall handshake
brew untap leepickdev/tap
```

## Version History

| Version | Changes |
|---------|---------|
| 1.9.3 | Parallel crew boot, consolidated wizard |
| 1.9.2 | Two-dialog wizard |
| 1.9.1 | Base wizard restore |
| 1.9.0 | Express mode |

## Support

Internal tool - contact the Handshake team on Slack.
