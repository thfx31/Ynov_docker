# Maintenance de l'environnement Forge Docker

Ce document décrit les procédures et bonnes pratiques de maintenance pour l’environnement **Forge Docker**.  
Il couvre la supervision, les mises à jour, le nettoyage, les sauvegardes et les vérifications périodiques.

---

## 1. Introduction

La maintenance vise à garantir la **stabilité**, la **sécurité** et la **pérennité** de la stack Forge Docker.  
Bien que l’environnement soit géré “as code” via Ansible et Docker Compose, certaines opérations manuelles peuvent être nécessaires entre deux déploiements.

---

## 2. Gestion courante des services

### Vérifier l’état des conteneurs

```bash
docker ps
docker compose ps
```

### Consulter les logs

```bash
docker logs -f <nom_du_conteneur>
# Exemple :
docker logs -f jenkins
```

### Redémarrer un service

```bash
docker compose restart <service>
# Exemple :
docker compose restart gitea
```

### Inspecter un service

```bash
docker inspect <nom_du_conteneur>
```

---

## 3. Mise à jour de la stack

### 3.1 Principe : mise à jour “as code”

La priorité dans la démarche DevOps est de gérer les mises à jour via le **code source** :  
- modification du `docker-compose.yml` pour changer les versions d’image,  
- déploiement automatisé via Ansible :

```bash
ansible-playbook -i inventory.ini forge-cicd.yml
```

Cette méthode garantit la **traçabilité** et la **reproductibilité**.

### 3.2 Mise à jour manuelle

Si nécessaire, une mise à jour manuelle peut être effectuée directement sur l’hôte Docker :

```bash
# Récupérer les dernières images
docker compose pull

# Relancer la stack
docker compose up -d

# Supprimer les anciennes images inutilisées
docker image prune -f
```

Ces commandes permettent de maintenir la stack à jour sans passer par Ansible, tout en conservant les volumes persistants.

---

## 4. Supervision rapide

### Vérifier les ressources et l’état général

```bash
docker stats
docker system df
docker volume ls
docker network ls
```

### Vérifier les certificats SSL

Les certificats sont générés et renouvelés automatiquement par `nginx-letsencrypt`.  
Pour vérifier leur présence ou leur validité :

```bash
docker exec nginx-proxy ls -l /etc/nginx/certs/
```

---
## 5. Nettoyage contrôlé

Le script **`cleanup_docker.sh`** est utilisé pour nettoyer les ressources Docker inutilisées.  
Il exécute les actions suivantes :

- Suppression des **conteneurs arrêtés**
- Suppression des **images non utilisées**
- Suppression des **volumes non référencés**
- Suppression des **réseaux inactifs**

### Exemple d’utilisation

```bash
./cleanup_docker.sh
```

### Précautions

- Vérifier que tous les services critiques sont **actifs** avant exécution.  
- Ne pas exécuter ce script pendant un déploiement ou une mise à jour.  
- Les volumes actifs (ex : `gitea-data`, `jenkins-home`) **ne sont pas supprimés**.

---

## 6. Sauvegarde et restauration des volumes

### 6.1 Sauvegarde d’un volume

Chaque volume Docker peut être sauvegardé sous forme d’archive `.tar` :

```bash
docker run --rm -v <nom_du_volume>:/data -v $(pwd):/backup   alpine tar czf /backup/<nom_du_volume>.tar.gz -C /data .
```

**Exemple :** sauvegarde du volume Gitea

```bash
docker run --rm -v gitea-data:/data -v $(pwd):/backup   alpine tar czf /backup/gitea-data.tar.gz -C /data .
```

### 6.2 Restauration sur le même hôte

```bash
docker run --rm -v <nom_du_volume>:/data -v $(pwd):/backup   alpine tar xzf /backup/<nom_du_volume>.tar.gz -C /data
```

### 6.3 Transfert vers un autre hôte

1. Copier le fichier `.tar.gz` sur le nouvel hôte (`scp` ou autre).  
2. Créer le volume sur le nouvel hôte :  
   ```bash
   docker volume create <nom_du_volume>
   ```
3. Restaurer les données avec la même commande que ci-dessus.

---
