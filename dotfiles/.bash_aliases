alias vpn='openconnect -u sag47 -s /etc/vpnc/vpnc-script https://vpn.drexel.edu/'
alias vpntest='openconnect -u sag47 -s /etc/vpnc/vpnc-script -g IRT-Private https://vpntest.drexel.edu/'

#more aliases
#alias ls='ls -lah --color=auto'
alias ls='ls --color=auto'
alias ssh='ssh -C'
alias df='df -h'
alias du='du -shc'
alias amarokbackupdb='mysqldump --add-drop-table -u amarokuser -pamarok amarokdb > ~/Documents/amarok-backup.sql'
alias firefoxvacuum='echo "sqlite3 VACUUM and REINDEX on firefox";for x in `find ~ -type f -name *.sqlite* | grep firefox`;do echo "$x";sqlite3 $x VACUUM;sqlite3 $x REINDEX;done'
alias tux='ssh -C sag47@tux.cs.drexel.edu'
alias x='exit'
#alias cp='rsync -ruptv'
alias irc_rizon='ssh -p23 -f sag47@home.gleske.net -L
1025:irc.rizon.net:6667 -N'
alias irc_freenode='ssh -p23 -f sag47@home.gleske.net -L
1024:irc.freenode.net:6667 -N'
alias vnc_tunnel='ssh -p23 -f sag47@home.gleske.net -L 2000:localhost:5902 -N'
alias vnc_connect='ssvncviewer -passwd /home/sam/.vnc/passwd localhost:2000'
alias vnc_kill_tunnel='/home/sam/.vnc/killtunnel.sh'
alias vnc_tunnel_internal='ssh -p23 -f sag47@home.gleske.net -L 2001:hda.home:5902 -N'
alias bzflag_connect='bzflag -window -geometry 1024x768'
alias wychcraft='xfreerdp -u sag47 -d drexel -g 1260x965 wychcraft.irt.drexel.edu'
alias rdp_tunnel='ssh -f sag47@home.gleske.net -L 2003:etherbeast.home:3389 -N && echo $!'
alias rdp_connect='xfreerdp -t 2003 -u sam -g 1024x768 localhost'
#alias servercount="echo $((`sed '1d' /etc/clusters | grep -v '^$' | wc -w`-`sed '1d' /etc/clusters | grep -v '^$' | wc -l`))"
