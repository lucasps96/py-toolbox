# TOOLBOX

> Ambiente Docker genérico para rodar scripts Python em um servidor.

## O que é

Uma imagem Docker única (`py-toolbox`) com **Python + Chromium/Playwright + bibliotecas comuns**, para rodar scripts Python em um servidor sem precisar instalar as dependências diretamente no sistema operacional.

A imagem também pode ser usada pelo `DockerOperator` do Airflow.

Os scripts **não ficam dentro da imagem**. Cada projeto mantém seus próprios arquivos `.py` em sua própria pasta. A toolbox fornece apenas o ambiente de execução desses scripts.

Isso significa que:

- mudar um script **não exige rebuild** da imagem;
- a imagem só precisa ser reconstruída quando uma biblioteca nova precisa ser adicionada ou quando o próprio ambiente da toolbox é alterado.

---

## Estrutura

A pasta da toolbox fica em:

```text
/mnt/work/toolbox/
```

Arquivos principais:

| Arquivo | Função |
|---|---|
| `Dockerfile` | Define a imagem Docker (Python + Playwright + bibliotecas). |
| `requirements.txt` | Lista as bibliotecas Python instaladas na imagem. |
| `docker-run.sh` | Atalho para executar um script dentro do container. |
| `README.md` | Documentação da toolbox. |

A organização dos projetos é independente da toolbox. Por exemplo:

```text
/mnt/work/
├── toolbox/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── docker-run.sh
│   └── README.md
│
├── Projeto/
│   └── scrape/
│       ├── bulk_scrape.py
│       └── faltantes.xlsx
│
└── outro-projeto/
    └── script.py
```

---

## Como rodar um script existente

Entre na pasta do projeto onde está o script:

```bash
cd /mnt/work/Projeto/scrape
```

Execute o script usando o `docker-run.sh`:

```bash
docker-run.sh bulk_scrape.py faltantes.xlsx --coluna url --saida produtos_novos.xlsx
```

O `docker-run.sh` monta a **pasta atual** dentro do container. Por isso, ele pode ser usado a partir de qualquer projeto ou pasta do servidor.

Não é necessário copiar os scripts para dentro da toolbox.

### Conceito

```text
Projeto
   │
   ├── script.py
   ├── arquivos de entrada
   └── arquivos de saída
           │
           ↓
    docker-run.sh
           │
           ↓
      py-toolbox
           │
           └── executa o script
```

---

## Como adicionar uma biblioteca nova

Se um script precisar de uma biblioteca que ainda não está instalada, será exibido um erro semelhante a:

```text
ModuleNotFoundError: No module named 'nome_da_lib'
```

### 1. Entre na pasta da toolbox

```bash
cd /mnt/work/toolbox
```

### 2. Adicione a biblioteca ao `requirements.txt`

```bash
nano requirements.txt
```

Adicione a biblioteca em uma nova linha.

### 3. Reconstrua a imagem

```bash
docker build -t py-toolbox .
```

O rebuild só é necessário quando o `requirements.txt` ou outro componente usado na construção da imagem for alterado.

Depois disso, a biblioteca estará disponível para qualquer script executado com a imagem `py-toolbox`.

---

## `docker-run.sh` no PATH

O `docker-run.sh` está instalado em:

```text
~/bin
```

Como `~/bin` está no `PATH` do usuário, é possível executar:

```bash
docker-run.sh
```

a partir de qualquer pasta, sem precisar usar:

```bash
./docker-run.sh
```

Também não é necessário copiar o script para cada projeto.

### Reinstalar em outro usuário ou máquina

```bash
mkdir -p ~/bin
cp docker-run.sh ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Limpeza e manutenção

### `__pycache__`

A execução de scripts pode criar arquivos de cache `__pycache__` na pasta do projeto.

Como o container roda como `root` por padrão, esses arquivos podem eventualmente ficar com proprietário `root`.

Se isso causar problemas de permissão:

```bash
sudo rm -rf __pycache__
```

### Ver imagens Docker

Para verificar o espaço ocupado pelas imagens:

```bash
docker images
```

### Remover uma imagem

Para remover uma imagem antiga que não é mais utilizada:

```bash
docker rmi nome-da-imagem
```

---

## Por que o Playwright está travado em `1.47.0`?

O `requirements.txt` fixa:

```text
playwright==1.47.0
```

de propósito.

A imagem base utilizada pelo Dockerfile:

```text
mcr.microsoft.com/playwright/python:v1.47.0-jammy
```

já contém o Chromium correspondente à versão 1.47.

Se o pacote Python `playwright` for instalado em uma versão diferente, por exemplo sem fixar a versão, ele poderá tentar utilizar uma versão do Chromium que não está presente na imagem.

Isso pode resultar em erro na execução.

### Para atualizar o Playwright

A versão do Playwright deve ser atualizada **em conjunto**:

1. alterar a versão da imagem base no `Dockerfile`;
2. alterar a versão do `playwright` no `requirements.txt`;
3. reconstruir a imagem.

As versões precisam permanecer compatíveis.

---

## Observações e futuro

A `py-toolbox` foi criada para funcionar como um **ambiente Python compartilhado** para os projetos de automação do servidor.

A ideia é manter uma imagem simples e estável, adicionando bibliotecas que sejam úteis para mais de um projeto, desde que sejam bibliotecas simples.

Enquanto as dependências forem compatíveis entre si, todos os projetos podem utilizar a mesma imagem. Não é necessário criar uma nova imagem para cada script ou projeto.

Se, no futuro, surgirem conflitos entre versões de bibliotecas ou projetos com necessidades muito diferentes, podem ser criadas imagens derivadas ou especializadas, por exemplo:

```text
py-toolbox
py-toolbox-scraping
py-toolbox-data
```

Isso só deve ser feito quando houver uma necessidade real, evitando complexidade desnecessária.

### Possíveis evoluções

A prioridade é manter a `py-toolbox` simples. Novas camadas de complexidade devem ser adicionadas apenas quando resolverem um problema concreto.
