# ldap_prac

   ######practice environment######
   --------------------------------
   
                host name   |     역할	   |      Ip      |       os       |
              --------------------------------------------------------------               
              server.local	 | ldap server  |	192.168.12.10|    centos7.8   |
              --------------------------------------------------------------
              client1.local |	nfs server   |	192.168.12.20|        "       | 
              --------------------------------------------------------------
              client2.local |	nfs client   |	192.168.12.21|        "       |
              --------------------------------------------------------------
              
              각각 ssh passwordless 접속 설정
              firewall disabled
              selinux disabled
 
 server
 ------
              
               [root@server ~]# yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel

               [root@server ~]# systemctl enable --now slapd

               [root@server ~]# slappasswd
                              New password: 
                              Re-enter new password: 
                              {SSHA}d/thexcQUuSfe3rx3gRaEhHpNJ52N8D3

               [root@server ~]# vi db.ldif

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               replace: olcSuffix
               olcSuffix: dc=local

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               replace: olcRootDN
               olcRootDN: cn=ldapadm,dc=local

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               replace: olcRootPW
               olcRootPW: {SSHA}QF+jBFJ/RWGVwPuDzQI87YJfJtKOYGhK

               [root@server ~]# ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif
               [root@server ~]# vi monitor.ldif
               dn: olcDatabase={1}monitor,cn=config
               changetype: modify
               replace: olcAccess
               olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=local" read by * none

               [root@server ~]# ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

               [root@server ~]# openssl req -new -x509 -nodes -out /etc/openldap/certs/ldapcert.pem -keyout /etc/openldap/certs/ldapkey.pem -days 365

               [root@server ~]# chown -R ldap:ldap /etc/openldap/certs/*.pem

               [root@server ~]# vi certs.ldif

               dn: cn=config
               changetype: modify
               replace: olcTLSCertificateFile
               olcTLSCertificateFile: /etc/openldap/certs/ldapcert.pem

               dn: cn=config
               changetype: modify
               replace: olcTLSCertificateKeyFile
               olcTLSCertificateKeyFile: /etc/openldap/certs/ldapkey.pem 

               [root@server ~]# ldapmodify -Y EXTERNAL  -H ldapi:/// -f certs.ldif
               [root@server ~]# slaptest -u
               config file testing succeeded

               [root@server ~]# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
               [root@server ~]# chown ldap:ldap /var/lib/ldap/*

               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
               [root@server ~]# vi base.ldif

               dn: dc=local
               dc: local
               objectClass: top
               objectClass: domain

               dn: cn=ldapadm ,dc=local
               objectClass: organizationalRole
               cn: ldapadm
               description: LDAP Manager

               dn: ou=People,dc=local
               objectClass: organizationalUnit
               ou: People

               dn: ou=Group,dc=local
               objectClass: organizationalUnit
               ou: Group

               [root@server ~]# ldapadd -x -W -D "cn=ldapadm,dc=itzgeek,dc=local" -f base.ldif
               Enter LDAP Password: 
               adding new entry "dc=itzgeek,dc=local"

               adding new entry "cn=ldapadm ,dc=itzgeek,dc=local"

               adding new entry "ou=People,dc=itzgeek,dc=local"

               adding new entry "ou=Group,dc=itzgeek,dc=local"
