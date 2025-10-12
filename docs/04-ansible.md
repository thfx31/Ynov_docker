# Documentation Ansible

Ce document présente la structure du projet **Ansible** utilisé pour déployer l’environnement Forge Docker.  
Il décrit la logique du playbook principal, le rôle de chaque composant et les cas où certaines tâches sont facultatives.

---

## 1. Présentation générale

L’automatisation du déploiement repose sur un playbook unique : `ansible/forge-cicd.yml`.  
Ce playbook orchestre l’installation de Docker, le déploiement de la stack, les tâches de post-installation et les vérifications de sécurité.

---

## 2. Rôles

### 2.1 Structure

| Rôle | Description | Actions principales |
|------|--------------|---------------------|
| **postinstall** | Prépare la machine hôte avant le déploiement  | Mise à jour du système, installation des packages nécessaires |
| **docker** | Installe et configure Docker et Docker Compose | Installation, activation du service Docker, gestion des dépendances |
| **forge_cicd** | Déploie la stack Docker Compose sur le serveur cible | Copie du fichier `docker-compose.yml`, création des volumes, exécution du `docker compose up -d`, vérification du statut des containers |
| **trivy** | Exécute une analyse de sécurité des images Docker | Téléchargement et lancement du scanner Trivy, génération des rapports HTML |

Chaque rôle est défini dans `ansible/roles/<nom_du_rôle>` avec la structure classique :
```
roles/
├── docker/
│   ├── defaults/main.yml
│   ├── tasks/main.yml
│   └── meta/main.yml
├── forge_cicd/
│   ├── defaults/main.yml
│   ├── tasks/main.yml
│   └── meta/main.yml
├── postinstall/
│   ├── defaults/main.yml
│   ├── tasks/main.yml
│   └── meta/main.yml
└── trivy/
    ├── defaults/main.yml
    ├── tasks/main.yml
    └── meta/main.yml
```

### 2.2 Tâche facultative (DockerHub)
Le playbook contient une tâche optionnelle pour se connecter à Docker Hub :
```yaml
# Only if prompted for Docker Hub credentials and need custom images
- name: Connect to Docker Hub
  community.docker.docker_login:
    username: "{{ docker_hub_user }}"
    password: "{{ docker_hub_token }}"
```
Cette étape permet de s'authentifier auprès de Docker Hub pour **pousser ou tirer des images personnalisées**.  
Elle n’est **pas obligatoire** si l’environnement utilise déjà des images publiées ou locales.

Si vous la désactivez, il faudra également supprimer ce bloc dans le playbook :
```yaml
  # Only if you want to be prompted for Docker Hub credentials
  vars_prompt:
    - name: "docker_hub_user"
      prompt: "Docker Hub username"
      private: no
    - name: "docker_hub_token"
      prompt: "Docker Hub Token"
      private: yes
```


---

## 3 Playbook

### 3.1 Fichier `forge-cicd.yml`

```yaml
---
- hosts: all
  
  # Only if you want to be prompted for Docker Hub credentials
  vars_prompt:
    - name: "docker_hub_user"
      prompt: "Docker Hub username"
      private: no
    - name: "docker_hub_token"
      prompt: "Docker Hub Token"
      private: yes

  roles:
    - postinstall
    - docker
    - forge_cicd
    - trivy
```

## 3.2 Exécution du playbook

### Commande standard
```bash
ansible-playbook -i inventory.ini forge-cicd.yml -l <docker_host_target>
```

### Comportement par défaut 
- Les rôles principaux (`docker`, `forge_cicd`, `postinstall`, `trivy`) s’exécutent normalement.
- Le playbook échouera si l'inventaire est mal renseigné

### Debug
Activation du verbose pour debugger
```bash
ansible-playbook -vvv -i inventory.ini forge-cicd.yml -l <docker_host_target>
```

### Erreurs possibles
Si l'ordre de lancement des rôles est modifié il est possible que le playbook s'exécute mal (problème de prérequis).
Exemple : si on lance forge_cicd avant docker, il ne pourra pas lancer docker compose.
Une bonne pratique serait de mettre le rôle Docker en dépendance de forge_cicd (ça se passe dans le fichier meta)

## 4. Inventaire et ansible.cfg
### 4.1 Fichier `inventory.ini`

L’inventaire définit les hôtes gérés par Ansible et les regroupe en environnements (par exemple `Homelab`, `DigitalOcean`, etc.).

Exemple :

```ini
[digitalocean]
do-server ansible_host=159.203.104.135

[Homelab]
docker-server ansible_host=ynov-docker01
```

### Explication
- `[Homelab]` : nom du groupe de serveurs (environnement local dans ce cas).  
- `docker-server` : nom logique de l’hôte.  
- `ansible_host=ynov-docker01` : nom DNS ou IP utilisé pour la connexion SSH.  

Ce fichier peut être étendu pour inclure plusieurs environnements (staging, production, cloud, etc.).
Il est également possible d'écrire l'inventaire au format YAML.
---

### 4.2 Fichier `ansible.cfg`

Le fichier `ansible.cfg` contrôle le comportement global d’Ansible, notamment les chemins, l’utilisateur distant, la clé SSH et les options de sécurité.

Exemple :

```ini
[defaults]
inventory = inventory.ini
remote_user = root
private_key_file = /home/<user>/.ssh/id_ed25519
host_key_checking = False
```

### Explication
- `inventory` : définit le fichier d’inventaire par défaut
- `remote_user` : utilisateur SSH utilisé pour exécuter les tâches (ici `root`)  
- `private_key_file` : chemin vers la clé SSH privée pour l’authentification  
- `host_key_checking` : désactive la vérification des empreintes SSH  

---

### 4.3 Bonnes pratiques

- Créer un inventaire par environnement (`inventory-homelab.ini`, `inventory-cloud.ini`, etc.).  
- Conserver le même `ansible.cfg` pour tous les contextes de déploiement.  
- Éviter l’utilisation du compte `root` en production : préférer un utilisateur dédié avec `become: true`.  
- Conserver les clés SSH dans un dossier sécurisé et versionner uniquement les chemins relatifs.

---
## 5. Bonnes pratiques et extensions

- Toujours tester les rôles sur un environnement de staging avant production.  
- Centraliser les variables sensibles (mots de passe, tokens) dans **Ansible Vault**.  
- Factoriser les variables communes dans `group_vars/all.yml` (non présent par défaut).  
- Conserver l’ordre logique des rôles : préparation → installation → déploiement → audit.

---
## 6. Génération et récupération des rapports Trivy

Le rôle **trivy** exécute une analyse de sécurité automatisée sur les images Docker de la stack et génère des rapports HTML complets.

### 6.1 Étapes principales

1. **Création du répertoire distant des rapports**  
   Un répertoire `reports/` est créé sur le serveur distant :
   ```yaml
   - name: Create reports directory
     ansible.builtin.file:
       path: "{{ forge_cicd_docker_path }}/reports"
       state: directory
       mode: "0755"
   ```

2. **Scan des images Docker**  
   La liste des images est extraite à partir de `docker compose images`, puis chaque image est scannée via Trivy :  
   ```yaml
   - name: Scan Docker images with Trivy
     ansible.builtin.command: >
       trivy image --quiet --format template
       --template "@/usr/local/share/trivy/templates/html.tpl"
       --output {{ forge_cicd_docker_path }}/reports/{{ item.Repository | replace('/', '_') }}_{{ item.Tag }}.html
       {{ item.Repository }}:{{ item.Tag }}
     loop: "{{ docker_images.stdout | from_json }}"
   ```

   Chaque rapport est généré dans le dossier `reports/` sur la machine distante, au format HTML :  
   `reports/<nom_image>_<tag>.html`

3. **Récupération locale des rapports**  
   Les rapports sont ensuite rapatriés sur la machine de contrôle dans le répertoire local du projet :  
   ```yaml
   - name: Fetch Trivy reports
     ansible.builtin.fetch:
       src: "{{ item.path }}"
       dest: ../reports/
       flat: yes
     loop: "{{ trivy_reports_to_fetch.files }}"
   ```

   → Les fichiers HTML se retrouvent localement dans :  
   `../reports/` (par rapport au répertoire `ansible/`)

### 6.2 Contenu et usage des rapports
Les rapports incluent :
- La liste des vulnérabilités détectées (OS, librairies, dépendances)  
- Leur niveau de sévérité (LOW, MEDIUM, HIGH, CRITICAL)  
- Les recommandations ou versions corrigées disponibles  

Ces rapports peuvent être consultés directement via un navigateur web ou archivés pour suivi de conformité.

---
