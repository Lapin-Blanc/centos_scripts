#!/bin/bash

function usage {
    echo "$0 [OPTIONS] où les options sont :
        -u | --user        : nom d'utilisateur
        -p | --password    : mot de passe
        -h | --help        : cette aide
    "
}

while [ "$1" != "" ]; do
    case $1 in
        -u | --user )           shift
                                USERNAME=$1
                                ;;
        -p | --password )       shift
                                PASSWORD=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

VALID_USER_RE='^[a-zA-Z][a-zA-Z0-9_\-]{3,}$'
while [[ ! $USERNAME =~ $VALID_USER_RE ]]
do
        read -p "$(echo -e "Nom d'utilisateur : ")" USERNAME
done

while [ -z $PASSWORD ]
do
        read -s -p "$(echo -e "Mot de passe : ")" PASS1
        read -s -p "$(echo -e "\nMot de passe (vérification): ")" PASS2
        while [ "$PASS1" != "$PASS2" ]
        do
                echo -e "\nles mots de passe ne concordent pas..."
                read -s -p "$(echo -e "Mot de passe : ")" PASS1
                read -s -p "$(echo -e "\nMot de passe (vérification): ")" PASS2
        done
        PASSWORD=$PASS1
        echo -e "\n"
done

# echo 1.$USERNAME
# echo 2.$PASSWORD
# echo 3.$DOMAIN
# echo 4.$EMAIL

useradd $USERNAME
echo $USERNAME:$PASSWORD | chpasswd

# Configuration générale de l'utilisateur
# - Configuration du prompt
# - Configuration de python et des virtualenvs
# - Configuration du site personnel

if grep -q -e "Customize the prompt" /home/$USERNAME/.bashrc
then
    echo "Prompt already customized"
else
    cat >> /home/$USERNAME/.bashrc <<-EOF
# Customize the prompt
if [ \$(id -u) -eq 0 ];
then # you are root, make the prompt red
    export PS1="\[\e[00;36m\]\A\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[00;34m\]\u\[\e[0m\]\[\e[00;33m\]@\[\e[0m\]\[\e[00;37m\]\H \[\e[0m\]\[\e[00;32m\]\w\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[00;33m\]\$\[\e[0m\]\[\e[00;37m\] \[\e[0m\]"
else
    export PS1="\[\e[00;36m\]\A\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[00;31m\]\u\[\e[0m\]\[\e[00;33m\]@\[\e[0m\]\[\e[00;37m\]\H \[\e[0m\]\[\e[00;32m\]\w\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[00;33m\]\$\[\e[0m\]\[\e[00;37m\] \[\e[0m\]"
fi
EOF
fi

if which python2.7
then
    if ! grep -q -e "^alias python.*$" /home/$USERNAME/.bashrc
    then
        echo alias python=$(which python2.7) >> /home/$USERNAME/.bashrc
    fi
    if ! grep -q -e "^export VIRTUALENVWRAPPER_PYTHON.*$" /home/$USERNAME/.bashrc
    then
         echo export VIRTUALENVWRAPPER_PYTHON=$(which python2.7) >> /home/$USERNAME/.bashrc
    fi
    if [ -e /usr/local/bin/virtualenvwrapper.sh ] && ! grep -q -e "^source /usr/local/bin/virtualenvwrapper.sh$" /home/$USERNAME/.bashrc
    then
         echo source /usr/local/bin/virtualenvwrapper.sh >> /home/$USERNAME/.bashrc
    fi
fi

if ! grep -s -e "^$USERNAME$" /etc/vsftpd/chroot_list
then
    echo "$USERNAME" >> /etc/vsftpd/chroot_list
fi

# Configuration du site personnel
# Préparation des accès WebDAV
chown $USERNAME:apache /home/$USERNAME
chmod g+wxs /home/$USERNAME
mkdir -p /home/$USERNAME/public_html

echo "<h2>Page d'accueil de $USERNAME</h2>" > /home/$USERNAME/public_html/index.html

# Configuration des répertoires virtuels
if ! grep -s -e "<Directory /home/*/public_html>" /etc/httpd/conf/httpd.conf
then echo "<Directory /home/*/public_html>
    Options Indexes Includes FollowSymLinks
    AllowOverride All
    Allow from all
    Order deny,allow
</Directory>" >> /etc/httpd/conf/httpd.conf
fi

service httpd restart

exit 0
