#!/bin/bash
# echo "" > uninstall-server.sh && chmod +x uninstall-server.sh && pico uninstall-server.sh
# Init Variable
APPLICATION="Sistem Informasi Kepegawaian Kota Pekalongan 2019"
_APP_NAME="simpeg"
_BASE_VHOST='/var/www'
_APACHE_LOG_DIR='/var/log/apache2'
_DNS_NAME="/etc/hosts"
_CONF_VHOST='/etc/apache2/sites-available'

_VHOST="$_BASE_VHOST/$_APP_NAME"
_DIR_SQL="$_VHOST/upload/sql"

delete_signature_app(){
# Remove Message of the Day
sudo rm -rf /etc/motd
# Remove Variabel Environment Simpeg
fileEnv="$HOME/.bashrc"
tempEnv="$HOME/.bashrc_temp"
if [ -f -a $fileEnv ]; then
    cp $fileEnv $tempEnv
    sudo sed -i '/export _VHOST_SIMPEG/d' $tempEnv
    sudo sed -i '/alias simpeg/d' $tempEnv
    cp $tempEnv $fileEnv
    rm $tempEnv
fi
# Remove Cronjob Simpeg
crontab -l > simpeg_cronjob
sudo sed -i '/simpeg/d' simpeg_cronjob
crontab simpeg_cronjob
rm simpeg_cronjob
# Reload Configuration
# exec bash
}

# Main Program
echo "Uninstalling Webserver ..."
echo "=========================="
sudo service apache2 stop
sudo apt-get purge apache2* -y
sudo apt-get autoremove -y
sudo rm -rf /etc/apache2
sudo rm -rf $_VHOST
echo
echo "Uninstalling PHP ..."
echo "===================="
x="$(dpkg --list | grep php | awk '/^ii/{ print $2}')"
sudo apt-get --purge remove $x -y
sudo apt-get purge php7.* -y
sudo apt-get autoremove phpmyadmin -y
sudo apt-get autoremove -y
sudo apt-get autoclean
echo 
echo "Uninstalling MySQL Server ..."
echo "============================="
sudo apt-get remove --purge mysql-server mysql-client mysql-common -y
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo rm -rf /etc/mysql
sudo find / -iname 'mysql*' -exec rm -rf {} \;

# Removing Signature
delete_signature_app
echo "Restarting Server ..."
sleep 2s
sudo reboot