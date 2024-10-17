#!/bin/bash

# Crear directorios necesarios con permisos adecuados
sudo mkdir -p /etc/traefik/ssl
sudo mkdir -p /etc/traefik/custom-ca
sudo chmod 700 /etc/traefik/custom-ca
sudo chmod 700 /etc/traefik/ssl

# Verificar que los archivos CA existan
if [[ ! -f /etc/traefik/custom-ca/myCA.pem || ! -f /etc/traefik/custom-ca/myCA.key ]]; then
  echo "Los archivos myCA.pem o myCA.key no existen en /etc/traefik/custom-ca. Por favor, verifica."
  exit 1
fi

# Copiar el CA a /etc/myCA
sudo mkdir -p /etc/myCA
sudo cp /etc/traefik/custom-ca/myCA.pem /etc/myCA

# Crear archivo de configuración de OpenSSL
echo "Creando archivo de configuración de OpenSSL: /etc/traefik/ssl/extfile.cnf"
cat > /etc/traefik/ssl/extfile.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
CN = cefaslocalserver.com

[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = api.local.cefaslocalserver.com
DNS.2 = api-int.local.cefaslocalserver.com
EOF

# Generar clave privada
echo "Generando clave privada..."
openssl genrsa -out /etc/traefik/ssl/cefaslocalserver.com.key 4096

# Crear el CSR (Certificate Signing Request)
echo "Generando CSR..."
openssl req -new -key /etc/traefik/ssl/cefaslocalserver.com.key -out /etc/traefik/ssl/cefaslocalserver.com.csr -config /etc/traefik/ssl/extfile.cnf

# Firmar el certificado usando el CA personalizado
echo "Firmando el certificado con el CA personalizado..."
openssl x509 -req -in /etc/traefik/ssl/cefaslocalserver.com.csr -CA /etc/traefik/custom-ca/myCA.pem -CAkey /etc/traefik/custom-ca/myCA.key -CAcreateserial -out /etc/traefik/ssl/cefaslocalserver.com.crt -days 365 -extensions v3_req -extfile /etc/traefik/ssl/extfile.cnf
