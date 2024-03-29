#!/bin/bash
sudo apt-get update && upgrade -y
sudo apt-get install sssd-ad sssd-tools realmd adcli krb5-user policykit-1 packagekit -y
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
  echo "Enter The Name Of The Group That Should Be Allowed To Log In (Name Displayed In Lowercase Letters With Spaces):"
  read -r nazwa_grupy_logowania
  if [[ -n "$nazwa_grupy_logowania" ]]; then
    if grep -q "simple_allow_groups" /etc/sssd/sssd.conf; then
      sed -i "s/simple_allow_groups = \(.*\)/simple_allow_groups = \1, ${nazwa_grupy_logowania}@${nazwa_domeny}/" /etc/sssd/sssd.conf
    else
      echo "simple_allow_groups = ${nazwa_grupy_logowania}@${nazwa_domeny}" >> /etc/sssd/sssd.conf
    fi
  else
    break
  fi
  echo "Add Another Group? (t/n)"
  read t_n
done
if grep -q "krb5_validate = true" /etc/sssd/sssd.conf > /dev/null 2>&1; then
 sudo sed -i 's/krb5_validate = true/krb5_validate = False/' /etc/sssd/sssd.conf
else
  if grep -q "krb5_validate = false" /etc/sssd/sssd.conf > /dev/null 2>&1; then
   break
  else
   echo "krb5_validate = False" >> /etc/sssd/sssd.conf
  fi
fi
if grep -q "access_provider = simple" /etc/sssd/sssd.conf > /dev/null 2>&1; then
 sudo sed -i 's/access_provider = .*/access_provider = simple/' /etc/sssd/sssd.conf
else
  if grep -q "access_provider = simple" /etc/sssd/sssd.conf > /dev/null 2>&1; then
   break
  else
   echo "access_provider = simple" >> /etc/sssd/sssd.conf
  fi
fi
sudo pam-auth-update --enable mkhomedir
if [ -d /usr/share/lightdm/lightdm.conf.d/ ]; then
  if grep -q "greeter-show-manual-login=false" /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf > /dev/null 2>&1; then
    sudo sed -i 's/greeter-show-manual-login=false/greeter-show-manual-login=true/' /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    if ! grep -q "greeter-show-manual-login=true" /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf > /dev/null 2>&1; then
    sed -i 'greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    fi
  fi
fi
if [ -d /etc/lightdm/lightdm.conf.d/ ]; then
  if grep -q "greeter-show-manual-login=false" /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf; then
    sudo sed -i 's/greeter-show-manual-login=false/greeter-show-manual-login=true/' /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf
    if ! grep -q "greeter-show-manual-login=true" /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf; then
    sed -i 'greeter-show-manual-login=true' >> /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf
    fi
  fi
fi
if systemctl status lightdm.service > /dev/null 2>&1; then
    systemctl restart lightdm.service
fi
systemctl restart sssd
t_n="t"
while [[ "$t_n" == "t" ]]; do
  echo "Enter The Name Of The Group That Should Be In The Sudo Group (Name Displayed In Lowercase Letters With Spaces):"
  read -r nazwa_grupy_sudo
  if [[ -n "$nazwa_grupy_sudo" ]]; then
    nazwa_grupy_sudo=${nazwa_grupy_sudo// /\\ }
    echo "%$nazwa_grupy_sudo@$nazwa_domeny ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  else
    break
  fi
  echo "Add Another Group? (t/n)"
  read t_n
done
echo "Script Finished, Now You Can Login"
exit
