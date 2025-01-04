# If not run interactively, don't do anything.
case $- in
    *i*) ;;
      *) return;;
esac

# Do colored prompt even for root
# Sadly, this will not apply to other users as they have a prompt set in their ~/.bashrc.
# Consider disabling it there to get this prompt.
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac
if [ "$color_prompt" = yes ]; then
    if [ "$(id -u)" -eq 0 ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]$(RET=$?; if [[ $RET != 0 ]]; then echo "$RET "; fi)\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}$(RET=$?; if [[ $RET != 0 ]]; then echo "\[\033[01;31m\]$RET "; fi)\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}$(RET=$?; if [[ $RET != 0 ]]; then echo "$RET "; fi)\u@\h:\w\$ '
fi

alias ls="ls --color=auto"
alias grep="grep --color=auto"

alias la="ls -A"
alias ll="ls -lh"

# improved lsblk. Shows label and model name
alias lsdsk="lsblk -o NAME,SIZE,FSUSE%,PTTYPE,FSTYPE,PARTTYPENAME,MOUNTPOINTS,LABEL,UUID,MODEL"

# command I used to find broken files in share
find_corrupt() {
    if [ $# -eq 0 ]; then
        find_corrupt .
    else
        # find "$1" -type f -print0 | xargs -0 file | grep ": data"
        # find "$1" -type f -exec file {} \; | grep ": data"
        # find "$1" -type f | while read -r file; do
        fdfind -t f ".*" "$1" | while read -r file; do
            if file "$file" | grep -q ": data"; then
                if [[ "$file" == *".bin" ]]; then continue; fi # General binary files
                if [[ "$file" == *".pak" ]]; then continue; fi # Installer files
                if [[ "$file" == *".inx" ]]; then continue; fi # Installer files
                if [[ "$file" == *".D64" ]]; then continue; fi # Commodore 64 disk images
                if [[ "$file" == *".v64" ]]; then continue; fi # Nintendo 64 ROMs
                if [[ "$file" == *".z64" ]]; then continue; fi # Nintendo 64 ROMs
                if [[ "$file" == *".gba" ]]; then continue; fi # Gameboy Advance ROMs
                if [[ "$file" == *".sgm" ]]; then continue; fi # Save states
                if [[ "$file" == *".nds" ]]; then continue; fi # Nintendo DS ROMs
                if [[ "$file" == *".opt" ]]; then continue; fi # ?? rom
                if [[ "$file" == *".is0" ]]; then continue; fi # ?? rom
                if [[ "$file" == *".sav" ]]; then continue; fi # Save files
                if [[ "$file" == *".nes" ]]; then continue; fi # Nintendo Entertainment System ROMs
                if [[ "$file" == *".smc" ]]; then continue; fi # Super Nintendo Entertainment System ROMs
                if 7z l "$file" &>/dev/null; then continue; fi
                echo "$file"
            fi
        done
    fi
}

# alias funktioniert nicht in sowas wie `sudo ll`
# Trick: sudo selbst als alias definieren: https://wiki.archlinux.org/title/Sudo#Passing_aliases
alias sudo="sudo "
alias watch="watch "

# Mouse-Scrolling in less (und dann auch in man)
#   Deaktiviert, da es einfaches Kopieren aus Less verhindert.
#   Theoretisch wäre das mit Shift-Mousedrag noch möglich, aber muss man wissen.
#   Kann in Less durch Tippen von '--mouse' aktiviert werden.
# export LESS='--mouse --wheel-lines=3'
