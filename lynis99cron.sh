#!/bin/bash
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi
systemctl enable sysstat
systemctl start sysstat
systemctl start arpon
systemctl start arpwatch
cat /root/.bash_history >> /files/.root_bash_history
cat /home/${SUDO_USER}/.bash_history >> /files/.home_bash_history
echo "" | tee /root/.bash_history /home/${SUDO_USER}/.bash_history
rsync -a /var/log /files/var
sysctl dev.tty.ldisc_autoload=0
sysctl fs.protected_fifos=2
sysctl kernel.core_uses_pid=1
sysctl kernel.kptr_restrict=2
sysctl kernel.modules_disabled=0
sysctl kernel.sysrq=1
sysctl kernel.unprivileged_bpf_disabled=1
sysctl kernel.yama.ptrace_scope=1
sysctl net.core.bpf_jit_harden=2
sysctl net.ipv4.conf.all.accept_redirects=0
sysctl net.ipv4.conf.all.log_martians=1
sysctl net.ipv4.conf.all.rp_filter=1
sysctl net.ipv4.conf.all.send_redirects=0
sysctl net.ipv4.conf.default.accept_redirects=0
sysctl net.ipv4.conf.default.accept_source_route=0
sysctl net.ipv4.conf.default.log_martians=1
sysctl net.ipv6.conf.all.accept_redirects=0
sysctl net.ipv6.conf.default.accept_redirects=0

clear
rm /home/${SUDO_USER}/.local/share/gvfs-metadata/* /dev/shm/* /tmp/user/1000/* 2> /dev/null
aptitude purge
clear
apt-get purge $(apt list | grep 'residual-config' | sed 's/\/.*//' | tr -s '\n' ' ') 2> /dev/null
clear
apt-get autoremove
clear
apt-get update && apt-get upgrade -y
clear
#aide --check --config /etc/aide/aide.conf
read -p '...' x
