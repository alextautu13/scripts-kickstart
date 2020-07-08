#!/bin/bash -v


# configure httpd 

systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www, -type, d, -exec, chmod, 2775, {}, \; 
find /var/www, -type, f, -exec, chmod, 0664, {}, \; 
 

# check if apache is enabled 

is_enabled=$(systemctl is-enabled http)

if [ "$is_enabled" = "disabled" ]
then 
systemctl start httpd
systemctl enable httpd

fi


# add dummy certs 
cd /etc/pki/tls/certs ; sudo ./make-dummy-cert localhost.crt
sudo cat /etc/pki/tls/certs/localhost.crt | sudo sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' | sudo tee /etc/pki/tls/private/localhost.key
sudo cat /etc/pki/tls/certs/localhost.crt | sudo sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | sudo tee /etc/pki/tls/certs/cert.crt
sed -i 's/localhost.crt/cert.crt/g' /etc/httpd/conf.d/ssl.conf


#/usr/lib/systemd/system/httpd.service
#PUBLIC_IPV4=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4)
#PUBLIC_HOSTNAME=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-hostname)


tee /usr/lib/systemd/system/httpd.service <<EOF

# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#	[Service]
#	Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

#custom variables for EC2 Public IP and Hostname 
PUBLIC_IPV4=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_HOSTNAME=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-hostname)

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# add http to https redirect 
 
tee /etc/httpd/conf.d/redirect.conf <<EOF
<VirtualHost *:80>
ServerName ${PUBLIC_IPV4}
Redirect permanent / https://${PUBLIC_IPV4}/
</VirtualHost>

<VirtualHost *:80>
ServerName ${PUBLIC_HOSTNAME}
Redirect permanent / https://${PUBLIC_HOSTNAME}/
</VirtualHost>             

EOF 


# restart reload service change and restart httpd 
systemctl daemon-reload
systemctl restart httpd 


# create index.html
tee /var/www/html/index.html <<EOF
<html>
 <head>
  <title>Hello AWS Test Page </title>
 </head>
 <body>
 <p>Hello AWS!</p>
 </body>
</html>
EOF


