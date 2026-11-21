### 0. Setup assumptions

This setup assumes that you have:
- Ubuntu server installed with LVM and LUKS encryption 
- OpenSSH server installed during Ubuntu installation process
- your server is connected to router with internet cable (not wifi)

### 1. Generate SSH Keys on Clients

#### Windows: 
- open `powershell` or `cmd`
- run command 
  ```bash
  ssh-keygen -t rsa -b 4096 -C "windows-pc" 
  ```
- follow the prompts (mosty confirm all with `Enter`)
- result should be saved:
    - private key: `C:\Users\YourUsername\.ssh\id_rsa`
    - public key: `C:\Users\YourUsername\.ssh\id_rsa.pub`

#### Linux:
- open terminal
- run command 
  ```bash
  ssh-keygen -t rsa -b 4096 -C "linux-pc" 
  ```
- follow the prompts (mosty confirm all with `Enter`)
- result should be saved:
    - private key: `~/.ssh/id_rsa`
    - public key: `~/.ssh/id_rsa.pub`

#### Android:
- install Termux 
- run commands
  ```bash
  pkg update && pkg install openssh
  ssh-keygen -t rsa -b 4096 -C "android-phone"
  ```
- result should be saved:
    - private key: `~/.ssh/id_rsa`
    - public key: `~/.ssh/id_rsa.pub`

### 2. Copy keys to Ubuntu Server

- turn on Ubuntu Server with monitor and keyboard plugged in
- enter encryption passphrase during boot
- once system is booted log in with your user and password
- run following commands:
  ```bash
  mkdir -p ~/.ssh nano 
  ~/.ssh/authorized_keys 
  ```
- save empty file `ctrl+o -> enter -> ctrl+x`

- from each device (windows, linux, android)
    - copy `id_rsa.pub` content
    - run below command and enter your password (provide server's ip instead of `xxx`) 
      ```bash 
      ssh user@192.168.xxx.xxx 
      ``` 
      
    - run command 
      ```bash
      nano .ssh/authorized_keys
      ```
    - paste content as one line (if there is already one, hit `Enter` to make another line)
    - save file `ctrl+o -> enter -> ctrl+x`
    - run command `exit`
    - try to run command `ssh user@192.168.xxx.xxx` and you should no longer be asked for password
- when all keys are pasted in the file run command:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  ```

### 3. Set up pre-boot SSH

**imortant note:** this will work only when server is connected to network with cable, wifi will not work.

Since the server requires a passphrase to boot we will need to be able to connect to pre-boot state (initramfs) to provide it. To make it work We need to go to server's terminal or ssh to it from other pc.

- run command: `ssh user@192.168.xxx.xxx`
- run commands:
  ```bash
  sudo apt update
  sudo apt install dropbear-initramfs
  ```
- ignore warings about invalid authorized keys
- run commands: 
  ```bash
  sudo cp .ssh/authorized_keys /etc/dropbear/initramfs/authorized_keys
  sudo chmod 600 /etc/dropbear/initramfs/authorized_keys
  ```
- run command `ip link` and note the name of your network cable interface, i.e. `eth0` or `enp3s0`
- modify config file with 
  ```bash
  sudo nano /etc/initramfs-tools/initramfs.conf
  ```
- insert the address that dropbear will use to listen to any ssh connections. Follow this format `IP=server_ip::gateway_ip:netmask:hostname:network_interface:off`. The line should look like this:
  ```
  IP=192.168.1.100::192.168.1.1:255.255.255.0:ubuntuserver:eth0:off
  ```
- save file `ctrl+o -> enter -> ctrl+x`
- run below command and make sure it returns no errors 
  ```bash
  sudo update-initramfs -u
  ```
- run command `sudo reboot` to restart the system

### 4. Unlock server and connect

Once pre-boot setup is done and the system is restarted you can try to unlock it remotely. In your other pc/phone open terminal and:
- run command (use ip from dropbear config file set up above):
``` ssh root@192.168.1.100 ``` (you may need to add `-p 2222` in case connection is refused)
- once connected run command ` cryptroot-unlock `
- enter passphrase and hit `Enter`
- you should now be automatically disconnected
- let the server boot up 2 minutes and run command:
``` ssh user@192.168.xxx.xxx ```
- you should now be connected to unlocked server

### 5. Disable ssh password

When you ssh connect to the server with a key then:
- open sshd config
  ```bash
  sudo nano /etc/ssh/sshd_config
  ```
- make sure these lines are uncommented and set to following values:
  ```
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  PubkeyAuthentication yes
  ```
- save `ctrl+o -> enter -> ctrl+x`
- validate config and restart ssh:
  ```
  sudo sshd -t
  sudo systemctl restart ssh
  ```
