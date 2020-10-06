mkdir -p /root/.ssh
cp /vagrant/id_rsa /root/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa
cp /vagrant/id_rsa.pub /root/.ssh/id_rsa.pub
chmod 0644 /root/.ssh/id_rsa.pub
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

