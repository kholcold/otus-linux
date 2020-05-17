mysql -e 'create database zabbix character set utf8 collate utf8_bin'
mysql -e 'create user zabbix@localhost identified by 'password''
mysql -e 'grant all privileges on zabbix.* to zabbix@localhost'
mysql -e 'FLUSH PRIVILEGES'