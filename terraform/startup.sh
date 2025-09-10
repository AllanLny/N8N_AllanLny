
#!/bin/bash
# filepath: terraform/startup.sh

N8N_DOMAIN="${N8N_DOMAIN:-$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/n8n_domain)}"
N8N_SSL_EMAIL="${N8N_SSL_EMAIL:-$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/n8n_ssl_email)}"

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

# Attente active que Docker soit prêt
echo "[startup] Attente que Docker soit prêt..."
for i in {1..20}; do
  if docker info > /dev/null 2>&1; then
    echo "[startup] Docker est prêt."
    break
  fi
  echo "[startup] Docker pas encore prêt, attente... ($i)"
  sleep 3
done

echo "[startup] Création du volume Docker n8n_data"
docker volume create n8n_data


echo "[startup] Suppression de tous les conteneurs n8n existants (même stoppés ou en erreur)"
for cid in $(docker ps -a -q --filter name=^/n8n$); do
  echo "[startup] Suppression du conteneur $cid"
  docker rm -f $cid || true
done

echo "[startup] Lancement du conteneur n8n"
if docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n
then
  echo "[startup] Fin lancement n8n : OK"
else
  echo "[startup][ERREUR] Le lancement du conteneur n8n a échoué !" >&2
  exit 2
fi

echo "[startup] Vérification de l'installation de Nginx"
if [ ! -d /etc/nginx/sites-available ]; then
  echo "Nginx n'est pas installé ou le dossier sites-available est absent"
  exit 1
fi

echo "[startup] Configuration de Nginx comme reverse proxy pour n8n"
cat >/etc/nginx/sites-available/n8n <<EOF
server {
    listen 80 default_server;
    server_name $N8N_DOMAIN _;

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


# --- Ajout automatique du SSL Let's Encrypt ---
echo "[startup] Installation de Certbot et génération du certificat SSL Let's Encrypt"
apt-get install -y certbot python3-certbot-nginx

# Attendre que Nginx soit accessible en HTTP avant de lancer Certbot
for i in {1..15}; do
  if curl -s --head --fail http://localhost | grep -q '200 OK'; then
    echo "[startup] Nginx est accessible en HTTP."
    break
  fi
  echo "[startup] Nginx pas encore accessible en HTTP, attente... ($i)"
  sleep 2
done

# Lancer Certbot et logguer la sortie
echo "[startup] Lancement de Certbot pour $N8N_DOMAIN"
if certbot --nginx --non-interactive --agree-tos --redirect -d "$N8N_DOMAIN" -m "$N8N_SSL_EMAIL" > /var/log/certbot-startup.log 2>&1; then
  echo "[startup] Certificat SSL Let's Encrypt configuré."
else
  echo "[startup][ERREUR] Certbot a échoué. Voir /var/log/certbot-startup.log pour le détail."
fi

echo "[startup] Statut des services pour debug"
systemctl status docker --no-pager
systemctl status nginx --no-pager

echo "[startup] Installation et configuration terminées. n8n est accessible via Nginx."

echo "Contenu du script" > /root/startup.sh