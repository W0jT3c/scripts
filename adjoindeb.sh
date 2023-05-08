#!/bin/bash
sudo apt install sssd-ad sssd-tools realmd adcli -y
echo "Enter The Domain Name: "
read -r nazwa_domeny
echo "Enter The Login Of The User Who Has The Right To Join The Computer To The Domain: "
read -r nazwa_uzytkownika_administratora
sudo realm join -v ${nazwa_domeny} -U $nazwa_uzytkownika_administratora@${nazwa_domeny}
t_n="t"
while [[ "$t_n" == "t" ]]; do
  echo "Enter A The Name Of The Group That Should Be Allowed To Log In: "
  read -r nazwa_grupy_logowania
  echo "simple_allow_groups = ${nazwa_grupy_logowania}@${nazwa_domeny}" >> /etc/sssd/sssd.conf
  echo "Add Another Group? (t/n)"
  read t_n
done
echo "access_provider = simple" >> /etc/sssd/sssd.conf
sudo pam-auth-update --enable mkhomedir
systemctl restart sssd
t_n="t"
while [[ "$t_n" == "t" ]]; do
  echo "Enter The Name Of The Group That Should Be In The Sudo Group: "
  read nazwa_grupy_sudo
  nazwa_grupy_sudo=${nazwa_grupy_sudo// /\\ }
  nazwa_grupy_sudo=${nazwa_grupy_sudo// /\\ }
  echo "%$nazwa_grupy_sudo@$nazwa_domeny ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  echo "Add Another Group? (t/n)"
  read t_n
done
echo "Script finished."
exit
