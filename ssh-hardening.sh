#!/bin/bash
# for install ami tools 
sudo yum install -y aws-amitools-ec2 
export PATH=$PATH:/opt/aws/bin > /etc/profile.d/aws-amitools-ec2.sh 
sudo yum upgrade -y aws-amitools-ec2

#SSH Hardening
sudo sed -i  's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config 
sudo passwd -l root
sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
sudo sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config 

if [ ! -d /root/.ssh ] ; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
fi

# Fetch public key using HTTP
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \ 
 curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > /tmp/my-key
if [ $? -eq 0 ] ; then
        cat /tmp/my-key >> /root/.ssh/authorized_keys
        chmod 700 /root/.ssh/authorized_keys
        rm /tmp/my-key
fi
