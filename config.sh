#!/usr/bin/env bash

#created by mattrattus
#v1.0

echo
echo -e "\033[36m<<<<<===== ------------------------ =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Change the root password =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ------------------------ =====>>>>>\033[0m"
echo
passwd

echo
echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Local config =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
echo
timedatectl set-timezone Europe/Warsaw
localectl set-keymap pl
cp /etc/locale.conf /etc/locale.conf_backup
echo 'LANG=en_US.UTF-8
LC_MESSAGES="C"
LC_ADDRESS="pl_PL.UTF-8"
LC_IDENTIFICATION="pl_PL.UTF-8"
LC_MEASUREMENT="pl_PL.UTF-8"
LC_MONETARY="pl_PL.UTF-8"
LC_NAME="pl_PL.UTF-8"
LC_NUMERIC="pl_PL.UTF-8"
LC_PAPER="pl_PL.UTF-8"
LC_TELEPHONE="pl_PL.UTF-8"
LC_TIME="pl_PL.UTF-8"' > /etc/locale.conf
echo "success"

echo
echo -e "\033[36m<<<<<===== ------ =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Update =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ------ =====>>>>>\033[0m"
echo
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf_backup
echo "max_parallel_downloads=5" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
dnf check-update
dnf -y upgrade

echo
echo -e "\033[36m<<<<<===== -------------------------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Installing additional repo =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== -------------------------- =====>>>>>\033[0m"
echo
dnf -y install epel-release
dnf -y install http://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf check-update
dnf -y upgrade

echo
echo -e "\033[36m<<<<<===== ------------------------------ =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Installing additional software =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ------------------------------ =====>>>>>\033[0m"
echo
dnf -y install fail2ban fail2ban-firewalld firewalld git glibc-langpack-pl policycoreutils-python-utils rkhunter vim zsh htop rsync tar util-linux-user dnf-utils
systemctl enable --now fail2ban

echo
echo -e "\033[36m<<<<<===== ----------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== sshd config =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ----------- =====>>>>>\033[0m"
echo
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup
vim -c '%s/#Port 22/Port 22122/g | %s/#PasswordAuthentication yes/PasswordAuthentication no/g | %s/#PermitEmptyPasswords no/PermitEmptyPasswords no' /etc/ssh/sshd_config
semanage port -a -t ssh_port_t -p tcp 22122
systemctl restart sshd
echo "success"

echo
echo -e "\033[36m<<<<<===== ---------------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== firewalld config =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ---------------- =====>>>>>\033[0m"
echo
systemctl enable --now firewalld
firewall-cmd --remove-service=ssh
firewall-cmd --remove-service=cockpit
firewall-cmd --add-port=22122/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
firewall-cmd --list-services
firewall-cmd --list-port
cp /etc/firewalld/firewalld.conf /etc/firewalld/firewalld.conf_backup

echo
echo -e "\033[36m<<<<<===== --------------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== fail2ban config =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== --------------- =====>>>>>\033[0m"
echo
touch /etc/fail2ban/jail.d/sshd.local
systemctl reload fail2ban
echo "[sshd]

enabled = true
mode = normal
port = ssh,22,22122
bantime = 86400
findtime = 600
maxretry = 2
logpath = %(sshd_log)s" > /etc/fail2ban/jail.d/sshd.local
sleep 2s && systemctl reload fail2ban
fail2ban-client status
fail2ban-client status sshd

echo
echo -e "\033[36m<<<<<===== --------------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== rkhunter config =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== --------------- =====>>>>>\033[0m"
echo
rkhunter -C
rkhunter --update
rkhunter --propupd

echo
echo -e "\033[36m<<<<<===== ------------------------ =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Add and config sudo user =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== ------------------------ =====>>>>>\033[0m"
echo
read -p "User name: " user_sudo
useradd -m -G wheel $user_sudo
passwd $user_sudo
mkdir /home/$user_sudo/.ssh
touch /home/$user_sudo/.ssh/authorized_keys
chown $user_sudo:$user_sudo /home/$user_sudo/.ssh /home/$user_sudo/.ssh/authorized_keys
vim /home/$user_sudo/.ssh/authorized_keys

echo
echo -e "\033[36m<<<<<===== -------------------------------------------- =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== Add ansible user? /// 'Y'es /// /// 'N'o /// =====>>>>>\033[0m"
echo -e "\033[36m<<<<<===== -------------------------------------------- =====>>>>>\033[0m"
echo
read -p "Add?: " ansible_user
echo "You've decided: "$ansible_user

if [[ $ansible_user = Y ]]; then
    useradd -m -G wheel ansible
    passwd ansible
    mkdir /home/ansible/.ssh
    touch /home/ansible/.ssh/authorized_keys
    chown ansible:ansible /home/ansible/.ssh /home/ansible/.ssh/authorized_keys
    vim /home/ansible/.ssh/authorized_keys

    echo
    echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
    echo -e "\033[36m<<<<<===== Final config =====>>>>>\033[0m"
    echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
    echo
    shred -zun 1 config.sh
    echo "success"
    echo

elif [[ $ansible_user = N ]]; then
    echo
    echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
    echo -e "\033[36m<<<<<===== Final config =====>>>>>\033[0m"
    echo -e "\033[36m<<<<<===== ------------ =====>>>>>\033[0m"
    echo
    shred -zun 1 config.sh
    echo "success"
    echo

fi
