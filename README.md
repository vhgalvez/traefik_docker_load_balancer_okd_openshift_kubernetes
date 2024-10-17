# traefik_docker_load_balancer_okd_openshift_kubernetes
 
traefik_docker_load_balancer_okd_openshift_kubernetes

## Description





## Installation

sudo mkdir -p /etc/traefik/custom-ca
cd /etc/traefik/custom-ca

# Generar la clave privada de la CA
sudo openssl genrsa -out myCA.key 4096

# Crear el certificado de la CA
sudo openssl req -x509 -new -nodes -key myCA.key -sha256 -days 1024 -out myCA.pem -subj "/CN=MyCustomCA"



```bash
sudo cp -r /$PWD/*  /etc/traefik/
```



## Usage

```bash
sudo chmod +x ./openssl.sh
sudo ./openssl.sh


