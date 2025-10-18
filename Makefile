# ==========================================================
# Makefile - Ansible Environnement (~/.venvs/ansible)
# ==========================================================

# Set variables
VENV_DIR := $(HOME)/.virtualenvs/ansible
REQUIREMENTS := ansible/requirements.txt
DOCKER_BUILD_SCRIPT := ./build_and_push_private.sh
DOCKER_CLEAN_SCRIPT := ./cleanup_docker.sh
PRECOMMIT_CONFIG := ansible/.pre-commit-config.yaml


.PHONY: help venv init upgrade build cleanup lint

# ----------------------------------------------------------
# Help commands
# ----------------------------------------------------------
help:
	@echo ""
	@echo "Commandes disponibles :"
	@echo "  make venv        → Create the global virtual environment (~/.venvs/ansible)"
	@echo "  make init        → Install dependencies from requirements.txt"
	@echo "  make upgrade     → Upgrade pip, setuptools, wheel, and all installed packages"
	@echo "  make build       → Build and push Docker images"
	@echo "  make cleanup     → Clean up Docker images"
	@echo ""

# ----------------------------------------------------------
# Venv management
# ----------------------------------------------------------
venv:
	@mkdir -p $(VENV_DIR)
	@test -d $(VENV_DIR)/bin || python3 -m venv $(VENV_DIR)
	@echo "✅ Virtualenv created at $(VENV_DIR)"

init: venv
	@echo "📦 Installing dependencies and pre-commit hooks..."
	@$(VENV_DIR)/bin/pip install --upgrade pip
	@$(VENV_DIR)/bin/pip install -r $(REQUIREMENTS)
	@if [ -x "$(VENV_DIR)/bin/pre-commit" ]; then \
		echo "⚙️  Installing pre-commit hook (config: $(PRECOMMIT_CONFIG))..."; \
		$(VENV_DIR)/bin/pre-commit install --config $(PRECOMMIT_CONFIG); \
	else \
		echo "⚠️ pre-commit not found (check requirements.txt)"; \
	fi
	@echo "✅ Environment initialized in $(VENV_DIR)"

upgrade:
	@echo "⬆️  Mise à jour du venv et de tous les paquets..."
	@. $(VENV_DIR)/bin/activate && \
	pip install --upgrade pip setuptools wheel && \
	pip list --outdated --format=json | jq -r '.[].name' | xargs -r -n1 pip install -U
	@echo "✅ All packages have been upgraded"

build:
	@echo "Building and pushing Docker image..."
	@chmod +x $(DOCKER_BUILD_SCRIPT)
	@$(DOCKER_BUILD_SCRIPT)

lint:
	@echo "🔍 Running Ansible and YAML linters..."
	~/.venvs/ansible/bin/ansible-lint ansible/
	~/.venvs/ansible/bin/yamllint .

cleanup:
	@echo "Cleaning up Docker resources..."
	@chmod +x $(DOCKER_CLEAN_SCRIPT)
	@$(DOCKER_CLEAN_SCRIPT)
