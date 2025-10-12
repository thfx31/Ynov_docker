# Documentation des services

Ce document détaille les différents services constituant la stack **Forge Docker**, leur rôle, leurs variables d’environnement et les volumes associés.  
L’objectif est de comprendre la structure technique de l’infrastructure et la persistance des données.

---

## 1. Introduction

L’environnement Forge Docker regroupe plusieurs services interconnectés : une forge Git (Gitea), un serveur d’intégration continue (Jenkins), un reverse proxy (nginx-proxy) avec gestion automatique des certificats SSL (nginx-letsencrypt), une base de données PostgreSQL et un portail d’accueil.  
Chaque service fonctionne dans un conteneur Docker distinct, connecté à un ou plusieurs réseaux selon son rôle.

---

## 2. Détail des services

### 2.1 nginx-proxy

**Rôle :** Reverse proxy central, responsable du routage HTTP/HTTPS vers les services internes  
**Image :** `thfx31/ynov:nginx-proxy-v1`  
**Ports exposés :** 80, 443  
**Réseaux :** `cicd-net`  
**Variables d’environnement principales :**
- `ENABLE_IPV6` : désactive IPv6 (false)  
- `PER_VHOST` : active la configuration par hôte virtuel

**Volumes :**
- `/var/run/docker.sock:/tmp/docker.sock:ro` : permet à nginx-proxy de détecter dynamiquement les conteneurs  
- `certs:/etc/nginx/certs:rw` : stocke les certificats SSL  
- `html:/usr/share/nginx/html` : fichiers statiques et challenges ACME  
- `dhparam:/etc/nginx/dhparam` : paramètres Diffie-Hellman pour TLS

**Dépendances :** nginx-letsencrypt (gestion des certificats)

---

### 2.2 nginx-letsencrypt

**Rôle :** Génération et renouvellement automatique des certificats SSL via Let's Encrypt
**Image :** `thfx31/ynov:nginx-letsencrypt-v1`  
**Réseaux :** `cicd-net`  
**Variables d’environnement principales :**
- `NGINX_PROXY_CONTAINER` : nom du conteneur nginx-proxy associé  
- `DEFAULT_EMAIL` : e-mail d’enregistrement Let's Encrypt  
- `ACME_CA_URI` : URL de l’autorité ACME (production ou staging)

**Volumes :**
- `/var/run/docker.sock:/var/run/docker.sock:ro` : accès au daemon Docker  
- `certs:/etc/nginx/certs:rw` : stockage des certificats générés  
- `html:/usr/share/nginx/html` : répertoire de validation des challenges ACME  
- `acme:/etc/acme.sh` : données et métadonnées du client ACME

**Dépendances :** nginx-proxy

---

### 2.3 gitea

**Rôle :** Forge Git auto-hébergée pour la gestion du code source  
**Image :** `thfx31/ynov:gitea-v1`  
**Ports exposés :** 3000 
**Réseaux :** `cicd-net`, `gitea-net`  
**Variables d’environnement principales :**
- `VIRTUAL_HOST` : `${GITEA_DOMAIN}`  
- `LETSENCRYPT_HOST` / `LETSENCRYPT_EMAIL` : informations pour Let's Encrypt  
- `VIRTUAL_PORT` : `3000`  
- `GITEA__database__*` : paramètres de connexion PostgreSQL (`DB_TYPE`, `HOST`, `NAME`, `USER`, `PASSWD`)  
- `USER_UID`, `USER_GID` : UID/GID du processus Gitea

**Volumes :**
- `gitea-data:/data` : stockage des dépôts, utilisateurs et configuration  
- `/etc/timezone:/etc/timezone:ro` : synchronisation du fuseau horaire  
- `/etc/localtime:/etc/localtime:ro` : synchronisation de l’heure système

**Dépendances :**
- gitea-db (PostgreSQL)

**Notes :**
Gitea est connecté à deux réseaux :  
- `gitea-net` (accès à la base PostgreSQL)  
- `cicd-net` (exposition via le reverse proxy)

---

### 2.4 gitea-db

**Rôle :** Base de données PostgreSQL utilisée par Gitea  
**Image :** `thfx31/ynov:postgres-v1`  
**Ports exposés :** 5432  
**Réseaux :** `gitea-net`  
**Variables d’environnement principales :**
- `POSTGRES_DB` : nom de la base Gitea  
- `POSTGRES_USER` : utilisateur PostgreSQL  
- `POSTGRES_PASSWORD` : mot de passe associé

**Volumes :**
- `gitea-db-data:/var/lib/postgresql/data` : persistance des données PostgreSQL

**Dépendances :** Aucune

---

### 2.5 jenkins

**Rôle :** Serveur d’intégration continue (CI/CD)  
**Image :** `thfx31/ynov:jenkins-v1`  
**Ports exposés :** 8080, 50000  
**Réseaux :** `cicd-net`  
**Variables d’environnement principales :**
- `VIRTUAL_HOST` : `${JENKINS_DOMAIN}`  
- `LETSENCRYPT_HOST` / `LETSENCRYPT_EMAIL` : configuration Let's Encrypt  
- `VIRTUAL_PORT` : `8080`

**Volumes :**
- `jenkins-home:/var/jenkins_home` : stockage des jobs, builds et plugins Jenkins  
- `/var/run/docker.sock:/var/run/docker.sock` : permet à Jenkins de lancer des builds Docker

**Dépendances :** nginx-proxy (accès HTTPS)

---

### 2.6 forge-homepage

**Rôle :** Page d’accueil du portail Forge regroupant les liens vers les services internes  
**Image :** `thfx31/ynov:forge-v1`  
**Ports exposés :** 80  
**Réseaux :** `cicd-net`  
**Variables d’environnement principales :**
- `VIRTUAL_HOST` : `${FORGE_DOMAIN}`  
- `LETSENCRYPT_HOST` / `LETSENCRYPT_EMAIL` : configuration Let's Encrypt

**Volumes :** Aucun volume spécifique  
**Dépendances :** nginx-proxy (exposition publique)

---

## 3. Fonction des volumes

Les volumes Docker assurent la **persistance des données** entre les déploiements et séparent la configuration du cycle de vie des conteneurs.

| Volume | Utilisation | Services associés |
|---------|--------------|-------------------|
| `certs` | Stocke les certificats SSL générés par Let's Encrypt | nginx-proxy, nginx-letsencrypt |
| `acme` | Contient les fichiers temporaires et métadonnées du client ACME (acme.sh) | nginx-letsencrypt |
| `dhparam` | Stocke les paramètres Diffie-Hellman pour le chiffrement TLS | nginx-proxy |
| `html` | Répertoire public partagé pour les challenges ACME et fichiers statiques | nginx-proxy, nginx-letsencrypt |
| `jenkins-home` | Contient la configuration, les jobs, les plugins et les builds Jenkins | jenkins |
| `gitea-data` | Contient les dépôts Git, utilisateurs et configuration de Gitea | gitea |
| `gitea-db-data` | Contient les données PostgreSQL utilisées par Gitea | gitea-db |

---

## 4. Tableau récapitulatif

| Service           | Image utilisée                     | Ports exposés | Réseaux | Volumes | Dépendances |
|-------------------|------------------------------------|----------------|-----------|-------------|--------------|
| nginx-proxy       | thfx31/ynov:nginx-proxy-v1         | 80, 443        | cicd-net  | certs, html, dhparam | nginx-letsencrypt |
| nginx-letsencrypt | thfx31/ynov:nginx-letsencrypt-v1   |                | cicd-net  | certs, html, acme | nginx-proxy |
| gitea             | thfx31/ynov:gitea-v1               | 3000           | cicd-net, gitea-net | gitea-data | gitea-db |
| gitea-db          | thfx31/ynov:postgres-v1            | 5432           | gitea-net | gitea-db-data | - |
| jenkins           | thfx31/ynov:jenkins-v1             | 8080, 50000    | cicd-net  | jenkins-home | nginx-proxy |
| forge-homepage    | thfx31/ynov:forge-v1               | 80             | cicd-net  | -           | nginx-proxy |

---
