# Partir d'une image Alpine légère
FROM alpine:3.20

# Installer OpenSSL
RUN apk add --no-cache openssl

# Définir les variables d'environnement
ENV CERT_CN=gitlab.tfrt.local \
    CERT_DAYS=365 \
    CERT_KEY_FILE=gitlab.key \
    CERT_CRT_FILE=gitlab.crt

# Définir le répertoire où seront stockés les certificats
WORKDIR /certs

# Génération automatique du certificat à la création du conteneur
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["openssl req -x509 -nodes -days $CERT_DAYS -newkey rsa:2048 -keyout /certs/$CERT_KEY_FILE -out /certs/$CERT_CRT_FILE -subj \"/CN=$CERT_CN\""]

