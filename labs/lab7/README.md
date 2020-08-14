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