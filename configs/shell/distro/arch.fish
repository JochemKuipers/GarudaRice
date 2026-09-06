# Arch / pacman-specific aliases (fish)
alias upd 'sudo pacman -Syu'
alias fixpacman 'sudo rm -f /var/lib/pacman/db.lck'
alias rmpkg 'sudo pacman -Rdd'

function cleanup
  while pacman -Qdtq
    sudo pacman -R (pacman -Qdtq)
    if test $status -eq 1
      break
    end
  end
end

alias gitpkg 'pacman -Q | grep -i -- -git | wc -l'

if type -q expac
  alias big 'expac -H M "%m\t%n" | sort -h | nl'
  alias rip 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl'
end

if type -q reflector
  alias mirror 'sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
  alias mirrord 'sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist'
  alias mirrors 'sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist'
  alias mirrora 'sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist'
end

if not test -x /usr/bin/yay; and test -x /usr/bin/paru
  alias yay 'paru'
end

alias apt 'man pacman'
alias apt-get 'man pacman'
