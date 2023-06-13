#!/bin/bash
clear
#Making restarting services with outdated libraries automatic instead of interactive
sed -i '38s/.*/$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf >/dev/null 2>&1

#DHCP
sudo dhclient >/dev/null 2>&1
echo "DHCP server found. IP set."

#proxy server url
server="proxy-server.com"
echo "Added proxy"


#proxy functions
function AddProxyLine {
  newline=$1
  searchstring=$2
  #Check if /etc/environment already has that variable
  linenum="$(cat '/etc/environment' | grep -n ${searchstring} | grep -Eo '^[^:]+')"
  if [ "$?" -eq 0 ]; then
    safenewline="$(printf "${newline}" | sed -e 's/[\/&]/\\&/g')"
    sudo sed -i "${linenum}s/.*/${safenewline}/" /etc/environment >/dev/null 2>&1
  else
    #Append the line to the end of the file
    sudo bash -c "echo '${newline}' >> /etc/environment" >/dev/null 2>&1
  fi
}
function AddAptLine {
  newline=$1
  searchstring=$2
  linenum=0
  replace=FALSE
  if [ -e /etc/apt/apt.conf ]; then
    linenum="$(cat '/etc/apt/apt.conf' | grep -n ${searchstring} | grep -Eo '^[^:]+')"
    if [ "$?" -eq 0 ]; then
      replace=TRUE
    fi
  fi
  if [ "$replace" = "TRUE" ]; then
    safenewline="$(printf "${newline}" | sed -e 's/[\/&]/\\&/g')"
    sudo sed -i "${linenum}s/.*/${safenewline}/" /etc/apt/apt.conf
  else
    #Append the line to the end of the file
    sudo bash -c "echo '${newline}' >> /etc/apt/apt.conf"
  fi
}


#Duplicating uppercase and lowercase because of some apps
AddProxyLine "http_proxy=http://${server}:911" "http_proxy" >/dev/null 2>&1
AddProxyLine "https_proxy=http://${server}:912" "https_proxy" >/dev/null 2>&1
AddProxyLine "ftp_proxy=http://${server}:911" "ftp_proxy" >/dev/null 2>&1
AddProxyLine "socks_proxy=http://${server}:1080" "socks_proxy" >/dev/null 2>&1
AddProxyLine "no_proxy=10.0.0.0/8,192.168.0.0/16,localhost,.local,127.0.0.0/8,172.16.0.0/12,134.134.0.0/16" "no_proxy" >/dev/null 2>&1
AddProxyLine "HTTP_PROXY=http://${server}:911" "HTTP_PROXY" >/dev/null 2>&1
AddProxyLine "HTTPS_PROXY=http://${server}:912" "HTTPS_PROXY" >/dev/null 2>&1
AddProxyLine "FTP_PROXY=http://${server}:911" "FTP_PROXY" >/dev/null 2>&1
AddProxyLine "SOCKS_PROXY=http://${server}:1080" "SOCKS_PROXY" >/dev/null 2>&1
AddProxyLine "NO_PROXY=10.0.0.0/8,192.168.0.0/16,localhost,.local,127.0.0.0/8,172.16.0.0/12,134.134.0.0/16" "NO_PROXY" >/dev/null 2>&1 AddAptLine "Acquire::http::Proxy \"http://${server}:911\";" "Acquire::http::Proxy" >/dev/null 2>&1
AddAptLine "Acquire::ftp::Proxy \"http://${server}:911\";" "Acquire::ftp::Proxy" >/dev/null 2>&1


#Check for the existance of gsettings
command -v gsettings >/dev/null 2>&1
if [ "$?" -eq 0 ]; then
  sudo gsettings set org.gnome.system.proxy mode 'auto' >/dev/null 2>&1
  sudo gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '*.local', '10.0.0.0/8', '192.168.0.0/16', '172.16.0.0/12', '134.134.0.0/16']" >/dev/null 2>&1
  gsettings set org.gnome.system.proxy mode 'auto' >/dev/null 2>&1
  gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '*.local', '10.0.0.0/8', '192.168.0.0/16', '172.16.0.0/12', '134.134.0.0/16']" >/dev/null 2>&1
fi


#Update ignoring the date check
echo "Updating repositories"
sudo apt-get -o Acquire::Check-Valid-Until=false -o Acqiure::Check-Date=false update >/dev/null 2>&1
sudo apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update -y >/dev/null 2>&1


#Installing packages
echo "Installing necessary packages"
sudo apt install connect-proxy git samba mc network-manager -y >/dev/null 2>&1

#ZABBIX
#Add zabbix repository
sudo dpkg -i zabbix-release_5.0-1+focal_all.deb  >/dev/null 2>&1
sudo apt update -y  >/dev/null 2>&1
# Install zabbix agent package
sudo apt install zabbix-agent -y  >/dev/null 2>&1
# Get IP of the host
#hostname="$(ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | tail -n 1)"
host=$(hostname)
# Generate configuration file for the specified server (Change Server=<IP>)
sudo bash -c "echo 'PidFile=/run/zabbix/zabbix_agentd.pid' > /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'LogFile=/var/log/zabbix-agent/zabbix_agentd.log' >> /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'LogFileSize=0' >> /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'Server=10.237.146.34' >> /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'ServerActive=127.0.0.1' >> /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'Hostname=$host' >> /etc/zabbix/zabbix_agentd.conf"
sudo bash -c "echo 'Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf' >> /etc/zabbix/zabbix_agentd.conf"
# Restart the agent service
sudo systemctl restart zabbix-agent.service  >/dev/null 2>&1
echo "Zabbix-agent was succesfuly set up"

#NetworkManager config for dhcp discovery on startup and turning off automatic upgrades
echo $'network:\n version: 2\n renderer: NetworkManager' > /etc/netplan/01-netcfg.yaml
echo "Disabling unattended updates"
sudo apt remove unattended-upgrades -y >/dev/null 2>&1

#Some platforms have problems with NetworkManager configuration. Here is a fix to that
sudo echo "" | sudo tee /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf


#sudo without password
echo "test   ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo >/dev/null 2>&1

#Disable lock screen after suspend/hibernate
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true' >/dev/null 2>&1
gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend 'false' >/dev/null 2>&1


#Reset
echo "-------------ALL DONE------------"
echo "The machine will reboot now"
sleep 2

init 6