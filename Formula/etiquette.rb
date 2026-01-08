class Etiquette < Formula
  desc "Multi-LLM agent swarms with Claude, Codex, or Gemini"
  homepage "https://github.com/leepickdev/etiquette"
  version "1.0.0"
  license "MIT"

  # Install from HEAD using git (works with SSH keys for private repos)
  head do
    url "https://github.com/leepickdev/etiquette.git", branch: "main", using: :git
  end

  # No Python dependency - pure bash

  def install
    # Store core binaries in libexec
    (libexec/".etiquette/bin").mkpath
    cp_r Dir["core/bin/*"], libexec/".etiquette/bin/"

    # Store templates
    cp "templates/hive", libexec/".etiquette/hive"

    # Store provider docs
    (libexec/"providers").install Dir["providers/*"]

    # Install skills for Claude plugin
    (share/"etiquette/skills").install Dir["skills/*"]

    # Create global init script
    (bin/"etiquette").write <<~EOS
      #!/bin/bash
      # Initialize etiquette in current project
      set -e

      ETIQUETTE_DIR=".etiquette"
      PROVIDER_OVERRIDE=""
      FORCE=false

      # Parse arguments
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --provider|-p) PROVIDER_OVERRIDE="$2"; shift 2 ;;
          --provider=*) PROVIDER_OVERRIDE="${1#*=}"; shift ;;
          --force|-f) FORCE=true; shift ;;
          --help|-h)
            echo "Usage: etiquette [--provider claude|codex|gemini] [--force]"
            echo ""
            echo "Initialize Etiquette in current project"
            echo ""
            echo "Options:"
            echo "  -p, --provider   Set provider (claude, codex, gemini)"
            echo "  -f, --force      Reinitialize even if already exists"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
          *) shift ;;
        esac
      done

      if [[ -d "$ETIQUETTE_DIR" ]] && [[ "$FORCE" == false ]]; then
        echo "Etiquette already initialized in this project"
        echo "Use --force to reinitialize"
        exit 0
      fi

      echo "Initializing Etiquette in $(pwd)..."

      # Create directory structure
      mkdir -p "$ETIQUETTE_DIR"/{bin,config,status,tasks,context,queue,registry,docs}

      # Copy scripts from libexec
      cp "#{libexec}/.etiquette/hive" "$ETIQUETTE_DIR/"
      cp "#{libexec}/.etiquette/bin/"* "$ETIQUETTE_DIR/bin/"

      # Determine provider (flag > env > auto-detect)
      if [[ -n "$PROVIDER_OVERRIDE" ]]; then
        PROVIDER="$PROVIDER_OVERRIDE"
      elif [[ -n "$ETIQUETTE_PROVIDER" ]]; then
        PROVIDER="$ETIQUETTE_PROVIDER"
      elif command -v codex &>/dev/null && ! command -v claude &>/dev/null; then
        PROVIDER="codex"
      elif command -v gemini &>/dev/null && ! command -v claude &>/dev/null; then
        PROVIDER="gemini"
      else
        PROVIDER="claude"
      fi

      # Validate provider
      if [[ "$PROVIDER" != "claude" && "$PROVIDER" != "codex" && "$PROVIDER" != "gemini" ]]; then
        echo "Error: Invalid provider '$PROVIDER'. Use: claude, codex, or gemini"
        exit 1
      fi

      # Copy provider-specific docs
      if [[ "$PROVIDER" == "codex" ]]; then
        cp -r "#{libexec}/providers/codex/docs/"* "$ETIQUETTE_DIR/docs/" 2>/dev/null || true
      elif [[ "$PROVIDER" == "gemini" ]]; then
        cp -r "#{libexec}/providers/gemini/docs/"* "$ETIQUETTE_DIR/docs/" 2>/dev/null || true
      fi

      echo "{\\"provider\\": \\"$PROVIDER\\"}" > "$ETIQUETTE_DIR/config/provider.json"

      # Make executable
      chmod +x "$ETIQUETTE_DIR/hive" "$ETIQUETTE_DIR/bin/"*

      # Generate iTerm profiles (macOS)
      if [[ "$(uname)" == "Darwin" ]] && [[ -d "/Applications/iTerm.app" ]]; then
        "$ETIQUETTE_DIR/bin/generate-profiles" 2>/dev/null || true
      fi

      echo ""
      echo "✓ Etiquette initialized with provider: $PROVIDER"
      echo ""
      echo "Next steps:"
      if [[ "$PROVIDER" != "claude" ]]; then
        echo "  1. Start the launch daemon: .etiquette/bin/hive-launch-daemon"
        echo "  2. Assign tasks: .etiquette/hive task kai 'Build feature'"
        echo "  3. Launch crew: .etiquette/hive launch haack"
      else
        echo "  1. In Claude Code: /etiquette:hive-bootstrap"
      fi
      echo ""
    EOS

    chmod 0755, bin/"etiquette"
  end

  def caveats
    <<~EOS
      Etiquette v#{version} installed!

      QUICK START:
        cd your-project
        etiquette --provider codex

      FOR CLAUDE CODE USERS:
        etiquette
        Then in Claude Code: /etiquette:hive-bootstrap

      FOR CODEX/GEMINI USERS:
        etiquette -p codex
        Then start daemon: .etiquette/bin/hive-launch-daemon

      DOCUMENTATION:
        https://github.com/leepickdev/etiquette
    EOS
  end

  test do
    system bin/"etiquette", "--help"
  end
end