#!/bin/bash
sudo mkdir -p /etc/traefik/ssl
sudo mkdir -p /etc/traefik/custom-ca
sudo mkdir -p /etc/myCA
sudo chmod 700 /etc/traefik/custom-ca
sudo chmod 700 /etc/traefik/ssl
sudo cp /etc/traefik/custom-ca/myCA.pem /etc/myCA

# Crear el archivo de configuración de OpenSSL (extfile.cnf)
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