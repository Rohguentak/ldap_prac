# ldap_prac

   ######practice environment######
   --------------------------------
   
              |   host name       |     역할	    |     Ip      |       os       |
              -------------------------------------------------------------------               
              | server1.srv.world	| ldap server1 |192.168.12.10|    centos7.8   |
              -------------------------------------------------------------------
              | server2.srv.world	| ldap server2 |192.168.12.11|    centos7.8   |
              -------------------------------------------------------------------
              | client1.srv.world |	 nfs client  |192.168.12.20|        "       | 
              -------------------------------------------------------------------
              | client2.srv.world |	 nfs client  |192.168.12.21|        "       |
              -------------------------------------------------------------------
              
              각각 ssh passwordless 접속 설정
              firewall disabled
              selinux disabled
 
 server
 ------
              
               [root@server ~]# yum -y install openldap-servers openldap-clients
               [root@server ~]# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
               [root@server ~]# systemctl enable --now slapd

ldap 관리용 비밀 번호 설정
 
               [root@server ~]# slappasswd
               New password: admin
               Re-enter new password: admin 
               {SSHA}d/thexcQUuSfe3rx3gRaEhHpNJ52N8D3

olcRootPW 섹션의 password설정
 
               [root@server ~]# vi chrootpw.ldif
               dn: olcDatabase={0}config,cn=config
               changetype: modify
               add: olcRootPW
               olcRootPW: {SSHA}d/thexcQUuSfe3rx3gRaEhHpNJ52N8D3
               
               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
               
기본 schema import

               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               adding new entry "cn=cosine,cn=schema,cn=config"

               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               adding new entry "cn=nis,cn=schema,cn=config"

               [root@server ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               adding new entry "cn=inetorgperson,cn=schema,cn=config"
               
directory manager password설정

               [root@dlp ~]# slappasswd
               New password: nexit1
               Re-enter new password: nexit1
               {SSHA}xxxxxxxxxxxxxxxxxxxxxxxx
               
               
디렉토리 구조 생성 

               [root@dlp ~]# vi chdomain.ldif
               dn: olcDatabase={1}monitor,cn=config
               changetype: modify
               replace: olcAccess
               olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=srv,dc=world" read by * none

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               replace: olcSuffix
               olcSuffix: dc=srv,dc=world

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               replace: olcRootDN
               olcRootDN: cn=Manager,dc=srv,dc=world

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               add: olcRootPW
               olcRootPW: {SSHA}xxxxxxxxxxxxxxxxxxxxxxxx        //directory manager password

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               add: olcAccess
               olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=Manager,dc=srv,dc=world" write by anonymous auth by self write by * none
               olcAccess: {1}to dn.base="" by * read
               olcAccess: {2}to * by dn="cn=Manager,dc=srv,dc=world" write by * read
               
               
               
               [root@server ~]# ldapmodify -Y EXTERNAL -H ldapi:/// -f chdomain.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               modifying entry "olcDatabase={1}monitor,cn=config"
 
               modifying entry "olcDatabase={2}hdb,cn=config"
 
               modifying entry "olcDatabase={2}hdb,cn=config"
 
               modifying entry "olcDatabase={2}hdb,cn=config"
           
           
           
               [root@dlp ~]# vi basedomain.ldif
               dn: dc=srv,dc=world
               objectClass: top
               objectClass: dcObject
               objectclass: organization
               o: Server World
               dc: Srv

               dn: cn=Manager,dc=srv,dc=world
               objectClass: organizationalRole
               cn: Manager
               description: Directory Manager

               dn: ou=People,dc=srv,dc=world
               objectClass: organizationalUnit
               ou: People

               dn: ou=Group,dc=srv,dc=world
               objectClass: organizationalUnit
               ou: Group
                     
           
               [root@dlp ~]# ldapadd -x -D cn=Manager,dc=srv,dc=world -W -f basedomain.ldif
               Enter LDAP Password:     # directory manager's password
               adding new entry "dc=srv,dc=world"

               adding new entry "cn=Manager,dc=srv,dc=world"
 
               adding new entry "ou=People,dc=srv,dc=world"
 
               adding new entry "ou=Group,dc=srv,dc=world"
  
  
ldap 설정 오류 확인

               [root@server ~]# slaptest -u
               config file testing succeeded
               
               

               

               
               
               
add user 
--------
               [root@server ~]# vi raj.ldif
               dn: uid=raj,ou=People,dc=local
               objectClass: top
               objectClass: account
               objectClass: posixAccount
               objectClass: shadowAccount
               cn: raj
               uid: raj
               uidNumber: 1004
               gidNumber: 100
               homeDirectory: /home/raj
               loginShell: /bin/bash
               gecos: Raj [Admin (at) local]
               userPassword: {crypt}x
               shadowLastChange: 17058
               shadowMin: 0
               shadowMax: 99999
               shadowWarning: 7
               
               [root@server ~]# ldapadd -x -W -D "cn=ldapadm,dc=local" -f raj.ldif
               
               [root@server ~]# ldappasswd -s password -W -D "cn=ldapadm,dc=local" -x "uid=raj,ou=People,dc=local"
               
               
               (option : delete || ldapdelete -W -D "cn=ldapadm,dc=local" "uid=raj,ou=People,dc=local")

ldap client[1,2]
----------------
               [root@client1 ~]# yum install -y openldap-clients nss-pam-ldapd
               
               [root@client1 ~]# authconfig --enableldap --enableldapauth --ldapserver=192.168.12.10 --ldapbasedn="dc=local" --enablemkhomedir --update
               
               [root@client1 ~]# systemctl restart  nslcd
               
               [root@client1 ~]# getent passwd raj

               raj:x:1004:100:Raj [Admin (at) local]:/home/raj:/bin/bash
               
