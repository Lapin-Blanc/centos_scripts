# OS: CentOS 6 64bit
# VPN server:  209.85.227.26
# VPN client IP: 209.85.227.27 - 209.85.227.30
# VPN username: vpnuser
# Password: myVPN$99

yum install ppp -y
cd /usr/local/src
wget http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.4.0-1.el6.x86_64.rpm
rpm -Uhv pptpd-1.4.0-1.el6.x86_64.rpm

# Open /etc/pptpd.conf using text editor and add following line:
localip 209.85.227.26
remoteip 209.85.227.27-30

# Open /etc/ppp/options.pptpd and add  authenticate method, encryption and DNS resolver value:

require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8

# Open /etc/ppp/chap-secrets and add the user as below:
vpnuser pptpd myVPN$99 *

# Open /etc/sysctl.conf via text editor and change line below:
net.ipv4.ip_forward = 1

# Run following command to take effect on the changes:
sysctl -p

# Allow IP masquerading in IPtables by executing following line:
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save
service iptables restart

# Update: Once you have done with step 8, check the rules at /etc/sysconfig/iptables. Make sure that the POSTROUTING rules is above any REJECT rules.

# Turn on the pptpd service at startup and launch it:
chkconfig pptpd on
service pptpd start
