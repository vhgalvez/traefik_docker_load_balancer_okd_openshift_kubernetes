
# Traefik Docker Load Balancer for OKD/OpenShift Kubernetes

Este proyecto configura un balanceador de carga utilizando **Traefik** en un entorno de **Docker** para gestionar OKD/OpenShift y Kubernetes.

## Descripción

El objetivo de este proyecto es proporcionar un balanceador de carga basado en Traefik para facilitar la configuración y gestión de un clúster OKD/OpenShift utilizando Docker. Además, se generan y configuran certificados SSL personalizados utilizando OpenSSL.

## Instalación

Sigue los pasos a continuación para instalar y configurar el entorno:

### 1. Crear los directorios necesarios

```bash
sudo mkdir -p /etc/traefik/custom-ca
sudo mkdir -p /etc/traefik/ssl
```

### 2. Generar la CA (Autoridad Certificadora)

#### 2.1. Generar la clave privada de la CA

```bash
cd /etc/traefik/custom-ca
sudo openssl genrsa -out myCA.key 4096
```

#### 2.2. Crear el certificado de la CA

```bash
sudo openssl req -x509 -new -nodes -key myCA.key -sha256 -days 1024 -out myCA.pem -subj "/CN=MyCustomCA"
```

#### 2.3. Copiar el certificado de la CA al almacén de confianza del sistema

```bash
sudo cp myCA.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

### 3. Copiar archivos de configuración a `/etc/traefik`

```bash
sudo cp -r /$PWD/* /etc/traefik/
```

### 4. Configuración del certificado SSL para el dominio

Si es necesario generar un certificado personalizado para tu dominio, asegúrate de que el script `openssl.sh` está preparado y luego ejecútalo:

```bash
sudo chmod +x ./openssl.sh
sudo ./openssl.sh
```

Esto generará los certificados necesarios para tu dominio en `/etc/traefik/ssl/`.

## Uso

### 1. Asegúrate de que Traefik está configurado correctamente

Verifica que el archivo `traefik.toml` esté configurado para usar los certificados SSL generados:

```toml
[tls]
  [[tls.certificates]]
    certFile = "/etc/traefik/ssl/cefaslocalserver.com.crt"
    keyFile = "/etc/traefik/ssl/cefaslocalserver.com.key"
```

### 2. Arrancar Traefik

Utiliza Docker Compose para iniciar Traefik con la configuración correcta. Para reiniciar o levantar Traefik, ejecuta:

```bash
docker-compose down && docker-compose up -d
```

## Verificación

Una vez que Traefik esté en funcionamiento, puedes verificar que está sirviendo correctamente el certificado SSL utilizando `curl`:

```bash
curl -v https://cefaslocalserver.com --insecure
```

Esto te permitirá comprobar que el certificado está siendo servido correctamente para el dominio especificado.

---

Este README debería proporcionar una estructura más clara para los usuarios que quieran instalar y utilizar el balanceador de carga Traefik en su entorno de OKD/OpenShift con Kubernetes. Si necesitas más ajustes o tienes alguna duda, ¡déjame saber!
