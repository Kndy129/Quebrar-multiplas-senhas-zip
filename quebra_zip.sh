#!/bin/bash

# ZIP inicial
zipfile="aqui é o nome do primeiro arquivo.zip"

# Pasta temporária para extrair
mkdir -p tmp/processed
mkdir -p tmp/extracted

# Arquivo para salvar as senhas
senha_file="senhas.txt"
> "$senha_file"  # limpa o arquivo se existir

# Fila de ZIPs para processar
queue=("$zipfile")

while [[ ${#queue[@]} -gt 0 ]]; do
    zipfile="${queue[0]}"
    queue=("${queue[@]:1}")  # remove o primeiro elemento da fila

    echo "[+] Tentando quebrar: $zipfile"

    # Gerar hash
    zip2john "$zipfile" > zip.hash

    # Rodar John
    /usr/local/bin/john --wordlist=/usr/share/wordlists/rockyou.txt --rules zip.hash

    # Pegar a senha descoberta
    password=$(/usr/local/bin/john --show zip.hash | awk -F: '{print $2}')
    echo "[+] Senha encontrada: $password"

    # Salvar a senha em senhas.txt
    echo "$zipfile : $password" >> "$senha_file"

    # Extrair para a pasta tmp/extracted
    unzip -o -P "$password" "$zipfile" -d tmp/extracted

    # Encontrar todos os ZIPs extraídos e adicioná-los à fila
    while IFS= read -r z; do
        # Só adicionar se ainda não estiver na fila
        if [[ ! " ${queue[@]} " =~ " $z " ]]; then
            queue+=("$z")
        fi
    done < <(find tmp/extracted -type f -name "*.zip")

    # Mover o ZIP processado para tmp/processed
    mv "$zipfile" tmp/processed/
done

echo "[+] Todos os ZIPs foram processados!"
echo "[+] Senhas salvas em $senha_file"
