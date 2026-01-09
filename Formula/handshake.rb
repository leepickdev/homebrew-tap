class Handshake < Formula
  desc "Multi-agent swarm orchestration for parallel development with Claude Code"
  homepage "https://github.com/leepickdev/handshake"
  # Private repo - requires HOMEBREW_GITHUB_API_TOKEN for org members
  url "https://github.com/leepickdev/handshake/archive/refs/tags/v2.0.0.tar.gz"
  sha256 :no_check  # Will be updated by release workflow
  license "MIT"

  # Note: This formula requires access to leepickdev/handshake (private repo)
  # Set HOMEBREW_GITHUB_API_TOKEN with a token that has repo access

  depends_on "python@3.11"

  def install
    # Create directories
    libexec.install "daemon/src/handshaked.py"
    libexec.install "daemon/src/services"
    libexec.install "daemon/requirements.txt"

    # Install .handshake-template scripts (renamed from .handshake for distribution)
    (libexec/".handshake").mkpath
    cp buildpath/".handshake-template/hive", libexec/".handshake/hive"
    (libexec/".handshake/bin").mkpath
    cp_r Dir[buildpath/".handshake-template/bin/*"], libexec/".handshake/bin/"
    (libexec/".handshake/config").mkpath
    cp buildpath/".handshake-template/config/swarm.json", libexec/".handshake/config/"

    # Install skills for Claude plugin
    (share/"handshake/skills").install Dir["skills/*"]

    # Install hooks
    (share/"handshake/hooks").install Dir["hooks/*"]

    # Create Python virtual environment
    venv = libexec/"venv"
    system "python3.11", "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "-r", libexec/"requirements.txt"

    # Create wrapper scripts
    (bin/"handshaked").write <<~EOS
      #!/bin/bash
      exec "#{venv}/bin/python" "#{libexec}/handshaked.py" "$@"
    EOS

    (bin/"hive-client").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/.handshake/bin/hive-client" "$@"
    EOS

    (bin/"handshake-init").write <<~EOS
      #!/bin/bash
      # Initialize handshake in current project
      set -e

      HANDSHAKE_DIR=".handshake"

      if [[ -d "$HANDSHAKE_DIR" ]]; then
        echo "Handshake already initialized in this project"
        exit 0
      fi

      echo "Initializing Handshake in $(pwd)..."

      # Create directory structure
      mkdir -p "$HANDSHAKE_DIR"/{bin,config,status,tasks,context,queue,registry,snapshots}

      # Copy scripts from libexec
      cp "#{libexec}/.handshake/hive" "$HANDSHAKE_DIR/"
      cp "#{libexec}/.handshake/bin/"* "$HANDSHAKE_DIR/bin/"
      cp "#{libexec}/.handshake/config/swarm.json" "$HANDSHAKE_DIR/config/"

      # Make executable
      chmod +x "$HANDSHAKE_DIR/hive" "$HANDSHAKE_DIR/bin/"*

      # Initialize shared context
      echo "# Hive Shared Memory" > "$HANDSHAKE_DIR/context/SHARED.md"
      echo "" >> "$HANDSHAKE_DIR/context/SHARED.md"
      echo "Cross-agent knowledge base. Agents log discoveries here." >> "$HANDSHAKE_DIR/context/SHARED.md"

      # Generate iTerm profiles (macOS)
      if [[ "$(uname)" == "Darwin" ]] && [[ -d "/Applications/iTerm.app" ]]; then
        "$HANDSHAKE_DIR/bin/generate-profiles" 2>/dev/null || true
      fi

      echo ""
      echo "Handshake initialized!"
      echo ""
      echo "Next steps:"
      echo "  1. Ensure daemon is running: brew services start handshake"
      echo "  2. Launch a crew: hive-client crew launch haack --tier haiku --mode auto"
      echo "  3. Or use Claude Code: /handshake:hive-bootstrap"
      echo ""
    EOS

    chmod 0755, bin/"handshaked"
    chmod 0755, bin/"hive-client"
    chmod 0755, bin/"handshake-init"
  end

  def caveats
    <<~EOS
      Handshake v#{version} installed!

      QUICK START:
        1. Start the daemon:
           brew services start handshake

        2. Initialize in your project:
           cd your-project
           handshake-init

        3. Launch a crew:
           hive-client crew launch haack --tier haiku --mode auto

      FOR CLAUDE CODE USERS:
        Install the plugin, then use /handshake:hive-bootstrap
        Skills installed at: #{share}/handshake/skills/

      DOCUMENTATION:
        https://github.com/leepickdev/handshake

      DAEMON LOGS:
        #{var}/log/handshake.log
    EOS
  end

  service do
    run [opt_bin/"handshaked"]
    keep_alive true
    log_path var/"log/handshake.log"
    error_log_path var/"log/handshake.log"
    working_dir HOMEBREW_PREFIX
  end

  test do
    # Start daemon briefly to test
    pid = fork do
      exec bin/"handshaked"
    end
    sleep 3

    # Check health endpoint
    output = shell_output("curl -s http://localhost:5757/health")
    assert_match "healthy", output

    Process.kill("TERM", pid)
  end
end
