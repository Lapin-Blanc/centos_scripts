#!/bin/bash
VIRTUAL_ENV=django16
PROJECT_NAME=mysite
VIRTUAL_HOST_DOMAIN=fabien.toune.be

function usage {
    echo "$0 [OPTIONS] où les options sont :
        -u | --user        : nom d'utilisateur du projet
        -p | --password    : mot de passe webdav
        -v | --virtualenv  : environnement virtuel
        -j | --projectname : nom du projet django
        -d | --domain      : nom du domaine virtuel 
        -h | --help        : cette aide
    "
}

while [ "$1" != "" ]; do
    case $1 in
        -u | --user )           shift
                                USER_NAME=$1
                                ;;
        -p | --password )       shift
                                PASSWORD=$1
                                ;;
        -v | --virtualenv )     shift
                                VIRTUAL_ENV=$1
                                ;;
        -j | --projectname )    shift
                                PROJECT_NAME=$1
                                ;;
        -d | --domain )         shift
                                VIRTUAL_HOST_DOMAIN=$1
                                ;;
        -h | --help )           usage
                                exit 1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

VALID_USER_RE='^[a-zA-Z][a-zA-Z0-9_\-]{3,}$'
VALID_HOSTNAME_RE='^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'

while [[ ! $USER_NAME =~ $VALID_USER_RE ]]
do
        read -p "$(echo -e "Nom d'utilisateur : ")" USER_NAME
done

while [ -z $PASSWORD ]
do
        read -s -p "$(echo -e "Mot de passe webdav: ")" PASS1
        read -s -p "$(echo -e "\nMot de passe (vérification): ")" PASS2
        while [ "$PASS1" != "$PASS2" ]
        do
                echo -e "\nles mots de passe ne concordent pas..."
                read -s -p "$(echo -e "Mot de passe webdav: ")" PASS1
                read -s -p "$(echo -e "\nMot de passe (vérification): ")" PASS2
        done
        PASSWORD=$PASS1
        echo -e "\n"
done

while [[ ! $VIRTUAL_ENV =~ $VALID_USER_RE ]]
do
        read -p "$(echo -e "Environnement virtuel : ")" VIRTUAL_ENV
done

while [[ ! $PROJECT_NAME =~ $VALID_USER_RE ]]
do
        read -p "$(echo -e "Nom du projet django : ")" PROJECT_NAME
done

while [[ ! $VIRTUAL_HOST_DOMAIN =~ $VALID_HOSTNAME_RE ]]
do
        read -p "$(echo -e "Nom de l'hôte virtuel : ")" VIRTUAL_HOST_DOMAIN
done

# Active les virtual hosts et WSGISocketPrefix
sed -i "s/^\(\s*\)#\s*\(NameVirtualHost.*\)$/\1\2/" /etc/httpd/conf/httpd.conf
if grep -q "WSGISocketPrefix" /etc/httpd/conf/httpd.conf
then 
    echo "WSGISocketPrefix already configured"
else 
    sed -i "/^\(\s*\)\(NameVirtualHost.*\)$/a\WSGISocketPrefix /var/run/wsgi" /etc/httpd/conf/httpd.conf
fi

# Active les virtual hosts
# if grep -q "ServerName $VIRTUAL_HOST_DOMAIN" /etc/httpd/conf/httpd.conf
# then 
#    echo "Virtual host $VIRTUAL_HOST_DOMAIN already configured"
# else 
mkdir -p /home/webdav
chown apache:apache /home/webdav
ln -s /home/$USER_NAME/ /home/webdav/$USER_NAME
(echo -n "$USER_NAME:WebDAV:" && echo -n "$USER_NAME:WebDAV:$PASSWORD" | md5sum | awk '{print $1}' ) >> /etc/httpd/conf/webdav.users.pwd

echo "
<VirtualHost *:80>

    ServerAdmin webmaster@$VIRTUAL_HOST_DOMAIN
    ServerName $VIRTUAL_HOST_DOMAIN
    ErrorLog logs/$VIRTUAL_HOST_DOMAIN-error
    CustomLog logs/$VIRTUAL_HOST_DOMAIN-access common

    Alias /webdav/ /home/webdav/$USER_NAME/
    Alias /webdav /home/webdav/$USER_NAME/
    <Directory /home/webdav/$USER_NAME/>
        Dav On
        AuthType Digest
        AuthName \"WebDAV\"
        AuthUserFile /etc/httpd/conf/webdav.users.pwd

        Options +Indexes
        IndexOptions FancyIndexing
        AddDefaultCharset UTF-8
        Require user $USER_NAME
        Order allow,deny
        Allow from all
    </Directory>

    Alias /static/ /home/$USER_NAME/django/$PROJECT_NAME/static/
    <Directory /home/$USER_NAME/django/$PROJECT_NAME/static/>
        Order deny,allow
        Allow from all
    </Directory>

    WSGIProcessGroup $VIRTUAL_HOST_DOMAIN
    WSGIDaemonProcess $VIRTUAL_HOST_DOMAIN user=$USER_NAME group=$USER_NAME python-path=/home/$USER_NAME/django/$PROJECT_NAME/:/home/$USER_NAME/.virtualenvs/$VIRTUAL_ENV/lib/python2.7/site-packages/
    WSGIScriptAlias / /home/$USER_NAME/django/$PROJECT_NAME/$PROJECT_NAME/wsgi.py

    <Directory /home/$USER_NAME/django/$PROJECT_NAME/>
        <Files wsgi.py>
            Order deny,allow
            Allow from all
        </Files>
    </Directory>
</VirtualHost>" > /etc/httpd/conf.d/$VIRTUAL_HOST_DOMAIN.conf
#fi

