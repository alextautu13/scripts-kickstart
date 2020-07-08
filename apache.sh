#!/bin/bash -v


# configure httpd 

systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user" 
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find, /var/www, -type, d, -exec, chmod, 2775, {}, \; 
find, /var/www, -type, f, -exec, chmod, 0664, {}, \; 
 

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

public_ip=$(wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4)

tee /etc/httpd/conf.d/redirect.conf <<EOF
<VirtualHost *:80>
ServerName $public_ip
Redirect permanent / https://$public_ip/
</VirtualHost>
EOF

# restart httpd 
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
