#!/bin/sh

yum -y upgrade
yum install -y epel-release
yum install -y net-tools nano vim wget

yum -y install vsftpd

setenforce 0
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/sysconfig/selinux
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config

# Installation, démarrage et activation d'Apache
yum -y install httpd
systemctl start httpd.service
systemctl enable httpd.service
# Ouverture permanent du port 80 dans le firewall
firewall-cmd --permanent --zone=public --add-service=http 
firewall-cmd --reload

# installation de php ainsi que du module de liaison vers MariaDB
yum -y install php php-mysql
# installation de divers modules complémentaires à PHP
yum -y install php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl curl-devel
# création d'un fichier de test PHP
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
# on pourrait aussi éditer le fichier /var/www/html/index.php
# et y écrire "" nous même...
# il est nécessaire de redémarrer Apache pour que celui-ci
# prenne les changements en compte
systemctl restart httpd.service

sed -i "s/anonymous_enable.*/anonymous_enable=NO/" /etc/vsftpd/vsftpd.conf
sed -i "s/.*chroot_local_user.*/chroot_local_user=YES/" /etc/vsftpd/vsftpd.conf
sed -i "s/local_umask=.*/local_umask=007/" /etc/vsftpd/vsftpd.conf
echo "allow_writeable_chroot=YES" >> /etc/vsftpd/vsftpd.conf
firewall-cmd --permanent --zone=public --add-service=ftp
firewall-cmd --reload
systemctl start vsftpd
systemctl enable vsftpd

yum -y install mariadb-server mariadb
systemctl start mariadb.service
systemctl enable mariadb.service
mysql_secure_installation

yum -y install phpMyAdmin
echo "" > /etc/httpd/conf.d/phpMyAdmin.conf
cat > /etc/httpd/conf.d/phpMyAdmin.conf << EOF
# phpMyAdmin - Web based MySQL browser written in php
#
# Allows only localhost by default
#
# But allowing phpMyAdmin to anyone other than localhost should be considered
# dangerous unless properly secured by SSL

Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8

  <IfModule mod_authz_core.c>
    # Apache 2.4
    <RequireAny>
      Require all granted
    </RequireAny>
  </IfModule>
  <IfModule !mod_authz_core.c>
    # Apache 2.2
    Order Deny,Allow
    AllowOverride None
    Options None
    Allow from All
    Require all granted
  </IfModule>
</Directory>
EOF
systemctl restart httpd
#####################################
# début de la création d'utilisateur
VALID_USER_RE='^[a-zA-Z][a-zA-Z0-9_\-]{5,}$'

echo "###############################"
read -p "Nom pour l'utilisateur : " FTP_USER

while [[ ! "$FTP_USER" =~ $VALID_USER_RE ]]
do
        echo "Le nom d'utilisateur doit faire au moins 5 caractères, être composé de lettres et de chiffres et commencer par une lettre"
        read -p "Nom pour l'utilisateur : " FTP_USER
done

if [ "$(cut -d: -f1 /etc/passwd | grep $FTP_USER)" != "" ]; then 
    echo "L'utilisateur existe déja"
else
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
    
    useradd $FTP_USER
    echo $FTP_USER:$PASSWORD | chpasswd
	chmod 750 /home/$FTP_USER
	# création du dossier de publication du site
	mkdir /home/$FTP_USER/public_html
	# définition des utilisateur et groupe propriétaires
	chown $FTP_USER:$FTP_USER /home/$FTP_USER/public_html/
	# modification des droits sur ce répertoire
	# propriétaire et groupe : lecture et écriture
	# autre : aucun
	chmod 770 /home/$FTP_USER/public_html
	# faire entrer l'utilisateur apache dans le groupe fabien
	usermod -a -G $FTP_USER apache
fi
# fin de la création de l'utilisateur
#####################################

#######################################################
# début de la configuration du virtual host pour apache
VALID_HOSTNAME_RE='^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'
echo "########################"
while [[ ! $VIRTUAL_HOST_DOMAIN =~ $VALID_HOSTNAME_RE ]]
do
        read -p "Nom de l'hôte virtuel : " VIRTUAL_HOST_DOMAIN
done

echo "<VirtualHost *:80>
    ServerAdmin webmaster@$VIRTUAL_HOST_DOMAIN
    ServerName $VIRTUAL_HOST_DOMAIN
    ErrorLog logs/$VIRTUAL_HOST_DOMAIN-error
    CustomLog logs/$VIRTUAL_HOST_DOMAIN-access common
        DocumentRoot /home/$FTP_USER/public_html

    <Directory /home/$FTP_USER/public_html>
        AllowOverride All
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>" > /etc/httpd/conf.d/"$VIRTUAL_HOST_DOMAIN".conf

systemctl restart httpd

echo "*************************************************************************************"
echo "*************************************************************************************"
echo "Configuration terminée, ajouter la ligne suivante à votre fichiers hosts sur windows :
Adresse_IP_du_serveur $VIRTUAL_HOST_DOMAIN"