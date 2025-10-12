# ==========================================================
# Makefile - Ansible Environnement (~/.venvs/ansible)
# ==========================================================

# Set variables
VENV_DIR := $(HOME)/.venvs/ansible
REQUIREMENTS := requirements.txt


.PHONY: help venv init shell upgrade 

# ----------------------------------------------------------
# Help commands
# ----------------------------------------------------------
help:
	@echo ""
	@echo "$(YELLOW)Commandes disponibles :$(NC)"
	@echo "  make venv        → Create the global virtual environment (~/.venvs/ansible)"
	@echo "  make init        → Install dependencies from requirements.txt"
	@echo "  make upgrade     → Upgrade pip, setuptools, wheel, and all installed packages"
	@echo "  make shell       → Open an interactive shell inside the venv"
	@echo ""

# ----------------------------------------------------------
# Venv management
# ----------------------------------------------------------
venv:
	@mkdir -p $(VENV_DIR)
	@test -d $(VENV_DIR)/bin || python3 -m venv $(VENV_DIR)
	@echo "✅ Virtualenv created at $(VENV_DIR)"

init: venv
	@. $(VENV_DIR)/bin/activate && pip install --upgrade pip && pip install -r $(REQUIREMENTS)
	@echo "✅ Dependencies installed in $(VENV_DIR)"

upgrade:
	@echo "⬆️  Mise à jour du venv et de tous les paquets..."
	@. $(VENV_DIR)/bin/activate && \
	pip install --upgrade pip setuptools wheel && \
	pip list --outdated --format=json | jq -r '.[].name' | xargs -r -n1 pip install -U
	@echo "✅ All packages have been upgraded"

shell:
	@echo "🐍 Activating venv : $(VENV_DIR)"
	@bash -c "source $(VENV_DIR)/bin/activate && exec bash"
