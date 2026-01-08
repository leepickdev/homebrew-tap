class Etiquette < Formula
  desc "Multi-LLM agent swarms with Claude, Codex, or Gemini"
  homepage "https://github.com/leepickdev/etiquette"
  url "https://github.com/leepickdev/etiquette/archive/refs/tags/v1.0.0.tar.gz"
  sha256 :no_check  # Updated by release workflow
  license "MIT"

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
    (bin/"etiquette-init").write <<~EOS
      #!/bin/bash
      # Initialize etiquette in current project
      set -e

      ETIQUETTE_DIR=".etiquette"

      if [[ -d "$ETIQUETTE_DIR" ]]; then
        echo "Etiquette already initialized in this project"
        exit 0
      fi

      echo "Initializing Etiquette in $(pwd)..."

      # Create directory structure
      mkdir -p "$ETIQUETTE_DIR"/{bin,config,status,tasks,context,queue,registry,docs}

      # Copy scripts from libexec
      cp "#{libexec}/.etiquette/hive" "$ETIQUETTE_DIR/"
      cp "#{libexec}/.etiquette/bin/"* "$ETIQUETTE_DIR/bin/"

      # Detect provider and copy appropriate docs
      if command -v claude &>/dev/null; then
        PROVIDER="claude"
      elif command -v codex &>/dev/null; then
        PROVIDER="codex"
        cp -r "#{libexec}/providers/codex/docs/"* "$ETIQUETTE_DIR/docs/" 2>/dev/null || true
      elif command -v gemini &>/dev/null; then
        PROVIDER="gemini"
        cp -r "#{libexec}/providers/gemini/docs/"* "$ETIQUETTE_DIR/docs/" 2>/dev/null || true
      else
        PROVIDER="claude"
      fi

      echo "{\\"provider\\": \\"$PROVIDER\\"}" > "$ETIQUETTE_DIR/config/provider.json"

      # Make executable
      chmod +x "$ETIQUETTE_DIR/hive" "$ETIQUETTE_DIR/bin/"*

      # Generate iTerm profiles (macOS)
      if [[ "$(uname)" == "Darwin" ]] && [[ -d "/Applications/iTerm.app" ]]; then
        "$ETIQUETTE_DIR/bin/generate-profiles" 2>/dev/null || true
      fi

      echo ""
      echo "Etiquette initialized with provider: $PROVIDER"
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

    chmod 0755, bin/"etiquette-init"
  end

  def caveats
    <<~EOS
      Etiquette v#{version} installed!

      QUICK START:
        cd your-project
        etiquette-init

      FOR CLAUDE CODE USERS:
        Skills installed at: #{share}/etiquette/skills/
        Use /etiquette:hive-bootstrap to set up your swarm

      FOR CODEX/GEMINI USERS:
        After init, start the launch daemon in a separate terminal:
        .etiquette/bin/hive-launch-daemon

      DOCUMENTATION:
        https://github.com/leepickdev/etiquette
    EOS
  end

  test do
    system bin/"etiquette-init", "--help"
  end
end