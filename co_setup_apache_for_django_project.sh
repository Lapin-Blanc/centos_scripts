#!/bin/bash
USER_NAME=fabien
VIRTUAL_ENV=django16
PROJECT_NAME=mysite
VIRTUAL_HOST_DOMAIN=fabien.toune.be

# Active les virtual hosts et WSGISocketPrefix
sed -i "s/^\(\s*\)#\s*\(NameVirtualHost.*\)$/\1\2/" /etc/httpd/conf/httpd.conf
if grep -q "WSGISocketPrefix" /etc/httpd/conf/httpd.conf
then 
    echo "WSGISocketPrefix already configured"
else 
    sed -i "/^\(\s*\)\(NameVirtualHost.*\)$/a\WSGISocketPrefix /var/run/wsgi" /etc/httpd/conf/httpd.conf
fi

# Active les virtual hosts
if grep -q "ServerName $VIRTUAL_HOST_DOMAIN" /etc/httpd/conf/httpd.conf
then 
    echo "Virtual host $VIRTUAL_HOST_DOMAIN already configured"
else 
    echo "
    <VirtualHost *:80>

        ServerAdmin webmaster@$VIRTUAL_HOST_DOMAIN
        ServerName $VIRTUAL_HOST_DOMAIN
        ErrorLog logs/$VIRTUAL_HOST_DOMAIN-error
        CustomLog logs/$VIRTUAL_HOST_DOMAIN-access common

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
    </VirtualHost>" >> /etc/httpd/conf/httpd.conf
fi

