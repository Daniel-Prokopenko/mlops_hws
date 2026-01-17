#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-install.log}"
VENV_DIR="${VENV_DIR:-$HOME/mlops_venv}"

log() { echo -e "$@" | tee -a "$LOG_FILE"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

is_wsl() {
  grep -qi "microsoft" /proc/version 2>/dev/null
}

SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if have_cmd sudo; then
    SUDO="sudo"
  else
    echo "Потрібен sudo (або запусти скрипт від root)." >&2
    exit 1
  fi
fi

# OS detection
OS_ID="unknown"
OS_VER="unknown"
CODENAME=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_VER="${VERSION_ID:-unknown}"
  CODENAME="${VERSION_CODENAME:-}"
fi

: > "$LOG_FILE"
log "==> ОС: ${OS_ID} ${OS_VER}"
log "==> Лог: ${LOG_FILE}"
log "==> Старт: $(date)"
log "==> VENV: ${VENV_DIR}"

apt_install() {
  $SUDO apt-get update -y >>"$LOG_FILE" 2>&1
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" >>"$LOG_FILE" 2>&1
}

# ---------------------------
# Docker + Compose
# ---------------------------
docker_works() {
  docker version >/dev/null 2>&1
}

install_docker() {
  log "\n==> Docker: перевірка"

  if have_cmd docker; then
    if docker_works; then
      log "✅ Docker OK: $(docker --version 2>/dev/null || true)"
      log "✅ Compose: $(docker compose version 2>/dev/null || true)"
      return 0
    fi

    # WSL special case: docker stub exists but integration is disabled
    if is_wsl; then
      log "⚠️ Docker команда є, але демон недоступний у WSL."
      log "👉 Відкрий Docker Desktop (Windows) → Settings → Resources → WSL integration → увімкни для твоєї Ubuntu."
      log "Після цього перевір: docker version"
      return 0
    fi
  fi

  # Native Linux install path
  log "==> Docker не знайдено. Встановлюю через офіційний репозиторій…"

  if [[ "${OS_ID}" != "ubuntu" && "${OS_ID}" != "debian" ]]; then
    log "⚠️  Скрипт розрахований на Ubuntu/Debian. На ${OS_ID} може не спрацювати авто-інстал."
  fi

  apt_install ca-certificates curl gnupg lsb-release

  $SUDO install -m 0755 -d /etc/apt/keyrings >>"$LOG_FILE" 2>&1 || true

  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg"       | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg >>"$LOG_FILE" 2>&1
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg >>"$LOG_FILE" 2>&1
  fi

  if [[ -z "${CODENAME}" ]]; then
    CODENAME="$(lsb_release -cs 2>/dev/null || echo noble)"
  fi

  ARCH="$($SUDO dpkg --print-architecture 2>/dev/null || echo amd64)"

  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS_ID} ${CODENAME} stable"     | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

  $SUDO apt-get update -y >>"$LOG_FILE" 2>&1
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log "✅ Docker встановлено: $(docker --version 2>/dev/null || true)"
  log "✅ Compose: $(docker compose version 2>/dev/null || true)"

  # Add user to docker group (non-fatal)
  if [[ -n "${SUDO}" ]]; then
    if getent group docker >/dev/null 2>&1; then
      if id -nG "$USER" | grep -qw docker; then
        log "Користувач $USER вже в групі docker."
      else
        log "Додаю $USER до групи docker (потрібен релогін/перезапуск shell)."
        $SUDO usermod -aG docker "$USER" >>"$LOG_FILE" 2>&1 || true
      fi
    fi
  fi
}

# ---------------------------
# Python + venv + deps
# ---------------------------
python_ge_39() {
  python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,9) else 1)' >/dev/null 2>&1
}

ensure_python() {
  log "\n==> Python: перевірка"
  if have_cmd python3 && python_ge_39; then
    log "✅ Python OK: $(python3 --version 2>/dev/null || true)"
  else
    log "==> Встановлюю python3 + venv + pip…"
    apt_install python3 python3-venv python3-pip
    log "Python тепер: $(python3 --version 2>/dev/null || true)"
  fi
}

ensure_venv() {
  log "\n==> venv: створення/перевірка"
  if [[ ! -d "${VENV_DIR}" ]]; then
    python3 -m venv "${VENV_DIR}" >>"$LOG_FILE" 2>&1
    log "✅ Створено venv: ${VENV_DIR}"
  else
    log "✅ venv вже існує: ${VENV_DIR}"
  fi
}

venv_pip() {
  "${VENV_DIR}/bin/python" -m pip "$@"
}

pip_install_if_missing() {
  local pkg="$1"
  local import_name="$2"

  if "${VENV_DIR}/bin/python" -c "import ${import_name}" >/dev/null 2>&1; then
    log "✅ ${pkg} вже встановлено (venv)"
  else
    log "==> Встановлюю ${pkg} (venv)…"
    venv_pip install --no-cache-dir "${pkg}" >>"$LOG_FILE" 2>&1
    log "✅ ${pkg} встановлено (venv)"
  fi
}

install_python_deps() {
  log "\n==> Python deps у venv: Django / torch / torchvision / pillow"

  venv_pip install --upgrade pip >>"$LOG_FILE" 2>&1 || true

  pip_install_if_missing "Django" "django"

  if "${VENV_DIR}/bin/python" -c "import torch, torchvision" >/dev/null 2>&1; then
    log "✅ torch/torchvision вже встановлено (venv)"
  else
    log "==> Встановлюю torch + torchvision (CPU) (venv)…"
    venv_pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu >>"$LOG_FILE" 2>&1
    log "✅ torch/torchvision встановлено (venv)"
  fi

  pip_install_if_missing "pillow" "PIL"
}

print_versions() {
  log "\n==> Версії:"
  log "Docker:   $(docker --version 2>/dev/null || echo N/A)"
  log "Compose:  $(docker compose version 2>/dev/null || echo N/A)"
  log "Python:   $(python3 --version 2>/dev/null || echo N/A)"
  log "Venv Python: $(${VENV_DIR}/bin/python --version 2>/dev/null || echo N/A)"
  log "pip (venv):  $(${VENV_DIR}/bin/python -m pip --version 2>/dev/null || echo N/A)"
  log "Django (venv): $(${VENV_DIR}/bin/python -m django --version 2>/dev/null || echo N/A)"
  log "torch (venv): $(${VENV_DIR}/bin/python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo N/A)"
  log "torchvision (venv): $(${VENV_DIR}/bin/python -c 'import torchvision; print(torchvision.__version__)' 2>/dev/null || echo N/A)"
  log "pillow (venv): $(${VENV_DIR}/bin/python -c 'import PIL; print(PIL.__version__)' 2>/dev/null || echo N/A)"
}

# ---------------------------
# Main
# ---------------------------
log "Починаю встановлення/перевірки…"
install_docker
ensure_python
ensure_venv
install_python_deps
print_versions

log "\n✅ Готово."
log "ℹ️ Активувати venv: source ${VENV_DIR}/bin/activate"
log "ℹ️ Якщо Docker у WSL не працює — увімкни WSL integration у Docker Desktop."
