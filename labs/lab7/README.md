#### 1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

Cоздаём файл с конфигурацией для сервиса в директории
```/etc/sysconfig``` - из неё сервис будет брать необходимую переменную.

```
[root@otuslinux ~]# nano /etc/sysconfig/watchlog

# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```
Затем создаем ```/var/log/watchlog.log``` и пишем туда строки на своё усмотрение, плюс ключевое слово "ALERT"

```
[root@otuslinux ~]# touch /var/log/watchlog.log
```

Создадим скрипт:
```
[root@otuslinux ~]# nano /opt/watchlog.sh

#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
    logger "$DATE: I found word, Master!"
else
    exit 0
fi
```
Команда ```logger``` отправлāет лог в системный журнал

Создадим юнит для сервиса:
```
[root@otuslinux ~]# nano /etc/systemd/system/watchlog.service

[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
Создадим юнит для таймера:
```
[root@otuslinux ~]# nano /etc/systemd/system/watchlog.timer

[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```

Запускаем timer:
```
[root@otuslinux sysconfig]# systemctl start watchlog.timer
```

#### 2. Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.

Устанавливаем spawn-fcgi и необходимые для него пакеты:
```
[root@server ~]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
```/etc/rc.d/init.d/spawn-fcgi``` init скрипт, который будем переписывать

Раскомментируем строки с переменными в ```/etc/sysconfig/spawn-fcgi```
```
[root@server ~]# cat /etc/sysconfig/spawn-fcgi

# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```

А сам юнит файл будет примерно следующего вида:

```
[root@server ~]# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Проверяем, что все успешно работает:
```
[root@server ~]# systemctl start spawn-fcgi
[root@server ~]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2020-08-14 12:22:15 UTC; 4s ago
 Main PID: 5355 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─5355 /usr/bin/php-cgi
           ├─5356 /usr/bin/php-cgi
```

#### 3. Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Для запуска нескольких экземпляров сервиса будем использовать шаблон в
конфигурации файла окружения:
```
[root@server ~]# systemctl cat httpd
# /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I <--Добавим параметр %I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
```

В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
```
# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf

# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```
Соответственно в директории с конфигами httpd должны лежать два конфига, в нашем случае что будут first.conf и second.conf

Для удачного запуска, в конфигурационных файлах должны быть указаны
уникальные для каждого экземплāра опции Listen и PidFile. Конфиги можно
скопировать и поправить только второй, в нем должны быть след опции:

```
PidFile /var/run/httpd-second.pid
Listen 8080
```
Создадим файл для запуска:
```
[root@server system]# cat /etc/systemd/system/httpd@.service 
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Запускае и проверяем работу:
```
systemctl start httpd@first
systemctl status httpd@first
systemctl start httpd@second
systemctl status httpd@second
```
```
[root@server system]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=24896,fd=4),("httpd",pid=24895,fd=4),("httpd",pid=24894,fd=4),("httpd",pid=24893,fd=4),("httpd",pid=24892,fd=4),("httpd",pid=24891,fd=4),("httpd",pid=24890,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=24882,fd=4),("httpd",pid=24881,fd=4),("httpd",pid=24880,fd=4),("httpd",pid=24879,fd=4),("httpd",pid=24878,fd=4),("httpd",pid=24877,fd=4),("httpd",pid=24876,fd=4))
```