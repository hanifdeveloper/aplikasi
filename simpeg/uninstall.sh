#!/bin/bash
# Running Application : 
# $. bash <(curl -s https://raw.githubusercontent.com/hanifdeveloper/aplikasi/master/simpeg/uninstall.sh)

VHOST='/var/www/simpeg'
echo "Uninstalling Webserver ..."
echo "=========================="
sudo service apache2 stop
sudo apt-get purge apache2* -y
sudo apt-get autoremove -y
sudo rm -rf /etc/apache2
sudo rm -rf $VHOST
sudo rm -rf /etc/motd # File Banner
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