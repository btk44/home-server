## Docker Installation

### 0. Documentation

Everything described in this guide comes from the official documentation: [Docker Engine Installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/).


### 1. Docker Repository Configuration

Open a terminal and connect to the server:
```
ssh USER@192.168.XXX.XXX
```

In the terminal, we run the following commands from the documentation in order:
```
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```
```
sudo apt update
```

---

### 2. Package Installation

After updating the APT packages from the previous step, we run the installation command:
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
---

### 3. Starting the Service

After the installation is complete, we check the Docker service status:
```
sudo systemctl status docker
```
If the service is not active (`active`), we start it with the command:
```
sudo systemctl start docker
```
---

### 4. Creating a Folder for Container Configuration and Data

We create a directory where we will store Docker configurations and data:
```
mkdir docker
```
---

**I strongly recommend treating this guide as outdated and using the official Docker documentation provided at the beginning.**
