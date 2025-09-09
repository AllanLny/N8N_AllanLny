#!/bin/bash
# filepath: terraform/startup.sh

# Met à jour le système et installe Docker & Nginx
apt-get update -y && apt-get install -y docker.io nginx

# Active et démarre Docker
systemctl start docker
systemctl enable docker

# Crée un volume Docker persistant pour n8n
docker volume create n8n_data

# Arrête et supprime tout ancien conteneur n8n s'il existe
if [ "$(docker ps -aq -f name=n8n)" ]; then
  docker stop n8n || true
  docker rm n8n || true
fi

# Lance n8n (port 5678, données persistantes)
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n

# Vérifie que Nginx est bien installé
if [ ! -d /etc/nginx/sites-available ]; then
  echo "Nginx n'est pas installé ou le dossier sites-available est absent"
  exit 1
fi

# Configure Nginx comme reverse proxy pour n8n
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

# Active la config n8n et désactive le site par défaut
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-enabled/default

# Teste la config Nginx et redémarre
nginx -t && systemctl restart nginx

# Affiche l'état des services pour debug
systemctl status docker --no-pager
systemctl status nginx --no-pager

echo "Installation et configuration terminées. n8n est accessible via Nginx."

echo "Contenu du script" > /root/startup.sh