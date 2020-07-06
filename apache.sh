#!/bin/bash -v

cd /etc/pki/tls/certs ; sudo ./make-dummy-cert localhost.crt
sudo cat /etc/pki/tls/certs/localhost.crt | sudo sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' | sudo tee /etc/pki/tls/private/localhost.key
sudo cat /etc/pki/tls/certs/localhost.crt | sudo sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | sudo tee /etc/pki/tls/certs/cert.crt
sed -i 's/localhost.crt/cert.crt/g' /etc/httpd/conf.d/ssl.conf

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
  <title>PHP Test</title>
 </head>
 <body>
 <p>Hello AWS!</p>
 </body>
</html>
EOF

#determine Public IP 
public_ip=$(wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4)