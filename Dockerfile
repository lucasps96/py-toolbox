FROM mcr.microsoft.com/playwright/python:v1.47.0-jammy

WORKDIR /app

# LibreOffice Calc (modo headless) — usado por scripts que precisam abrir/
# converter arquivos .xlsx malformados (ex.: OOXML "strict" com referências
# externas quebradas, que o openpyxl não consegue ler direto). Só o pacote
# "calc", não a suíte inteira, pra manter a imagem mais enxuta.
RUN apt-get update && \
    apt-get install -y --no-install-recommends libreoffice-calc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# nada de COPY de scripts aqui — eles vêm via volume em tempo de execução

ENTRYPOINT ["python"]
