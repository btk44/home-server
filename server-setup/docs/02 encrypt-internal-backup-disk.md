### 0. Setup assumptions

This setup assumes that you have:
- Ubuntu server installed
- OpenSSH server installed during Ubuntu installation process and have it configured with passwords or keys
- additional disk build in server pc or attached to it

### 1. Install packages

Below packages should be already installed in Ubuntu, but in case they are missing run command:
```
sudo apt update
sudo apt install cryptsetup rsync -y
```

### 2. Identify and encrypt the disk

Once the disk is attached to Ubuntu server run following command:
```
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```
You should see output similar to this:
```
NAME                          SIZE MODEL           SERIAL          FSTYPE      MOUNTPOINTS
...
loop3                         1.5M                                 squashfs    /snap/hwctl/131
sdb                         931.5G Samsung SSD 870 xxxxxxxxxxxxxxx
└─sdb1                      931.5G                                 exfat
nvme0n1                     931.5G CT1000P3PSSD8   xxxxxxxxxxxx
├─nvme0n1p1                     1G                                 vfat        /boot/efi
```

In this case it is `sdb`

- run following commands to create partition table (**this will erase all data from the disk**)
  ```bash
  sudo parted /dev/sdb --script mklabel gpt
  sudo parted /dev/sdb --script mkpart primary 1MiB 100%
  ```
- werify it worked (there is a new partition */dev/sdb1*)
  ```bash
  lsblk /dev/sdb
  ```
- encrypt the partition using *LUKS2* and verify the result
  ```bash
  sudo cryptsetup luksFormat --type luks2 /dev/sdb1
  -> enter passphrase when prompted
  sudo cryptsetup luksDump /dev/sdb1
  ```
- unlock the encrypted partition
  ```bash
  sudo cryptsetup open /dev/sdb1 encrypted_disk
  -> enter passphrase when prompted
  ```
- unlocked device should be available at `/dev/mapper/encrypted_disk`
- create the ext4 filesystem
  ```bash
  sudo mkfs.ext4 -L encrypted-backup /dev/mapper/encrypted_disk
  ```
- create the mount directory and mount
  ```bash
  sudo mkdir -p /mnt/backup
  sudo mount /dev/mapper/encrypted_disk /mnt/backup
  ```
- verify 
  ```bash
  df -h /mnt/backup
  ```
- unmount and close the disk
  ```bash
  sudo sync
  sudo umount /mnt/backup
  sudo cryptsetup close encrypted_disk
  lsblk -f
  ```
- at this point you should no logner see `/dev/mapper/encrypted_disk`

The disk is set up.

### 3. Mount, save and umount

Once the disk is set up we can perform a backup:
- decrypt disk:
  ```bash
  sudo cryptsetup open /dev/sdb1 encrypted_disk 
  ```
- mount
  ```bash
  sudo mount /dev/mapper/encrypted_disk /mnt/backup
  ```
- run backup
  ```bash
  sudo rsync -aHAX --numeric-ids /home/ /mnt/backup/home/
  ```
- unmount
  ```bash
  sudo sync
  sudo umount /mnt/backup
  ```
- lock
  ```bash
  sudo cryptsetup close encrypted_disk 
  ```

