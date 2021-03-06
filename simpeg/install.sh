#!/bin/bash
# echo "" > install-server.sh && chmod +x install-server.sh && pico install-server.sh
# Init Variable
APPLICATION="Sistem Informasi Kepegawaian Kota Pekalongan 2019"
_APP_NAME="simpeg"
_BASE_VHOST='/var/www'
_APACHE_LOG_DIR='/var/log/apache2'
_DNS_NAME="/etc/hosts"
_CONF_VHOST='/etc/apache2/sites-available'

_VHOST="$_BASE_VHOST/$_APP_NAME"
_DIR_SQL="$_VHOST/upload/sql"

# Git Configuration
_GIT_URLS="bitbucket.org/kominfopklcity/web-application-simpeg.git"
_GIT_USER=""
_GIT_PASS=""

_RESULT=`mktemp`
_FILE_SQL=()

webserver_linux(){
echo "Installing Webserver ..."
echo "========================"
# Install Aplikasi Pendukung
sudo apt-get update
sudo apt-get install git
# Webserver Apache
sudo apt-get install apache2 -y
sudo apt-get install curl -y
echo
}

php_linux(){
echo "Installing PHP ..."
echo "=================="
sudo apt-get install php7.0 -y
sudo apt-get install php-curl -y
sudo apt-get install php-mysql -y
sudo apt-get install php-gd -y
sudo systemctl reload apache2
echo
}

mysql_linux(){
echo "Installing MySQL Server ..."
echo "==========================="
sudo apt-get install mysql-server -y
sudo apt-get install mysql-client -y
sudo apt-get install mysql-common -y
echo
}

create_vhost_linux(){
echo "Creating Virtual Host"
echo "====================="
sudo mkdir -p $_VHOST
sudo chmod -R 755 $_VHOST
sudo chown -R $USER:www-data $_VHOST
sudo touch "$_CONF_VHOST/$_APP_NAME.local.conf"
sudo chmod 777 "$_CONF_VHOST/$_APP_NAME.local.conf"
sudo cat > "$_CONF_VHOST/$_APP_NAME.local.conf" << EOF
<VirtualHost *:80>
ServerAdmin administrator@local.com
ServerName $_APP_NAME.local
ServerAlias www.$_APP_NAME.local
DocumentRoot "$_BASE_VHOST/$_APP_NAME"
<Directory "$_BASE_VHOST/$_APP_NAME">
    Options Indexes FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
    Require all granted
</Directory>
ErrorLog ${_APACHE_LOG_DIR}/error.$_APP_NAME.log
CustomLog ${_APACHE_LOG_DIR}/access.$_APP_NAME.log combined
</VirtualHost>
EOF
sudo a2dissite 000-default.conf
sudo a2ensite $_APP_NAME.local.conf
sudo a2enmod rewrite
sudo apache2ctl configtest
sudo systemctl reload apache2
echo
}

config_app_linux(){
echo "Configuring System ..."
echo "======================"
fileConfigApache='/etc/apache2/apache2.conf' # check location: sudo find /etc/ -name apache2.conf | grep "apache2"
fileConfigPHP='/etc/php/7.0/apache2/php.ini' # check location: sudo find /etc/ -name php.ini | grep "apache2"
fileConfigMySQL='/etc/mysql/my.cnf'# check location: sudo find /etc -name my.cnf | grep "mysql"
sudo grep -q 'ServerSignature Off' $fileConfigApache && sudo sed -i 's:ServerSignature Off:ServerSignature Off:' $fileConfigApache || echo 'ServerSignature Off' | sudo tee --append $fileConfigApache > /dev/null
sudo grep -q 'ServerTokens Prod' $fileConfigApache && sudo sed -i 's:ServerTokens Prod:ServerTokens Prod:' $fileConfigApache || echo 'ServerTokens Prod' | sudo tee --append $fileConfigApache > /dev/null
sudo sed -i 's:^upload_max_filesize.*:upload_max_filesize=20M:g' $fileConfigPHP
sudo sed -i 's:^post_max_size.*:post_max_size=20M:g' $fileConfigPHP
sudo sed -i 's:^;browscap.*:browscap=/var/www/simpeg/comp/php_browscap/php_browscap.ini:g' $fileConfigPHP
sudo sed -i 's:^innodb_buffer_pool_size.*:innodb_buffer_pool_size=384M:g' $fileConfigMySQL
sudo sed -i 's:^innodb_additional_mem_pool_size.*:innodb_additional_mem_pool_size=20M:g' $fileConfigMySQL
sudo sed -i 's:^innodb_log_file_size.*:innodb_log_file_size=10M:g' $fileConfigMySQL
sudo sed -i 's:^innodb_log_buffer_size.*:innodb_log_buffer_size=64M:g' $fileConfigMySQL
sudo sed -i 's:^innodb_flush_log_at_trx_commit.*:innodb_flush_log_at_trx_commit=1:g' $fileConfigMySQL
sudo sed -i 's:^innodb_lock_wait_timeout.*:innodb_lock_wait_timeout=180M:g' $fileConfigMySQL
}

add_signature_app(){
# Update Message of the Day
php $_VHOST/simpeg.php --banner > motd.conf
sudo cp motd.conf /etc/motd
sudo rm -rf motd.conf
# Adding Variabel Environment Simpeg
fileEnv="$HOME/.bashrc"
tempEnv="$HOME/.bashrc_temp"
if [ -f -a $fileEnv ]; then
    cp $fileEnv $tempEnv
    sudo grep -q 'export _VHOST_SIMPEG' $tempEnv && sudo sed -i 's:export _VHOST_SIMPEG:export _VHOST_SIMPEG:' $tempEnv || echo "export _VHOST_SIMPEG=$_VHOST" | sudo tee --append $tempEnv > /dev/null
    sudo grep -q 'alias simpeg' $tempEnv && sudo sed -i 's:alias simpeg:alias simpeg:' $tempEnv || echo 'alias simpeg="php $_VHOST_SIMPEG/simpeg.php"' | sudo tee --append $tempEnv > /dev/null
    cp $tempEnv $fileEnv
    rm $tempEnv
fi
# Adding Cronjob Simpeg
crontab -l > simpeg_cronjob
sudo grep -q 'simpeg' simpeg_cronjob && sudo sed -i 's:simpeg:simpeg:' simpeg_cronjob || echo "@daily php $_VHOST/simpeg.php --sync-all 2>&1 >> sync.logs" | sudo tee --append simpeg_cronjob > /dev/null
crontab simpeg_cronjob
rm simpeg_cronjob
# Reload Configuration
# exec bash
}

#Custom Function
init_app(){
dialog --clear --backtitle "$APPLICATION" \
--checklist "Tekan tombol spasi, untuk memilih modul yang akan diinstall" 20 60 15 \
"webserver" "Install Web Server Apache" off \
"php" "Install PHP" off \
"mysql" "Install MySQL Server" off \
"simpeg" "Install/Update Aplikasi Simpeg" on 2> $_RESULT
}

init_user_git(){
dialog --clear --backtitle "$APPLICATION" \
--inputbox "User Git" 15 50 "$_GIT_USER" 2> $_RESULT
}

init_pass_git(){
dialog --clear --backtitle "$APPLICATION" \
--insecure \
--passwordbox "Password Git" 15 50 "$_GIT_PASS" 2> $_RESULT
}

check_modul(){
type $1 &>/dev/null && $1 || echo "modul $1 not found" > /dev/null
}

install_modul(){
modul=$*
for m in $modul; do
    os=`echo $_OS | awk '{print tolower($0)}'`
    check_modul $m"_"$os
done
}

form_import_db(){
# List file sql
nomer=1
lists=()
cd $_DIR_SQL;
for file in *.sql; do
    _FILE_SQL+=("$file")
    lists+=("$nomer $file")
    let nomer=$nomer+1
done
dialog --clear --backtitle "$APPLICATION" --title 'Import Database' \
--menu 'Pilih database yang akan direstore' 15 55 5 ${lists[@]} 2> $_RESULT
}

action_import_db(){
files=$1
dialog --backtitle "$APPLICATION" --infobox "Tunggu sebentar, sedang mengimport $files ..." 5 100; sleep 3
import=`php $_VHOST/simpeg.php --restore $files`
show_results "File Import : $files"
}

show_results(){
# Versi Apache
vAPACHE=`sudo apachectl -V | grep "Server version"`
# Versi PHP
vPHP="PHP version: `php -v|awk '{print $2}'|head -n 1`"
# Versi MySQL
vMYSQL="MySQL version: `mysql --version|awk '{ print $5 }'`"
result="
Selamat Aplikasi simpeg 2019 telah terinstall
Berikut detail sistem yang terinstall:
$vAPACHE
$vPHP
$vMYSQL
$1
"
dialog --title "Instalation Complete" --backtitle "$APPLICATION" --msgbox "$result" 20 100;
# Reload Configuration
clear
cd $HOME;
exec bash
# exit
}

exit_apps(){
echo $1; sleep 1; clear; exit;
}

show_form(){
$1 # Running Function
form_return=$? # Catch Error Code Dialog (0: success)
case $form_return in
    1) exit_apps "Application aborted";;
    255) exit_apps "Application terminated";;
esac
}

# Main Program
_OS=`uname -s` # Check OS
echo 'Application started ...'
# Fix Problem Instalasi
sudo dpkg --configure -a
show_form init_app
list_modul=`cat $_RESULT`
install_modul $list_modul
# Check Application
if [ -d $_VHOST/.git ]; then
    clear
    echo "Update Applicaton"
    echo "================="
    cd $_VHOST && git pull origin master
    cd $HOME
else
    # create_vhost_linux
    install_modul create_vhost
    echo "Installing Applicaton"
    echo "====================="
    
    # Check Project is Exist
    while true; do
        show_form init_user_git
        user_git=`cat $_RESULT`
        show_form init_pass_git
        pass_git=`cat $_RESULT`
        clear
        git clone https://$user_git:$pass_git@$_GIT_URLS $_VHOST
    if [ -e $_VHOST/.git ]; then
        break
    fi
    done
    
    # Seting User Git
    git config --global user.name "$user_git"
    git config --global user.password "$pass_git"
    echo "Configuring Application ..."
    echo "============================"
    install_modul config_app
    php $_VHOST/simpeg.php --app-init
    echo "Configuration OK"
    
    # Restore DB
    show_form form_import_db
    input=`cat $_RESULT`
    action_import_db "${_FILE_SQL[$input-1]}"
fi

rm -f $_RESULT # Clear Result