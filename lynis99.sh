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
apt-get install -y acct aptitude apt-listbugs apt-listchanges apt-show-versions apt-transport-https arpon arpwatch auditd autolog bleachbit chkrootkit clamav clamtk clamav-daemon debsums fail2ban john john-data libapache2-mod-evasive libapache2-mod-security2 libpam-tmpdir libpam-passwdqc lynis menu needrestart net-tools nmap puppet resolvconf rsync ssh-audit sysstat sysstat tiger trash-cli tripwire ufw usbguard iptables-persistent
apt-get install -y aide

#fail2ban backup config
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#core dump
sed -i '/soft    core/s/#//' /etc/security/limits.conf
echo "* hard core 0" >> /etc/security/limits.conf
echo 'ulimit -c 0' >> /etc/profile

#/etc/login.defs
sed -i 's/022/027/;s/99999/180/;s/MIN_DAYS	0/MIN_DAYS	7/;/LOGIN_RETRIES/s/5/3/;/CRYPT_MIN/s/#//;/CRYPT_MIN/s/5/25/;/CRYPT_MAX/s/#//;/CRYPT_MAX/s/000/0000/;s/ SHA/SHA/' /etc/login.defs
passwd -n 15 -x 90 ${SUDO_USER}
chmod 400 -R /etc/sudoers.d

#modprobe to disable rare protocols
for i in {dccp,sctp,rds,tipc,freevxfs,hfs,hfsplus,jffs2,udf}
do
echo "install $i /bin/true" > /etc/modprobe.d/${i}.conf
done
printf "%sblacklist dccp\nblacklist sctp\nblacklist tipc\nblacklist rds" > /etc/modprobe.d/blacklist-rare.conf
echo "blacklist firewire-core" > /etc/modprobe.d/firewire.conf
printf "%sblacklist freevxfs\nblacklist hfs\nblacklist hfsplus\nblacklist jffs2\nblacklist udf" > /etc/modprobe.d/blacklist-fs.conf
modprobe -rb freevxfs hfs hfsplus jffs2 udf dccp sctp rds tipc firewire-core

#file permissions
chmod 700 -R $(ls -l /etc | grep cron | grep -v '^-' | sed 's/.* //;s/^/\/etc\//' | tr -s '\n' ' ')
chmod 600 /etc/crontab
chmod 600 /etc/ssh/sshd_config
chmod 600 /boot/grub/grub.cfg
#dir permissions
chmod 750 /etc/sudoers.d
#compiler permissions
chmod 700 /usr/bin/x86_64-linux-gnu-as
chmod 700 /usr/bin/x86_64-linux-gnu-gc*

#auditd update rules
cp -f audit.rules /etc/audit/rules.d/audit.rules
systemctl enable auditd
systemctl start auditd
systemctl restart auditd

#compilers
chmod 700 $(ls -l /usr/bin | grep gcc | grep -v '^l' | sed 's/.* //' | tr -s '\n' ' ')
chmod 700 /usr/bin/x86_64-linux-gnu-as
chmod 700 /usr/bin/x86_64-linux-gnu-gcc-12

#arpwatch
systemctl enable arpwatch
systemctl start arpwatch
systemctl enable arpon
systemctl start arpon
chmod 750 -R /var/lib/arpalert
chown arpalert /var/lib/arpalert

#sysstat
sed -i 's/false/true/' /etc/default/sysstat
systemctl enable sysstat
systemctl start sysstat

#iptables netfilter
systemctl enable netfilter-persistent
systemctl start netfilter-persistent

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
rm /home/${SUDO_USER}/.local/share/Trash/expunged/* /home/${SUDO_USER}/.local/share/Trash/files/* /home/${SUDO_USER}/.local/share/Trash/info/*
rm -rf /home/${SUDO_USER}/.local/share/Trash/expunged/* /home/${SUDO_USER}/.local/share/Trash/files/* /home/${SUDO_USER}/.local/share/Trash/info/*

#tmpfs>/tmp, hidepid>proc
echo "tmpfs /tmp tmpfs nosuid,nodev,noatime,noexec,rw,mode=1777,size=4g 0 0" >> /etc/fstab
echo "proc /proc proc nosuid,nouser,noexec,hidepid=2 0 0" >> /etc/fstab

#new file permissions
chmod 750 /var/lib/arpalert

#create aide db
clear
read -p "Adding user _aide to allow aide to initialize. Please choose a password for user _aide..." x
adduser --allow-bad-names _aide
sed -i 's/Checksums = H/Checksums = sha512/' /etc/aide/aide.conf
aide -i --config /etc/aide/aide.conf

#alter coredump configuations
printf "%s\nProcessSizeMax=0\nStorage=none" >> /etc/systemd/coredump.conf

#usbguard
usbguard generate-policy -p
sed -i 's/Inserted.*/InsertedDevicePolicy=block/' /etc/usbguard/usbguard-daemon.conf
sed -i 's/PresentControllerPolicy=.*/PresentControllerPolicy=apply-policy/' /etc/usbguard/usbguard-daemon.conf
systemctl restart usbguard

#iptables DoS prevention, drop invalid traffic, block common vulnerable ports
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A OUTPUT -p tcp --dport 135 -j DROP
iptables -A OUTPUT -p udp --dport 135 -j DROP
iptables -A OUTPUT -p tcp --dport 137 -j DROP
iptables -A OUTPUT -p udp --dport 137 -j DROP
iptables -A OUTPUT -p tcp --dport 138 -j DROP
iptables -A OUTPUT -p udp --dport 138 -j DROP
iptables -A OUTPUT -p tcp --dport 139 -j DROP
iptables -A OUTPUT -p udp --dport 139 -j DROP
iptables -A OUTPUT -p tcp --dport 445 -j DROP
iptables -A OUTPUT -p udp --dport 69 -j DROP
iptables -A OUTPUT -p udp --dport 514 -j DROP
iptables -A OUTPUT -p udp --dport 161 -j DROP
iptables -A OUTPUT -p udp --dport 163 -j DROP
iptables -A OUTPUT -p tcp --dport 6660 -j DROP
iptables -A OUTPUT -p tcp --dport 6661 -j DROP
iptables -A OUTPUT -p tcp --dport 6662 -j DROP
iptables -A OUTPUT -p tcp --dport 6663 -j DROP
iptables -A OUTPUT -p tcp --dport 6664 -j DROP
iptables -A OUTPUT -p tcp --dport 6665 -j DROP
iptables -A OUTPUT -p tcp --dport 6666 -j DROP
iptables -A OUTPUT -p tcp --dport 6667 -j DROP
iptables -A OUTPUT -p tcp --dport 6668 -j DROP
iptables -A OUTPUT -p tcp --dport 6669 -j DROP
iptables-save

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
fi
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
fi
