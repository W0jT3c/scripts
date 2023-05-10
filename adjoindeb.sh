#!/bin/bash
sudo apt-get update && upgrade -y
sudo apt-get install sssd-ad sssd-tools realmd adcli krb5-user -y
sudo cp /usr/lib/x86_64-linux-gnu/sssd/conf/sssd.conf /etc/sssd/
sudo chmod 600 /etc/sssd/sssd.conf
echo "Enter The Domain Name:"
read -r nazwa_domeny
nazwa_domeny=$(echo "$nazwa_domeny" | tr '[:lower:]' '[:upper:]')
echo "Enter The Login Of The User Who Has The Right To Join The Computer To The Domain:"
read -r nazwa_uzytkownika_administratora
if ! sudo realm join -U $nazwa_uzytkownika_administratora@${nazwa_domeny} ${nazwa_domeny} -v; then
    echo "Exit"
    exit 1
fi
t_n="t"
  while [[ "$t_n" == "t" ]]; do
    echo "Enter The Name Of The Group That Should Be In The Sudo Group (Name Displayed In Lowercase Letters With Spaces):"
    read nazwa_grupy_sudo
    if [[ -z "$nazwa_grupy_sudo" ]]; then
    else
    nazwa_grupy_sudo=${nazwa_grupy_sudo// /\\ }
    echo "%$nazwa_grupy_sudo@$nazwa_domeny ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "Add Another Group? (t/n)"
    read t_n
    fi
  done
echo "access_provider = simple" >> /etc/sssd/sssd.conf
sudo pam-auth-update --enable mkhomedir
systemctl restart sssd
if [ -d /usr/share/lightdm/lightdm.conf.d/ ]; then
  if ! grep -q "greeter-show-manual-login=true" /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf &> /dev/null; then
    echo "greeter-show-manual-login=true" >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    sed -i 'greeter-show-manual-login=false' /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    if  grep -q "greeter-show-manual-login=false" /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf &> /dev/null; then
    sed -i 'greeter-show-manual-login=false' /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    fi
  fi
fi
if [ -d /etc/lightdm/lightdm.conf.d/ ]; then
  if ! grep -q "greeter-show-manual-login=true" /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf; then
    echo "greeter-show-manual-login=true" >> /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf
    if  grep -q "greeter-show-manual-login=false" /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf; then
    sed -i 'greeter-show-manual-login=false' /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf
    fi
  fi
fi
if systemctl status lightdm.service &> /dev/null; then
   systemctl restart lightdm.service
fi
t_n="t"
  while [[ "$t_n" == "t" ]]; do
    echo "Enter The Name Of The Group That Should Be In The Sudo Group(Name Displayed In Lowercase Letters With Spaces):"
    read nazwa_grupy_sudo
    if [[ -z "$nazwa_grupy_sudo" ]]; then
    else
    nazwa_grupy_sudo=${nazwa_grupy_sudo// /\\ }
    echo "%$nazwa_grupy_sudo@$nazwa_domeny ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "Add Another Group? (t/n)"
    read t_n
    fi
  done
echo "Script Finished, You Can Now Login To The Domain"
exit
