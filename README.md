# claudeAnon

Run Claude Code with Anthropic API but **hide your email** from the header.

## What it does

- Uses official Anthropic API (full quality, all features)
- Routes through a local proxy that strips email from `/v1/account` responses
- Header shows: `claude-sonnet-4-5 · API Usage Billing` (no email)

## Files

```
claudeAnon/
├── email-hiding-proxy.js   # Node.js proxy server
├── claudeanon.sh           # Wrapper script
└── README.md              # This file
```

## Installation

### Option 1: System-wide (recommended)

1. Copy files to `~/.claude/scripts/`:
```bash
cp email-hiding-proxy.js ~/.claude/scripts/
cp claudeanon.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/claudeanon.sh
```

2. Add alias to `~/.zshrc`:
```bash
echo "alias claudeanon='bash ~/.claude/scripts/claudeanon.sh'" >> ~/.zshrc
source ~/.zshrc
```

### Option 2: Run from Desktop

```bash
cd ~/Desktop/claudeAnon
chmod +x claudeanon.sh
./claudeanon.sh
```

## Usage

```bash
# Run with default model (claude-sonnet-4-5)
claudeanon

# Use different model
ANTHROPIC_MODEL=claude-opus-4-5 claudeanon

# Pass arguments to Claude
claudeanon -p "Hello world"
```

## Requirements

- Node.js (for proxy)
- Claude Code CLI (`claude`)
- Valid `ANTHROPIC_API_KEY` in environment or macOS Keychain

## How it works

```
┌─────────────┐      /v1/account      ┌──────────────┐
│ Claude CLI  │ ─────────────────────>│ Local Proxy  │
│             │ <─────────────────────│ (port 3738)  │
└─────────────┘   no email returned   └──────┬───────┘
                                               │
                                               ↓
                                        ┌──────────────┐
                                        │ api.anthropic│
                                        │    .com      │
                                        └──────────────┘
```

1. Wrapper script starts Node.js proxy on port 3738
2. Proxy forwards all requests to `api.anthropic.com`
3. When `/v1/account` is called, proxy removes `email` and `name` from response
4. Claude displays header without email

## Privacy

- Your email is only hidden from **display** in the Claude header
- Anthropic still sees your email on their backend (linked to your API key)
- This is a **client-side privacy filter**, not backend anonymity

## Troubleshooting

**Proxy fails to start:**
- Ensure Node.js is installed: `node --version`
- Check port 3738 is free: `lsof -i :3738`

**API key not found:**
- Set environment variable: `export ANTHROPIC_API_KEY=sk-ant-...`
- Or store in Keychain (see `provider-picker.sh` for reference)

**Email still shows:**
- Ensure proxy is running (check for "Proxy active" message)
- Verify `ANTHROPIC_BASE_URL` points to `http://127.0.0.1:3738`

## License

MIT - Free to use and modify.
