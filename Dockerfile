##################
##### OPENSSL #####
##################
# Build with alpine base OS
FROM alpine:3.22 AS openssl

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

##################
##### GITLAB #####
##################

# Start from the official GitLab CE image
FROM gitlab/gitlab-ce:18.3.3-ce.0 AS gitlab

# Expose Gitlab HTTP and HTTPS ports
EXPOSE 80 443

###################
##### JENKINS #####
###################

# Start from the official Jenkins image
FROM jenkins/jenkins:2.430-jdk21 AS jenkins

# Switch to root to install packages
USER root

# Install basic tools (git, docker CLI, etc.)
RUN apt-get update && \
    apt-get install -y git curl docker.io && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Allow Jenkins user to use Docker socket if mounted
RUN usermod -aG docker jenkins

# Set Jenkins home
ENV JENKINS_HOME=/var/jenkins_home

# Switch back to the Jenkins user
USER jenkins

# Expose default ports (UI + JNLP)
EXPOSE 8080 50000

