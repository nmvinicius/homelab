#!/usr/bin/env bash
# Gerar CA privada + certificado wildcard *.arpa para o homelab.
# Uso: ./scripts/generate-certs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERTS_DIR="${PROJECT_DIR}/certs"
CA_DIR="${CERTS_DIR}/ca"

DOMAIN="arpa"
WILDCARD_DOMAIN="*.${DOMAIN}"

# ---------------------------------------------------------------------------
# 1. Criar estrutura de diretórios
# ---------------------------------------------------------------------------
mkdir -p "${CA_DIR}"

# ---------------------------------------------------------------------------
# 2. Gerar chave privada da Root CA (protegida por senha ou sem)
# ---------------------------------------------------------------------------
if [[ ! -f "${CA_DIR}/ca.key" ]]; then
  echo "==> Gerando chave privada da Root CA (4096-bit RSA)..."
  openssl genrsa -out "${CA_DIR}/ca.key" 4096
  chmod 600 "${CA_DIR}/ca.key"
else
  echo "==> Chave da CA já existe: ${CA_DIR}/ca.key"
fi

# ---------------------------------------------------------------------------
# 3. Gerar certificado autoassinado da Root CA (10 anos)
# ---------------------------------------------------------------------------
if [[ ! -f "${CA_DIR}/ca.crt" ]]; then
  echo "==> Gerando certificado autoassinado da Root CA (10 anos)..."
  openssl req -x509 -new -nodes \
    -key "${CA_DIR}/ca.key" \
    -sha256 -days 3650 \
    -out "${CA_DIR}/ca.crt" \
    -subj "/C=BR/ST=Home/L=Homelab/O=Homelab Internal CA/CN=Homelab Root CA"
else
  echo "==> Certificado da CA já existe: ${CA_DIR}/ca.crt"
fi

# ---------------------------------------------------------------------------
# 4. Gerar chave privada do wildcard *.arpa
# ---------------------------------------------------------------------------
echo "==> Gerando chave privada para ${WILDCARD_DOMAIN} (2048-bit RSA)..."
openssl genrsa -out "${CERTS_DIR}/wildcard.${DOMAIN}.key" 2048
chmod 600 "${CERTS_DIR}/wildcard.${DOMAIN}.key"

# ---------------------------------------------------------------------------
# 5. Criar CSR (Certificate Signing Request) com SANs
# ---------------------------------------------------------------------------
echo "==> Criando CSR com Subject Alternative Names (SANs)..."
cat > "${CERTS_DIR}/wildcard.${DOMAIN}.cnf" << EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[req_distinguished_name]
C  = BR
ST = Home
L  = Homelab
O  = Homelab Internal
CN = ${WILDCARD_DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${WILDCARD_DOMAIN}
DNS.2 = ${DOMAIN}
EOF

openssl req -new \
  -key "${CERTS_DIR}/wildcard.${DOMAIN}.key" \
  -out "${CERTS_DIR}/wildcard.${DOMAIN}.csr" \
  -config "${CERTS_DIR}/wildcard.${DOMAIN}.cnf"

# ---------------------------------------------------------------------------
# 6. Assinar o certificado com a Root CA (5 anos)
# ---------------------------------------------------------------------------
echo "==> Assinando certificado wildcard com a Root CA (5 anos)..."

cat > "${CERTS_DIR}/wildcard.${DOMAIN}.ext" << EOF
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth, clientAuth
subjectAltName         = @alt_names

[alt_names]
DNS.1 = ${WILDCARD_DOMAIN}
DNS.2 = ${DOMAIN}
EOF

openssl x509 -req \
  -in "${CERTS_DIR}/wildcard.${DOMAIN}.csr" \
  -CA "${CA_DIR}/ca.crt" \
  -CAkey "${CA_DIR}/ca.key" \
  -CAcreateserial \
  -out "${CERTS_DIR}/wildcard.${DOMAIN}.crt" \
  -days 1825 \
  -sha256 \
  -extfile "${CERTS_DIR}/wildcard.${DOMAIN}.ext"

# ---------------------------------------------------------------------------
# 7. Criar fullchain.pem (cert + CA) para o nginx
# ---------------------------------------------------------------------------
echo "==> Criando fullchain.pem para Nginx..."
cat "${CERTS_DIR}/wildcard.${DOMAIN}.crt" "${CA_DIR}/ca.crt" \
  > "${CERTS_DIR}/wildcard.${DOMAIN}.fullchain.pem"

# ---------------------------------------------------------------------------
# 8. Gerar parâmetros DH para DHE (Forward Secrecy)
# ---------------------------------------------------------------------------
if [[ ! -f "${CERTS_DIR}/dhparam.pem" ]]; then
  echo "==> Gerando DH parameters (2048-bit, isso pode demorar um pouco)..."
  openssl dhparam -out "${CERTS_DIR}/dhparam.pem" 2048
else
  echo "==> DH parameters já existem: ${CERTS_DIR}/dhparam.pem"
fi

# ---------------------------------------------------------------------------
# 9. Limpar arquivos temporários e exibir resumo
# ---------------------------------------------------------------------------
rm -f "${CERTS_DIR}/wildcard.${DOMAIN}.csr"
rm -f "${CERTS_DIR}/wildcard.${DOMAIN}.cnf"
rm -f "${CERTS_DIR}/wildcard.${DOMAIN}.ext"

echo ""
echo "============================================"
echo " Certificados gerados com sucesso!"
echo "============================================"
echo ""
echo "Arquivos importantes:"
echo ""
echo "  CA (distribuir para dispositivos):"
echo "    ${CA_DIR}/ca.crt"
echo ""
echo "  Wildcard *.arpa (usar no Nginx):"
echo "    Certificado:  ${CERTS_DIR}/wildcard.${DOMAIN}.crt"
echo "    Chave:        ${CERTS_DIR}/wildcard.${DOMAIN}.key"
echo "    Fullchain:    ${CERTS_DIR}/wildcard.${DOMAIN}.fullchain.pem"
echo ""
echo "  DH Params:"
echo "    ${CERTS_DIR}/dhparam.pem"
echo ""
echo "Próximo passo: distribuir ca.crt para os dispositivos da rede."
echo "Depois: ./scripts/deploy.sh core"
