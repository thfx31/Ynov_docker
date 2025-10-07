# Étape 1 : partir d'une image Alpine légère
FROM alpine:3.22

# Étape 2 : installer OpenSSL
RUN apk add --no-cache openssl

# Étape 3 : définir les variables d'environnement (tu peux les changer à la volée dans docker-compose)
ENV CERT_CN=gitlab.tfrt.local \
    CERT_DAYS=365 \
    CERT_KEY_FILE=gitlab.key \
    CERT_CRT_FILE=gitlab.crt

# Étape 4 : définir le répertoire où seront stockés les certificats
WORKDIR /certs

# Étape 5 : génération automatique du certificat à la création du conteneur
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["openssl req -x509 -nodes -days $CERT_DAYS -newkey rsa:2048 -keyout /certs/$CERT_KEY_FILE -out /certs/$CERT_CRT_FILE -subj \"/CN=$CERT_CN\""]

