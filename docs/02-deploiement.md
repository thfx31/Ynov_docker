# Documentation de déploiement

Ce document présente les différentes méthodes de déploiement de l’environnement **Forge Docker**.  
La méthode recommandée repose sur **Ansible**, mais une procédure manuelle via **Docker Compose** est également décrite.

---

## 1. Déploiement automatisé avec Ansible

### 1.1 Présentation générale

Le déploiement automatisé repose sur un projet **Ansible** structuré dans le répertoire `ansible/`.  
Le playbook principal `forge-cicd.yml` orchestre les tâches de **post-installation** de la machine host (Debian-like), l’installation de **Docker**, le déploiement de la **stack CI/CD** et la recherche de **vulnérabilités** dans les images.

### 1.2 Structure du projet Ansible

```
ansible/
├── ansible.cfg
├── forge-cicd.yml
├── inventory.ini
├── host_vars/
│   └── dockerhost_hostname.yml
└── roles/
    ├── docker/
    ├── forge_cicd/
    ├── postinstall/
    └── trivy/
```

Chaque rôle assure une fonction spécifique :
- **postinstall** : tâches de post installation (prérequis Docker) de la machine Docker Host 
- **docker** : installation et configuration de Docker sur la machine distante  
- **forge_cicd** : déploiement de la stack Docker Compose  
- **trivy** : scan de sécurité des images Docker

### 1.3 Préparation de l’environnement Python

Il est recommandé de disposer d'un environnement Python isolé (virtualenv) pour exécuter le playbook **forge-cicd.yml**.  
Deux méthodes sont possibles.

#### a. Avec le Makefile

Le `Makefile` présent à la racine du projet propose plusieurs commandes utiles :

```bash
make venv       # Crée l'environnement virtuel global (~/.venvs/ansible)
make init       # Installe les dépendances listées dans requirements.txt
make upgrade    # Met à jour pip, setuptools, wheel et les dépendances
make shell      # Ouvre une console interactive dans le venv
```

Ces commandes permettent d’installer Ansible et les dépendances requises dans un environnement isolé.

#### b. Sans le Makefile (manuellement)

Si `make` n’est pas disponible, l’environnement peut être créé manuellement :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 1.4 Exécution du playbook

Une fois l’environnement prêt, exécuter le playbook :

```bash
cd ansible
ansible-playbook -i inventory.ini forge-cicd.yml
```

Le fichier `inventory.ini` définit les hôtes cibles, et les variables spécifiques à chaque hôte se trouvent dans `host_vars/`.

### 1.5 Résultats attendus

À l’issue de l’exécution :
- Docker est installé et configuré sur la machine distante
- La stack Docker Compose est déployée (services Gitea, Jenkins, PostgreSQL, proxy, etc.) ;
- Les services sont démarrés et accessibles via HTTPS.

---

## 2. Déploiement manuel (méthode alternative)

Cette méthode n’est pas la voie principale, mais elle permet de comprendre la logique du déploiement ou de tester le projet sans Ansible.

### 2.1 Clonage du dépôt

Avant toute chose, cloner le dépôt sur le serveur (Docker Host) :

```bash
git clone https://github.com/thfx31/ynov_docker.git
cd ynov_docker
```

### 2.2 Construction des images Docker (optionnel)

Si vous souhaitez utiliser vos propres images personnalisées, vous pouvez les construire avant de lancer la stack.  
Deux méthodes sont possibles : **manuelle** ou via le **script d’automatisation**.

#### a. Construction manuelle

Chaque image peut être construite individuellement à partir du Dockerfile correspondant.
Si vous souhaitez rendre vos images disponibles depuis un registre distant (ex. Docker Hub), il faut d’abord s’y connecter puis les pousser manuellement.
Exemple pour Gitea :

```bash
# Création et tag de l'image
docker build -t thfx31/ynov:gitea-v1 -f Dockerfile .

# Connexion à Docker Hub
docker login -u <votre_utilisateur>

# Push de l’image vers le registry
docker push <nom_du_registry>:gitea-v1
```

Cette commande génère l’image localement avec le tag spécifié.  
Vous pouvez ensuite l’utiliser dans votre fichier `docker-compose.yml`.

#### b. Construction automatisée via script

Le script `build_and_push_private.sh` situé à la racine du projet automatise la construction et le push des images sur Docker Hub.  
Il propose plusieurs options :

```bash
./build_and_push_private.sh --help
Usage: ./build_and_push_private.sh [OPTION]

Options:
  --list               List all available images in Docker Hub
  --build <name>       Build and push a specific image (e.g., forge)
  --all                Build and push all images (default)
  --help               Show this help message

Examples:
  ./build_and_push_private.sh --list
  ./build_and_push_private.sh --build jenkins
  ./build_and_push_private.sh --all
```

### 2.3 Lancer la stack Docker Compose

Si vous ne souhaitez pas utiliser d’images customisées, vous pouvez directement utiliser les images existantes publiées.  
Il suffit alors de **modifier les noms d’image** dans le fichier `docker-compose.yml` si nécessaire, puis de lancer :

```bash
docker compose up -d
docker ps
```

Les conteneurs suivants doivent apparaître :
- nginx-proxy  
- nginx-letsencrypt  
- gitea  
- jenkins  
- gitea-db  
- forge-homepage  

### 2.4 Arrêt et suppression de la stack

```bash
docker compose down -v
```

Cette commande arrête et supprime les conteneurs, réseaux et volumes associés.

---

## 3. Vérification et maintenance

Quelques commandes utiles :

| Action | Commande |
|---------|-----------|
| Vérifier les conteneurs actifs | `docker ps` |
| Consulter les logs d’un service | `docker compose logs -f <service>` |
| Vérifier la version d’une image | `docker images` |
| Supprimer la stack et les volumes | `docker compose down -v` |
| Nettoyer les images obsolètes | `docker image prune -a` |

Les fichiers de configuration et les volumes sont persistants sur l’hôte, garantissant la continuité des services entre deux déploiements.

---
