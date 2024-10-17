#!/bin/bash

# Crear directorios necesarios con permisos adecuados
sudo mkdir -p /etc/traefik/ssl
sudo mkdir -p /etc/traefik/custom-ca
sudo mkdir -p /etc/pki/ca-trust/source/anchors
sudo chmod 700 /etc/traefik
sudo chmod 700 /etc/traefik/custom-ca
sudo chmod 700 /etc/traefik/ssl

# Copiar el certificado de la CA a anchors y actualizar el almacén de confianza del sistema
sudo cp custom-ca/myCA.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust extract

# Verificar si los archivos CA ya existen; si no, generarlos
if [[ ! -f /etc/traefik/custom-ca/myCA.pem || ! -f /etc/traefik/custom-ca/myCA.key ]]; then
    echo "Generando myCA.pem y myCA.key en /etc/traefik/custom-ca..."
    
    # Generar la clave privada de la CA
    sudo openssl genrsa -out /etc/traefik/custom-ca/myCA.key 4096
    if [[ $? -ne 0 ]]; then
        echo "Error al generar la clave privada de la CA."
        exit 1
    fi

    # Crear el certificado de la CA
    sudo openssl req -x509 -new -nodes -key /etc/traefik/custom-ca/myCA.key -sha256 -days 1024 -out /etc/traefik/custom-ca/myCA.pem -subj "/CN=MyCustomCA"
    if [[ $? -ne 0 ]]; then
        echo "Error al generar el certificado de la CA."
        exit 1
    fi
else
    echo "Los archivos myCA.pem y myCA.key ya existen en /etc/traefik/custom-ca. Saltando generación de CA."
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

# Generar clave privada para el certificado del servidor
echo "Generando clave privada para cefaslocalserver.com..."
openssl genrsa -out /etc/traefik/ssl/cefaslocalserver.com.key 4096
if [[ $? -ne 0 ]]; then
    echo "Error al generar la clave privada para cefaslocalserver.com."
    exit 1
fi

# Crear el CSR (Certificate Signing Request)
echo "Generando CSR para cefaslocalserver.com..."
openssl req -new -key /etc/traefik/ssl/cefaslocalserver.com.key -out /etc/traefik/ssl/cefaslocalserver.com.csr -config /etc/traefik/ssl/extfile.cnf
if [[ $? -ne 0 ]]; then
    echo "Error al generar el CSR para cefaslocalserver.com."
    exit 1
fi

# Firmar el certificado usando el CA personalizado
echo "Firmando el certificado con el CA personalizado..."
openssl x509 -req -in /etc/traefik/ssl/cefaslocalserver.com.csr -CA /etc/traefik/custom-ca/myCA.pem -CAkey /etc/traefik/custom-ca/myCA.key -CAcreateserial -out /etc/traefik/ssl/cefaslocalserver.com.crt -days 365 -extensions v3_req -extfile /etc/traefik/ssl/extfile.cnf
if [[ $? -ne 0 ]]; then
    echo "Error al firmar el certificado de cefaslocalserver.com."
    exit 1
fi

echo "Certificado generado correctamente en /etc/traefik/ssl/cefaslocalserver.com.crt"
