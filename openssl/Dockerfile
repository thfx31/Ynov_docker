# Build with alpine base OS
FROM alpine:3.22

# Install OpenSSL
RUN apk add --no-cache openssl

# Set environment variables
ENV CERT_CN=gitlab.tfrt.local \
    CERT_DAYS=365 \
    CERT_KEY_FILE=gitlab.key \
    CERT_CRT_FILE=gitlab.crt

# Create certificate and key
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["openssl req -x509 -nodes -days $CERT_DAYS -newkey rsa:2048 -keyout /certs/$CERT_KEY_FILE -out /certs/$CERT_CRT_FILE -subj \"/CN=$CERT_CN\""]