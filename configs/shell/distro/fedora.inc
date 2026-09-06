# Fedora / dnf-specific aliases for GarudaRice
alias upd='sudo dnf upgrade --refresh'
alias cleanup='sudo dnf autoremove'
alias rmpkg='sudo dnf remove'

if command -v dnf >/dev/null 2>&1; then
  alias big="dnf repoquery --userinstalled --qf '%{size}\t%{name}' 2>/dev/null | sort -h | tail -50"
fi
