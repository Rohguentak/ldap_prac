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
               
               
server HA 설정
-------------
              
syncprov 모듈 추가
               [root@server1 ~]# vi mod_syncprov.ldif
               dn: cn=module,cn=config
               objectClass: olcModuleList
               cn: module
               olcModulePath: /usr/lib64/openldap
               olcModuleLoad: syncprov.la

               [root@server1 ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f mod_syncprov.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               adding new entry "cn=module,cn=config"

               [root@server1 ~]# vi syncprov.ldif
               dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
               objectClass: olcOverlayConfig
               objectClass: olcSyncProvConfig
               olcOverlay: syncprov
               olcSpSessionLog: 100

               [root@server1 ~]# ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               adding new entry "olcOverlay=syncprov,olcDatabase={2}hdb,cn=config"
               


데이터 싱크 설정

               주석다 지우고 설정 해야 올바르게 설정 됨
               
               [root@server1 ~]# vi master01.ldif  
               dn: cn=config
               changetype: modify
               replace: olcServerID
               olcServerID: 0             //서버마다 다르게 설정

               dn: olcDatabase={2}hdb,cn=config
               changetype: modify
               add: olcSyncRepl
               olcSyncRepl: rid=001
                 # specify another LDAP server's URI (데이터 싱크 맞출 ldap서버 주소)
                 provider=ldap://192.168.12.11:389/
                 bindmethod=simple

                 # own domain name
                 binddn="cn=Manager,dc=srv,dc=world"
                 # directory manager's password
                 credentials=nexit1          ///slappasswd로 생성한 비밀번호 말고 입력한 비밀번호써야 함
                 searchbase="dc=srv,dc=world"
                 # includes subtree
                 scope=sub
                 schemachecking=on
                 type=refreshAndPersist
                 # [retry interval] [retry times] [interval of re-retry] [re-retry times]
                 retry="30 5 300 3"
                 # replication interval
                 interval=00:00:05:00
               -
               add: olcMirrorMode
               olcMirrorMode: TRUE

               dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
               changetype: add
               objectClass: olcOverlayConfig
               objectClass: olcSyncProvConfig
               olcOverlay: syncprov
               
               [root@server1 ~]# ldapmodify -Y EXTERNAL -H ldapi:/// -f master01.ldif
               SASL/EXTERNAL authentication started
               SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
               SASL SSF: 0
               modifying entry "cn=config"

               modifying entry "olcDatabase={2}hdb,cn=config"

               adding new entry "olcOverlay=syncprov,olcDatabase={2}hdb,cn=config"
               
add user 
--------
               [root@server1 ~]# slappasswd
               New password:
               Re-enter new password:
               {SSHA}xxxxxxxxxxxxxxxxx
               [root@server1 ~]# vi ldapuser.ldif
               # create new
               # replace to your own domain name for "dc=***,dc=***" section
               dn: uid=cent,ou=People,dc=srv,dc=world
               objectClass: inetOrgPerson
               objectClass: posixAccount
               objectClass: shadowAccount
               cn: Cent
               sn: Linux
               userPassword: {SSHA}xxxxxxxxxxxxxxxxx
               loginShell: /bin/bash
               uidNumber: 1000
               gidNumber: 1000
               homeDirectory: /home/cent

               dn: cn=cent,ou=Group,dc=srv,dc=world
               objectClass: posixGroup
               cn: Cent
               gidNumber: 1000
               memberUid: cent

               [root@server1 ~]# ldapadd -x -D cn=Manager,dc=srv,dc=world -W -f ldapuser.ldif
               Enter LDAP Password:
               adding new entry "uid=cent,ou=People,dc=srv,dc=world"

               adding new entry "cn=cent,ou=Group,dc=srv,dc=world"
               
               #####delete command#####
               [root@server1 ~]# ldapdelete -x -W -D 'cn=Manager,dc=srv,dc=world' "uid=cent,ou=People,dc=srv,dc=world"
               Enter LDAP Password:
               [root@server1 ~]# ldapdelete -x -W -D 'cn=Manager,dc=srv,dc=world' "cn=cent,ou=Group,dc=srv,dc=world"
               Enter LDAP Password:
               
               #####search user list#####
               [root@server1 ~]# ldapsearch -x -b 'ou=People,dc=srv,dc=world'

ldap client[1,2]
----------------
               [root@client1 ~]# yum install -y openldap-clients nss-pam-ldapd
               
               [root@client1 ~]# authconfig --enableldap \
               --enableldapauth \ 
               --ldapserver=server1.srv.world,server2.srv.world \
               --ldapbasedn="dc=srv,dc=world" \
               --enablemkhomedir \
               --update
               [root@client1 ~]# systemctl restart  nslcd
               
               [root@client1 ~]# getent passwd cent

               cent:x:1000:1000:Cent [Admin (at) local]:/home/cent:/bin/bash
               
