# Debian / apt-specific aliases for GarudaRice
alias upd='sudo apt update && sudo apt upgrade'
alias cleanup='sudo apt autoremove --purge'
alias rmpkg='sudo apt remove'
alias fixapt='sudo dpkg --configure -a; sudo apt -f install'

if command -v apt >/dev/null 2>&1; then
  alias big="dpkg-query -Wf '\${Installed-Size}\t\${Package}\n' | sort -n | tail -50"
fi
