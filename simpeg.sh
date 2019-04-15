#!/bin/bash
echo 'TESTING DARI SERVER'
#Init Variable
APPLICATION="Sistem Informasi Kepegawaian Kota Pekalongan 2019"
_APP_NAME="simpeg"
_BASE_VHOST='/var/www'
_APACHE_LOG_DIR='/var/log/apache2'
_DNS_NAME="/etc/hosts"
_CONF_VHOST='/etc/apache2/sites-available'

_VHOST="$_BASE_VHOST/$_APP_NAME"
_DIR_SQL="$_VHOST/upload/sql"

_RESULT=`mktemp`
_FILE_SQL=""

#Custom Function
init_app(){
dialog --clear --backtitle "$APPLICATION" \
--checklist "Tekan tombol spasi, untuk memilih modul yang akan diinstall" 20 60 15 \
"webserver" "Install Web Server Apache" off \
"php" "Install PHP" off \
"mysql" "Install MySQL Server" off \
"simpeg" "Install/Update Aplikasi Simpeg" on 2> $_RESULT
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
show_form init_app

rm -f $_RESULT # Clear Result
