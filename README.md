# Forge Docker – Environnement DevOps

Ce projet met en place une **infrastructure DevOps complète** basée sur **Docker**, regroupant les principaux outils de développement et d’intégration continue.
Cette forge logicielle sera entièrement déployée par **Ansible**.

---
## Contexte
Projet réalisé dans le cadre d'un TP **Conteneur & orchestration**
Mastère **Expert en cloud, sécurité & infrastructure 2024/2026**

---
## Applications de la forge

- **Gitea** – forge Git légère et auto-hébergée  
- **Jenkins** – pipeline CI/CD automatisé  
- **Nginx Proxy + Let's Encrypt** – reverse proxy automatique avec certificats SSL  
- **PostgreSQL** – base de données pour Gitea  
- **Forge Homepage** – page d’accueil centralisée

---

## Stack technique

| Composant | Rôle |
|------------|------|
| Docker / Docker Compose | Orchestration des services |
| Nginx Proxy | Routage HTTP/S automatique |
| Let's Encrypt Companion | Gestion des certificats SSL |
| Gitea | Hébergement de code source |
| Jenkins | Intégration et déploiement continu |
| PostgreSQL | Stockage des données Gitea |
| Ansible | Déploiement configuration distante |

---

## Lancement rapide

```bash
# Démarrer l'environnement complet
docker compose up -d

# Vérifier l'état
docker ps

# Arrêter et nettoyer
docker compose down -v
```

---

## Accès par défaut

| Service | URL | Description |
|----------|-----|-------------|
| Gitea | https://gitea.local | Forge Git |
| Jenkins | https://jenkins.local | CI/CD |
| Forge Homepage | https://forge.local | Page d’accueil |
| PostgreSQL | Interne (non exposé) | Base Gitea |

---

## Documentation détaillée

Retrouvez les détails techniques et les schémas dans le dossier [`docs/`](docs/).

- [01 - Architecture](docs/01-architecture.md)
- [02 - Déploiement](docs/02-deploiement.md)
- [03 - Services](docs/03-services.md)
- [04 - Ansible](docs/04-ansible.md)

---

## Auteurs

Projet réalisé par **Thomas FAUROUX** et **Robin THIRIET** 
Dépôt : [thfx31/ynov_docker](https://github.com/thfx31/ynov_docker)

---

## Licence

Ce projet est distribué sous licence **MIT**.  
Vous pouvez librement le réutiliser et le modifier avec attribution.
