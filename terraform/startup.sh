
#!/bin/bash
# filepath: terraform/startup.sh

# Active le mode debug et redirige toute la sortie vers un log
set -x
exec > >(tee -a /var/log/startup-script.log) 2>&1

echo "[startup] Début du script"

echo "[startup] Mise à jour du système et installation de Docker & Nginx"
apt-get update -y && apt-get install -y docker.io nginx
echo "[startup] Fin installation paquets"

echo "[startup] Activation et démarrage de Docker"
systemctl start docker
systemctl enable docker

echo "[startup] Création du volume Docker n8n_data"
docker volume create n8n_data

echo "[startup] Arrêt et suppression d'un ancien conteneur n8n si existant"
if [ "$(docker ps -aq -f name=n8n)" ]; then
  docker stop n8n || true
  docker rm n8n || true
fi

echo "[startup] Lancement du conteneur n8n"
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n
echo "[startup] Fin lancement n8n"

echo "[startup] Vérification de l'installation de Nginx"
if [ ! -d /etc/nginx/sites-available ]; then
  echo "Nginx n'est pas installé ou le dossier sites-available est absent"
  exit 1
fi

echo "[startup] Configuration de Nginx comme reverse proxy pour n8n"
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

echo "[startup] Activation de la config n8n et désactivation du site par défaut"
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-enabled/default

echo "[startup] Test de la config Nginx et redémarrage"
nginx -t && systemctl restart nginx

echo "[startup] Statut des services pour debug"
systemctl status docker --no-pager
systemctl status nginx --no-pager

echo "[startup] Installation et configuration terminées. n8n est accessible via Nginx."

echo "Contenu du script" > /root/startup.sh