# claudeAnon

> Run Claude Code with the official Anthropic API but **hide your email** from the session header.

Ever noticed how Claude Code displays your email in the header when using the official Anthropic API? This tool gives you **client-side privacy** by routing through a local proxy that strips your email from the account response—while still giving you full access to Anthropic's models and features.

## 🎯 What It Does

- ✅ Uses **official Anthropic API** (full quality, all Claude features)
- ✅ Routes through a **local Node.js proxy** on port 3738
- ✅ Strips `email` and `name` from `/v1/account` responses
- ✅ Header shows: `claude-sonnet-4-5 · API Usage Billing` (no email)
- ✅ Auto-cleanup: proxy shuts down when you exit Claude
- ✅ Works with any Anthropic model (Sonnet, Opus, Haiku)

## 📁 Files Included

```
claudeAnon/
├── email-hiding-proxy.js   # Node.js proxy server (intercepts /v1/account)
├── claudeanon.sh           # Bash wrapper (starts proxy + launches Claude)
├── install.sh              # Quick installer (copies files, adds alias)
└── README.md              # This file
```

## 🚀 Quick Start

### Option 1: Clone and Install (Recommended)

```bash
# Clone the repo
git clone https://github.com/Dennesssy/claudeAnon.git
cd claudeAnon

# Run installer (copies files, adds alias to ~/.zshrc)
./install.sh

# Reload shell
source ~/.zshrc

# Run Claude in anonymous mode
claudeanon
```

### Option 2: Manual Install

```bash
# Create scripts directory
mkdir -p ~/.claude/scripts

# Copy files
cp email-hiding-proxy.js ~/.claude/scripts/
cp claudeanon.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/claudeanon.sh

# Add alias to shell config
echo "alias claudeanon='bash ~/.claude/scripts/claudeanon.sh'" >> ~/.zshrc
source ~/.zshrc

# Run it
claudeanon
```

### Option 3: Run Directly from Clone

```bash
cd claudeAnon
chmod +x claudeanon.sh
./claudeanon.sh
```

## 📖 Usage Examples

```bash
# Basic usage (default model: claude-sonnet-4-5-20250929)
claudeanon

# Use Opus 4.5
ANTHROPIC_MODEL=claude-opus-4-5 claudeanon

# Use Haiku
ANTHROPIC_MODEL=claude-haiku-4-5 claudeanon

# Pass arguments directly to Claude
claudeanon -p "Explain quantum computing"

# Continue last conversation
claudeanon -c

# Run with debug mode
claudeanon --debug

# Use with max budget
claudeanon --max-budget-usd 1.00
```

## 📋 Requirements

| Requirement | Version/Details |
|-------------|-----------------|
| **Node.js** | v14+ (for proxy server) |
| **Claude CLI** | Installed via `npm install -g @anthropic/claude-code` |
| **API Key** | Valid `ANTHROPIC_API_KEY` in env or macOS Keychain |
| **OS** | macOS, Linux, or WSL2 |
| **Shell** | bash or zsh |

### Check if you have dependencies:

```bash
node --version      # Should show v14+
claude --version    # Should show Claude Code v2.x
echo $ANTHROPIC_API_KEY  # Should show sk-ant-...
```

## 🔧 How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                         TERMINAL                                │
│                                                                  │
│   $ claudeanon                                                   │
│                                                                  │
│   🔒 Starting Claude in Anonymous Mode                          │
│      (Email hidden from header)                                  │
│                                                                  │
│   ✓ Proxy active on port 3738                                    │
│                                                                  │
│   ┌─────────────┐   /v1/account    ┌──────────────┐            │
│   │ Claude CLI  │ ────────────────>│ Local Proxy  │            │
│   │             │ <──────────────── │ (port 3738)  │            │
│   └─────────────┘  no email in     └──────┬───────┘            │
│      Header              response            │                   │
│                                            │                    │
│                                            ↓                    │
│                                     ┌──────────────┐            │
│                                     │ api.anthropic│            │
│                                     │    .com      │            │
│                                     └──────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### Flow Breakdown:

1. **You run `claudeanon`**
   - Wrapper script (`claudeanon.sh`) starts

2. **API Key Detection**
   - Checks `ANTHROPIC_API_KEY` environment variable
   - If not found, searches macOS Keychain for accounts: `claude`, `aicodetracker`, `anthropic`
   - Exits with error if no key found

3. **Proxy Startup**
   - Node.js proxy (`email-hiding-proxy.js`) starts on port 3738
   - Proxy runs in background with PID stored in `~/.claude/.anon-proxy.pid`
   - Waits 1 second for proxy to initialize

4. **Environment Setup**
   - Clears any existing Anthropic env vars
   - Sets `ANTHROPIC_BASE_URL=http://127.0.0.1:3738` (points to proxy)
   - Sets `ANTHROPIC_MODEL=claude-sonnet-4-5-20250929` (or custom)

5. **Proxy Interception**
   - **All requests**: Forwarded to `https://api.anthropic.com` unchanged
   - **`/v1/account` requests**: Response parsed, `email` and `name` fields removed
   - Modified response returned to Claude CLI

6. **Claude Launch**
   - Claude CLI starts with proxy as endpoint
   - Fetches account info → receives stripped response
   - Header displays: `claude-sonnet-4-5 · API Usage Billing` (no email)

7. **Cleanup on Exit**
   - Trap handler kills proxy process
   - PID file removed
   - Temporary log file deleted

## 🔒 Privacy Disclosure

**Important:** This is **client-side privacy filtering only**.

| What Happens | Details |
|--------------|---------|
| ✅ **Hidden from display** | Your email won't appear in the Claude header |
| ✅ **Hidden from screenshots** | Screenshots won't show your email |
| ✅ **Hidden from shoulder surfers** | People looking at your screen won't see it |
| ❌ **NOT hidden from Anthropic** | Anthropic still has your email (linked to API key) |
| ❌ **NOT backend anonymity** | Your API key identifies you to Anthropic |

**Think of it as:** A privacy screen filter for your Claude session, not Tor for AI.

## 🐛 Troubleshooting

### Proxy fails to start

```bash
# Check Node.js is installed
node --version

# Check if port 3738 is already in use
lsof -i :3738

# Kill any existing proxy
pkill -f "email-hiding-proxy"

# Try running proxy manually to see error
cd ~/Desktop/claudeAnon
node email-hiding-proxy.js
```

### API key not found

```bash
# Set environment variable
export ANTHROPIC_API_KEY=sk-ant-api03-...

# Or store in macOS Keychain
security add-generic-password -a "claude" -s "ANTHROPIC_API_KEY" -w "sk-ant-api03-..."

# Verify it's stored
security find-generic-password -a "claude" -s "ANTHROPIC_API_KEY" -w
```

### Email still shows in header

```bash
# Verify proxy is running
lsof -i :3738

# Check what ANTHROPIC_BASE_URL is set to
echo $ANTHROPIC_BASE_URL
# Should be: http://127.0.0.1:3738

# Manually test proxy endpoint
curl http://127.0.0.1:3738/v1/account
# Should return: {} (empty object, no email)
```

### "claude: command not found"

```bash
# Install Claude Code CLI
npm install -g @anthropic/claude-code

# Verify installation
claude --version
```

### Alias not found after install

```bash
# Reload shell config
source ~/.zshrc
# or
source ~/.bashrc

# Verify alias
type claudeanon
```

## 🛠️ Advanced Configuration

### Change Proxy Port

Edit `claudeanon.sh`:

```bash
PROXY_PORT=3738  # Change to your preferred port
```

### Use Different Model by Default

Edit `claudeanon.sh`:

```bash
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-opus-4-5}"
```

### Proxy Multiple Claude Instances

Run with different ports:

```bash
# Terminal 1
PROXY_PORT=3738 ./claudeanon.sh

# Terminal 2
PROXY_PORT=3739 ./claudeanon.sh
```

## 📊 Comparison with Alternatives

| Method | Email Hidden | Full API Access | Setup Difficulty |
|--------|--------------|-----------------|------------------|
| **claudeAnon** | ✅ Yes | ✅ Yes (Anthropic) | Easy (script) |
| **Use Z.ai/Groq/etc** | ✅ Yes | ⚠️ Partial (different models) | Easy |
| **No proxy** | ❌ No | ✅ Yes (Anthropic) | Easiest |
| **Custom CLI build** | ✅ Yes | ✅ Yes | Hard (fork + compile) |

## 🤝 Contributing

Feel free to:

- Report bugs via GitHub Issues
- Submit pull requests for improvements
- Fork for your own use case
- Share with others who might need it

## 📝 License

MIT License - Free to use, modify, and distribute.

## 🌟 Credits

Created by [@Dennesssy](https://github.com/Dennesssy)

Built with:
- Node.js (proxy server)
- Bash (wrapper script)
- Claude Code CLI (target application)

---

**Note:** This tool is not affiliated with or endorsed by Anthropic. Use at your own risk. Respect Anthropic's Terms of Service.
