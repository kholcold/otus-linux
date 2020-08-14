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