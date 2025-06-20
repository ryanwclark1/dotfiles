[38;2;198;208;245m#\!/bin/bash[0m
[38;2;198;208;245mset -x[0m
[38;2;198;208;245mlog() { echo "[$1] $2"; }[0m

[38;2;198;208;245minstall_claude() {[0m
[38;2;198;208;245m    log "INFO" "Checking Claude Code installation..."[0m
[38;2;198;208;245m    [0m
[38;2;198;208;245m    # Check if Claude Code is already installed[0m
[38;2;198;208;245m    if command -v claude &>/dev/null; then[0m
[38;2;198;208;245m        log "INFO" "Claude Code is already installed"[0m
[38;2;198;208;245m        log "INFO" "Current version: $(claude --version 2>/dev/null || echo 'unknown')"[0m
[38;2;198;208;245m        log "INFO" "Location: $(which claude)"[0m
[38;2;198;208;245m        [0m
[38;2;198;208;245m        # Skip npm installation if Claude is installed via system package manager[0m
[38;2;198;208;245m        if [[ "$(which claude)" == /nix/* ]] || [[ "$(which claude)" == /usr/* ]]; then[0m
[38;2;198;208;245m            log "INFO" "Claude Code is installed via system package manager, skipping npm installation"[0m
[38;2;198;208;245m            return[0m
[38;2;198;208;245m        fi[0m
[38;2;198;208;245m        [0m
[38;2;198;208;245m        read -p "Do you want to reinstall/update via npm? (y/N): " -n 1 -r[0m
[38;2;198;208;245m        echo[0m
[38;2;198;208;245m        if [[ \! $REPLY =~ ^[Yy]$ ]]; then[0m
[38;2;198;208;245m            return[0m
[38;2;198;208;245m        fi[0m
[38;2;198;208;245m    fi[0m
[38;2;198;208;245m}[0m

[38;2;198;208;245minstall_claude[0m
