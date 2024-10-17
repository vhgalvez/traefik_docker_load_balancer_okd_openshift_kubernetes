#!/bin/bash

# Step 1: Create necessary directories with appropriate permissions
sudo mkdir -p /etc/traefik/ssl
sudo mkdir -p /etc/traefik/custom-ca
sudo mkdir -p /etc/pki/ca-trust/source/anchors

# Set directory permissions
sudo chmod 700 /etc/traefik
sudo chmod 700 /etc/traefik/custom-ca
sudo chmod 700 /etc/traefik/ssl
sudo chmod 755 /etc/traefik
sudo chmod 755 /etc/traefik/ssl

# Step 2: Remove old CA files if they exist
sudo rm -f /etc/traefik/custom-ca/myCA.pem /etc/traefik/custom-ca/myCA.key /etc/traefik/custom-ca/myCA.srl

# Step 3: Generate CA private key
echo "Generating CA private key..."
sudo openssl genrsa -out /etc/traefik/custom-ca/myCA.key 4096
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to generate CA private key."
    exit 1
fi

# Step 4: Create CA certificate
echo "Creating CA certificate..."
sudo openssl req -x509 -new -nodes -key /etc/traefik/custom-ca/myCA.key -sha256 -days 1024 -out /etc/traefik/custom-ca/myCA.pem -subj "/CN=MyCustomCA"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create CA certificate."
    exit 1
fi

# Step 5: Copy CA certificate to trusted store and update trust
echo "Copying CA certificate to trusted store and updating..."
sudo cp /etc/traefik/custom-ca/myCA.pem /etc/pki/ca-trust/source/anchors/myCA.pem
sudo update-ca-trust extract
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to update trusted certificates."
    exit 1
fi

# Step 6: Create OpenSSL config file for the server certificate
echo "Creating OpenSSL configuration..."
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

# Step 7: Generate private key for the server certificate
echo "Generating private key for server certificate..."
openssl genrsa -out /etc/traefik/ssl/cefaslocalserver.com.key 4096
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to generate private key for server certificate."
    exit 1
fi

# Step 8: Create the Certificate Signing Request (CSR)
echo "Generating CSR for server certificate..."
openssl req -new -key /etc/traefik/ssl/cefaslocalserver.com.key -out /etc/traefik/ssl/cefaslocalserver.com.csr -config /etc/traefik/ssl/extfile.cnf
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to generate CSR."
    exit 1
fi

# Step 9: Sign the server certificate with the custom CA
echo "Signing server certificate with the custom CA..."
openssl x509 -req -in /etc/traefik/ssl/cefaslocalserver.com.csr -CA /etc/traefik/custom-ca/myCA.pem -CAkey /etc/traefik/custom-ca/myCA.key -CAcreateserial -out /etc/traefik/ssl/cefaslocalserver.com.crt -days 365 -extensions v3_req -extfile /etc/traefik/ssl/extfile.cnf
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to sign the server certificate."
    exit 1
fi

# Step 10: Adjust permissions for the certificate and key files
sudo chmod 644 /etc/traefik/ssl/*.crt
sudo chmod 600 /etc/traefik/ssl/*.key

echo "Certificate successfully generated and stored at /etc/traefik/ssl/cefaslocalserver.com.crt"

exit 0
