# Arch / pacman-specific aliases for GarudaRice
alias upd='sudo pacman -Syu'
alias fixpacman='sudo rm -f /var/lib/pacman/db.lck'
alias rmpkg='sudo pacman -Rdd'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null'
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'

if command -v expac >/dev/null 2>&1; then
  alias big="expac -H M '%m\t%n' | sort -h | nl"
  alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
fi

if command -v reflector >/dev/null 2>&1; then
  alias mirror='sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
  alias mirrord='sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist'
  alias mirrors='sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist'
  alias mirrora='sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist'
fi

if [[ ! -x /usr/bin/yay ]] && [[ -x /usr/bin/paru ]]; then
  alias yay='paru'
fi

# Friendly redirects for Debian muscle-memory
alias apt='man pacman'
alias apt-get='man pacman'
