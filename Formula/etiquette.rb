class Etiquette < Formula
  desc "Multi-agent swarm orchestration for Codex and Gemini CLIs"
  homepage "https://github.com/leepickdev/etiquette"
  version "1.1.0"
  license "AGPL-3.0"

  head do
    url "https://github.com/leepickdev/etiquette.git", branch: "main", using: :git
  end

  depends_on "tmux"
  depends_on "jq"

  def install
    (libexec/"bin").mkpath
    cp_r Dir["core/bin/*"], libexec/"bin/"
    cp "templates/hive", libexec/"hive"
    (libexec/"providers").install Dir["providers/*"]
    (libexec/"skills").install Dir["skills/*"]
    cp "bootstrap.sh", libexec/"bootstrap.sh"

    (bin/"etiquette").write <<~EOS
      #!/bin/bash
      set -e
      ETIQUETTE_LIBEXEC="#{libexec}"
      ETIQUETTE_DIR=".etiquette"

      show_help() {
        echo "Etiquette v1.1.0 - Multi-agent swarm orchestration"
        echo ""
        echo "Usage: etiquette <command> [options]"
        echo ""
        echo "Commands:"
        echo "  init [--provider codex|gemini]  Initialize in current project"
        echo "  refresh                         Update skills only (fast)"
        echo "  spawn                           Spawn agent crew"
        echo "  status                          Show agent status"
        echo "  help                            Show this help"
        echo ""
        echo "Examples:"
        echo "  cd your-project"
        echo "  tmux new -s etiquette"
        echo "  etiquette init --provider codex"
        echo "  etiquette spawn"
      }

      cmd_init() {
        local PROVIDER="" FORCE=false
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --provider|-p) PROVIDER="$2"; shift 2 ;;
            --force|-f) FORCE=true; shift ;;
            *) shift ;;
          esac
        done
        if [[ -d "$ETIQUETTE_DIR" ]] && [[ "$FORCE" == false ]]; then
          echo "✓ Etiquette already initialized"
          echo "  Use 'etiquette refresh' to update skills"
          echo "  Use 'etiquette init --force' to reinitialize"
          exit 0
        fi
        echo "Initializing Etiquette..."
        mkdir -p "$ETIQUETTE_DIR"/{bin,config,status,tasks,state,queue,registry,docs}
        cp "$ETIQUETTE_LIBEXEC/hive" "$ETIQUETTE_DIR/"
        cp "$ETIQUETTE_LIBEXEC/bin/"* "$ETIQUETTE_DIR/bin/"
        [[ -z "$PROVIDER" ]] && { command -v codex &>/dev/null && PROVIDER="codex" || PROVIDER="gemini"; }
        local SKILLS_DIR=".$PROVIDER/skills"
        mkdir -p "$SKILLS_DIR"
        cp -r "$ETIQUETTE_LIBEXEC/skills/"* "$SKILLS_DIR/"
        echo "{\\"provider\\": \\"$PROVIDER\\", \\"version\\": \\"1.1.0\\"}" > "$ETIQUETTE_DIR/config/provider.json"
        chmod +x "$ETIQUETTE_DIR/hive" "$ETIQUETTE_DIR/bin/"* 2>/dev/null || true
        echo "✓ Etiquette initialized (provider: $PROVIDER)"
        echo "  Next: tmux new -s etiquette && etiquette spawn"
      }

      cmd_refresh() {
        [[ ! -d "$ETIQUETTE_DIR" ]] && { echo "Run 'etiquette init' first"; exit 1; }
        local PROVIDER=$(grep -o '"provider"[^,]*' "$ETIQUETTE_DIR/config/provider.json" | cut -d'"' -f4)
        PROVIDER="${PROVIDER:-codex}"
        cp -r "$ETIQUETTE_LIBEXEC/skills/"* ".$PROVIDER/skills/"
        cp "$ETIQUETTE_LIBEXEC/bin/"* "$ETIQUETTE_DIR/bin/"
        echo "✓ Skills refreshed for $PROVIDER"
      }

      cmd_spawn() {
        [[ ! -x "$ETIQUETTE_DIR/hive" ]] && { echo "Run 'etiquette init' first"; exit 1; }
        exec "$ETIQUETTE_DIR/hive" spawn "$@"
      }

      cmd_status() {
        [[ ! -x "$ETIQUETTE_DIR/hive" ]] && { echo "Run 'etiquette init' first"; exit 1; }
        exec "$ETIQUETTE_DIR/hive" status "$@"
      }

      case "${1:-help}" in
        init)    shift; cmd_init "$@" ;;
        refresh) shift; cmd_refresh "$@" ;;
        spawn)   shift; cmd_spawn "$@" ;;
        status)  shift; cmd_status "$@" ;;
        help|--help|-h) show_help ;;
        *) echo "Unknown: $1. Run 'etiquette help'"; exit 1 ;;
      esac
    EOS
    chmod 0755, bin/"etiquette"
  end

  def caveats
    <<~EOS
      Etiquette v1.1.0 installed!

      QUICK START:
        cd your-project
        tmux new -s etiquette
        etiquette init --provider codex
        etiquette spawn

      COMMANDS:
        etiquette init      Initialize project
        etiquette refresh   Update skills (fast)
        etiquette spawn     Spawn agent crew
        etiquette status    Show agent status

      DOCS: https://github.com/leepickdev/etiquette
    EOS
  end

  test do
    system bin/"etiquette", "help"
  end
end
