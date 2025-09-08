#!/bin/bash

# Script d'init pour installer Docker, Nginx et lancer n8n

# MAJ & install Docker et Nginx
apt-get update && apt-get install -y docker.io nginx

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

# Vérifier que Nginx est bien installé
if [ ! -d /etc/nginx/sites-available ]; then
  echo "Nginx n'est pas installé ou le dossier sites-available est absent"
  exit 1
fi

# Configurer Nginx comme reverse proxy
cat >/etc/nginx/sites-available/n8n <<EOF
server {
  listen 80 default_server;
  server_name n8nallanlny.freeddns.org _;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx