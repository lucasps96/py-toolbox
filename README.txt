TOOLBOX — ambiente Docker genérico pra rodar scripts Python em um servidor
=========================================================================

O QUE É
-------
Uma imagem Docker única ("py-toolbox") com Python + Chromium/Playwright +
libs comuns (novas podem ser adcionadas), pra rodar qualquer script Python em um  servidor
sem precisar instalar nada no sistema operacional. Essa imagem também pode ser usada
por DockerOperator do Airflow.

Os scripts NÃO ficam dentro da imagem — cada projeto mantém seus próprios
.py em sua própria pasta. A toolbox só fornece o "motor" que roda esses
scripts. Isso significa: mudar um script não exige rebuild da imagem; só
rebuilda quando uma biblioteca nova precisa ser adicionada.

Arquivos desta pasta (/mnt/work/toolbox/):
    Dockerfile        - define a imagem (Python + Playwright + libs)
    requirements.txt   - lista de bibliotecas Python instaladas na imagem
    docker-run.sh       - atalho pra rodar um script dentro do container
    README.txt          - este arquivo


COMO RODAR UM SCRIPT JÁ EXISTENTE
----------------------------------
1. Entra na pasta do projeto (onde está o .py que quer rodar):

       cd /mnt/work/Projeto/scrape

2. Chama o script pelo docker-run.sh, com os argumentos normais dele:

       docker-run.sh bulk_scrape.py faltantes.xlsx --coluna url --saida produtos_novos.xlsx

O docker-run.sh monta a pasta ATUAL (de onde você chamou o comando) dentro
do container, então ele funciona de qualquer projeto/pasta do servidor —
não precisa copiar nada pra dentro da toolbox.


COMO ADICIONAR UMA BIBLIOTECA NOVA
------------------------------------
Se um script novo (ou um já existente) precisar de uma lib Python que
ainda não está instalada, você vai ver um erro tipo:

    ModuleNotFoundError: No module named 'nome_da_lib'

Pra resolver:

1. Entra na pasta da toolbox:

       cd /mnt/work/toolbox

2. Abre o requirements.txt e adiciona a lib numa linha nova:

       nano requirements.txt

3. Reconstrói a imagem (só precisa fazer isso quando muda o
   requirements.txt — não a cada script novo):

       docker build -t py-toolbox .

Pronto — a lib fica disponível pra QUALQUER script, em QUALQUER pasta do
servidor, porque todos compartilham a mesma imagem.


SOBRE O docker-run.sh FICAR NO PATH
--------------------------------------
O docker-run.sh está instalado em ~/bin (que está no PATH do usuário),
 então funciona digitando só "docker-run.sh" de qualquer pasta, sem
precisar do "./" na frente nem copiar o arquivo pra cada projeto.

Se precisar reinstalar isso num usuário/máquina novo:

    mkdir -p ~/bin
    cp docker-run.sh ~/bin/
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc


LIMPEZA / MANUTENÇÃO
---------------------
- Rodar um script cria arquivos de cache (__pycache__) na pasta do
  projeto, às vezes com dono "root" (porque o container roda como root
  por padrão). Se isso causar erro de permissão num build futuro:

      sudo rm -rf __pycache__

- Pra ver quanto espaço as imagens Docker estão ocupando:

      docker images

- Pra remover uma imagem antiga que não usa mais:

      docker rmi nome-da-imagem


POR QUE PLAYWRIGHT ESTÁ TRAVADO EM 1.47.0
--------------------------------------------
O requirements.txt fixa "playwright==1.47.0" de propósito. A imagem base
(mcr.microsoft.com/playwright/python:v1.47.0-jammy) já vem com o Chromium
da versão 1.47 baixado no disco. Se o pacote Python "playwright" for
instalado numa versão diferente (por exemplo, sem travar, ele baixa a mais
recente), ele vai tentar abrir um Chromium que não existe na imagem e vai
dar erro. Se um dia quiser atualizar, precisa trocar a tag da imagem base
no Dockerfile E a versão do playwright no requirements.txt juntas, pro
mesmo número.


