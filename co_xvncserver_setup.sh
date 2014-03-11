yum -y groupinstall Desktop
yum -y install tigervnc-server
yum -y install xorg-x11-fonts-Type1 terminus-fonts terminus-fonts-console  urw-fonts mplayer-fonts xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi liberation-fonts-common liberation-sans-fonts

chkconfig vncserver on
# as user : 
vncpasswd
# as root again :
vim /etc/sysconfig/vncservers
# at the end of file :
VNCSERVERS="1:user"
VNCSERVERARGS[2]="-geometry 1280x800"
# open firewall port 5901
