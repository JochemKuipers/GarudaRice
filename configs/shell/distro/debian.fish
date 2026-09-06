# Debian / apt-specific aliases (fish)
alias upd 'sudo apt update && sudo apt upgrade'
alias cleanup 'sudo apt autoremove --purge'
alias rmpkg 'sudo apt remove'
alias fixapt 'sudo dpkg --configure -a; sudo apt -f install'
