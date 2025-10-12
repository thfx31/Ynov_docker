#############################################
# NGINX Proxy : reverse proxy
#############################################
FROM nginxproxy/nginx-proxy:alpine AS nginx-proxy
LABEL maintainer="thfx31" description="Custom NGINX Proxy for CI/CD stack"
EXPOSE 80 443


#############################################
# NGINX : Let's Encrypt Companion
#############################################
FROM nginxproxy/acme-companion AS nginx-letsencrypt
LABEL maintainer="thfx31" description="Custom ACME Companion (Let's Encrypt)"
EXPOSE 80 443


#############################################
# Forge : NGINX homepage
#############################################

FROM nginx:alpine AS forge
LABEL maintainer="thfx31" description="Custom Forge homepage (NGINX)"
COPY ./forge-html /usr/share/nginx/html
RUN test -f /usr/share/nginx/html/index.html || (echo "ERROR: index.html not found!" && exit 1)
EXPOSE 80


#############################################
# Jenkins : CI/CD server
#############################################

FROM jenkins/jenkins:lts-jdk17 AS jenkins
LABEL maintainer="thfx31" description="Custom Jenkins with Docker CLI and tools"
USER root
RUN apt-get update && \
    apt-get install -y docker.io git curl vim && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
USER jenkins
EXPOSE 8080 50000


#############################################
# Stage 6 — PostgreSQL (database)
#############################################
FROM postgres:16 AS postgres
LABEL maintainer="thfx31" description="Custom PostgreSQL 16 for Gitea"
EXPOSE 5432


#############################################
# Gitea : Git server
#############################################
FROM gitea/gitea:latest AS gitea
LABEL maintainer="thfx31" description="Custom Gitea Git server"
EXPOSE 3000
