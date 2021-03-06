yum -y groupinstall Desktop
yum -y install tigervnc-server tigervnc-server-applet
yum -y install xorg-x11-fonts-Type1 terminus-fonts terminus-fonts-console  urw-fonts

# as user : 
vncpasswd

# as root again :
vim /etc/sysconfig/vncservers

# at the end of file :
VNCSERVERS="1:user"
VNCSERVERARGS[2]="-geometry 1280x800"

# open firewall port 5901
-A INPUT -m state --state NEW -m tcp -p tcp -m multiport --dports 5801,5901 -j ACCEPT

service vncserver start
chkconfig vncserver on
