Смотрим список дисков
```
[vagrant@otuslinux ~]$ sudo lshw -short | grep disk
0/100/1.1/0.0.0    /dev/sda  disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb  disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc  disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd  disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde  disk        262MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf  disk        262MB VBOX HARDDISK
```
Смотрим таблицу разделов
```
[vagrant@otuslinux ~]$ sudo fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef88

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdb: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdd: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sde: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdf: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

```
Занулим супер блоки
```
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf

```
Создадим raid10
```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
Проверим что raid собрался
```
[vagrant@otuslinux ~]$ cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
```

```
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0 
/dev/md0:
           Version : 1.2
     Creation Time : Tue Feb 11 20:37:17 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Feb 11 20:37:20 2020
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 642f1ded:8f61261c:90f0389b:d93d575e
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
```
Убедимся что информация верна
```
[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=642f1ded:8f61261c:90f0389b:d93d575e
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde

```
Создаем файл mdadm.conf
```
[root@otuslinux vagrant]# echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
[root@otuslinux vagrant]# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
[root@otuslinux vagrant]# cat /etc/mdadm/mdadm.conf 
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=642f1ded:8f61261c:90f0389b:d93d575e
```
Сломать/починить raid10
Искусственно "зафейлим" одно блочное устройство
```
[root@otuslinux vagrant]# mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```
Смотрим как это отразилось на raid
```
[root@otuslinux vagrant]# cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sde[3](F) sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]

[root@otuslinux vagrant]# mdadm -D /dev/md0
Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       -       0        0        3      removed

       3       8       64        -      faulty   /dev/sde
```
Удалим "сломаный диск из массива"
```
[root@otuslinux vagrant]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```
Вставим "новый" диск
```
[root@otuslinux vagrant]# mdadm /dev/md0 --add /dev/sdf
mdadm: added /dev/sdf
```
Смотрим результат
```
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

[root@otuslinux vagrant]# mdadm -D /dev/md0
 Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       4       8       80        3      active sync set-B   /dev/sdf
```
## Создать GPT раздел, пять партиций и смонтировать их на диск
Создаем раздел GPT на RAID
```
[root@otuslinux vagrant]# parted -s /dev/md0 mklabel gpt
[root@otuslinux vagrant]# fdisk -l

Disk /dev/md0: 520 MB, 520093696 bytes, 1015808 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 524288 bytes / 1048576 bytes
Disk label type: gpt
Disk identifier: 52FD6533-BA6A-460B-8E71-76A6F96E623A
```
Создаем партиции 
```
[root@otuslinux vagrant]# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

[root@otuslinux vagrant]# parted /dev/md0 mkpart primary ext4 20% 40%     
Information: You may need to update /etc/fstab.

[root@otuslinux vagrant]#  parted /dev/md0 mkpart primary ext4 40% 60%    
Information: You may need to update /etc/fstab.

[root@otuslinux vagrant]# parted /dev/md0 mkpart primary ext4 60% 80%     
Information: You may need to update /etc/fstab.

[root@otuslinux vagrant]# parted /dev/md0 mkpart primary ext4 80% 100%    
Information: You may need to update /etc/fstab.
```
Создаем на этих партициях файловую систему
```
[root@otuslinux ~]# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25168 inodes, 100352 blocks
5017 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1936 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
Смонтируем их по каталогам
```
[root@otuslinux ~]#  mkdir -p /raid/part{1,2,3,4,5}
[root@otuslinux ~]# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
[root@otuslinux ~]# ls /raid/part
part1/ part2/ part3/ part4/ part5/
```
