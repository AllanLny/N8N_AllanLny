#!/bin/bash
# Script d'init pour installer Docker et lancer n8n

# MAJ & install Docker
apt-get update && apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Créer dossier persistant pour n8n
docker volume create n8n_data

# Lancer n8n (port 5678, données persistantes)
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n
