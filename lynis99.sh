#!/bin/bash

#######################################################################################
### USE AT YOUR OWN RISK!
### This script is intended to increase security on a fresh install of Debian Bullseye,
### but it may cause unintended consequences, including decreased functionality,
### volatile runtimes and crashing. You may want test this in a virtual machine!
#######################################################################################

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi
apt-get install -y acct aide apt-listbugs apt-listchanges apt-show-versions apt-transport-https arpon arpwatch auditd bleachbit chkrootkit clamav clamtk debsums fail2ban gufw john john-data libapache2-mod-evasive libapache2-mod-security2 libpam-cracklib libpam-tmpdir lynis menu needrestart net-tools nmap puppet resolvconf ssh-audit sysstat sysstat tiger trash-cli tripwire ufw usbguard

#fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#core dump
sed -i '/soft    core/s/#//' /etc/security/limits.conf
echo "* hard core 0" >> /etc/security/limits.conf

#/etc/login.defs
sed -i 's/022/027/;s/99999/180/;s/MIN_DAYS	0/MIN_DAYS	7/;/LOGIN_RETRIES/s/5/3/;/CRYPT_MIN/s/#//;/CRYPT_MIN/s/5/25/;/CRYPT_MAX/s/#//;/CRYPT_MAX/s/000/0000/' /etc/login.defs
sed -i 's/ SHA/SHA/' /etc/login.defs
passwd -n 15 -x 90 ${SUDO_USER}
chmod 400 -R /etc/sudoers.d

#modprobe
echo "install dccp /bin/true" > /etc/modprobe.d/dccp.conf
echo "install sctp /bin/true" > /etc/modprobe.d/sctp.conf
echo "install rds /bin/true" > /etc/modprobe.d/rds.conf
echo "install tipc /bin/true" > /etc/modprobe.d/tipc.conf
echo "install freevxfs /bin/true" > /etc/modprobe.d/freevxfs.conf
echo "install hfs /bin/true" > /etc/modprobe.d/hfs.conf
echo "install hfsplus /bin/true" > /etc/modprobe.d/hfsplus.conf
echo "install jffs2 /bin/true" > /etc/modprobe.d/jffs2.conf
echo "install squashfs /bin/true" > /etc/modprobe.d/squashfs.conf
echo "install udf /bin/true" > /etc/modprobe.d/udf.conf
echo "blacklist dccp" > /etc/modprobe.d/blacklist-rare.conf
echo "blacklist sctp" >> /etc/modprobe.d/blacklist-rare.conf
echo "blacklist tipc" >> /etc/modprobe.d/blacklist-rare.conf
echo "blacklist rds" >> /etc/modprobe.d/blacklist-rare.conf
echo "blacklist firewire-core" > /etc/modprobe.d/firewire.conf
echo "blacklist freevxfs" > /etc/modprobe.d/blacklist-fs.conf
echo "blacklist hfs" >> /etc/modprobe.d/blacklist-fs.conf
echo "blacklist hfsplus" >> /etc/modprobe.d/blacklist-fs.conf
echo "blacklist jffs2" >> /etc/modprobe.d/blacklist-fs.conf
echo "blacklist squashfs" >> /etc/modprobe.d/blacklist-fs.conf
echo "blacklist udf" >> /etc/modprobe.d/blacklist-fs.conf
modprobe -rb freevxfs
modprobe -rb hfs
modprobe -rb hfsplus
modprobe -rb jffs2
modprobe -rb squashfs
modprobe -rb udf
modprobe -rb dccp
modprobe -rb sctp
modprobe -rb rds
modprobe -rb tipc
modprobe -rb firewire-core

#file permissions
chmod 700 -R $(ls -l /etc | grep cron | grep -v '^-' | sed 's/.* //;s/^/\/etc\//' | tr -s '\n' ' ')
chmod 600 /etc/crontab
chmod 600 /etc/ssh/sshd_config
chmod 600 /boot/grub/grub.cfg

#auditd update rules
cp -f ar2 /etc/audit/rules.d/audit.rules
systemctl enable auditd
systemctl start auditd

#compilers
chmod 600 $(ls -l /usr/bin | grep gcc | grep -v '^l' | sed 's/.* //' | tr -s '\n' ' ')
chmod 600 /usr/bin/x86_64-linux-gnu-as

#arpwatch
systemctl enable arpwatch
systemctl start arpwatch
#sysstat
systemctl enable sysstat
systemctl start sysstat

#CUPS
sed -i /run/s/^/#/ /etc/cups/cupsd.conf
chmod 400 /etc/cups/cupsd.conf

#external logging
mkdir /files
mkdir /files/var
mkdir /files/var/log
rsync -a /var/log /files/var
rm -rf /var/log
ln -s /files/var/log /var

#legal banner
echo "Attention, by continuing to connect to this system, you consent to the owner storing a log of all activity. Unauthorized access is prohibited." | tee /etc/issue{,.net}

#sshd
sed -i '/AllowTcpForwarding/s/#//;/AllowTcpForwarding/s/yes/no/;/ClientAliveCountMax/s/#//;/ClientAliveCountMax/s/3/2/;/Compression/s/#//;/Compression/s/delayed/no/;/LogLevel/s/#//;/LogLevel/s/INFO/VERBOSE/;/MaxAuthTries/s/#//;/MaxAuthTries/s/6/3/;/MaxSessions/s/#//;/MaxSessions/s/10/2/;/Port/s/#//;/Port/s/22/1001/;/TCPKeepAlive/s/#//;/TCPKeepAlive/s/yes/no/;/X11Forwarding/s/#//;/X11Forwarding/s/yes/no/;/AllowAgentForwarding/s/#//;/AllowAgentForwarding/s/yes/no/' /etc/ssh/sshd_config
sed -i 's/	/#/;s/##/#/' /etc/ssh/sshd_config

#trash
trash-empty
rm /home/${SUDO_USER}/.local/share/Trash/expunged/*
rm /home/${SUDO_USER}/.local/share/Trash/files/*
rm /home/${SUDO_USER}/.local/share/Trash/info/*
rm -rf /home/${SUDO_USER}/.local/share/Trash/expunged/*
rm -rf /home/${SUDO_USER}/.local/share/Trash/files/*
rm -rf /home/${SUDO_USER}/.local/share/Trash/info/*

#tmpfs>/tmp, hidepid>proc
echo "tmpfs /tmp tmpfs rw,mode=1777,size=4g 0 0" >> /etc/fstab
echo "proc /proc proc hidepid=2 0 0" >> /etc/fstab

#grub pbkdf2 password
clear
echo "Ok. Here comes the tricky part..."
echo ""
echo "After pressing [Return] to continue, you'll be establishing a GRUB username and password to be entered at boot, before your operating system is mounted."
echo "Your username will be visible as you type it, but your password will not be."
echo "Be sure to enter the password correctly, as not doing so will lock you out of your system."
echo ""
declare q="n";
read -p "Continue? [y/n]: " q
if [ $q == 'n' ]||[ $q == 'N' ]; then
exit

clear
declare loggin="";
read -p "Username?: " loggin
echo "cat <<EOF" >> /etc/grub.d/00_header
printf "%sset superusers=\"${loggin}\"\npassword_pbkdf2 ${loggin} " >> /etc/grub.d/00_header

echo "Enter password twice and press [Return] after each entry: "
printf $(grub-mkpasswd-pbkdf2 | sed -n '3p' | cut -c 33-) >> /etc/grub.d/00_header
echo "" >> /etc/grub.d/00_header
echo "EOF" >> /etc/grub.d/00_header
update-grub

clear
declare rebo="n";
read -p "Done! Reboot now? [y/n]" rebo
if [ $rebo == 'y' ]||[ $rebo == 'Y' ]; then
reboot
