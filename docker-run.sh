#!/usr/bin/env bash
# Uso:
#   cd /mnt/work/outro-projeto
#   docker-run.sh outro_script.py --algum-argumento

set -euo pipefail

docker run --rm -it \
    -v "$(pwd)":/app \
    py-toolbox \
    "$@"
