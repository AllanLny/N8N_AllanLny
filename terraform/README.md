# README pour déploiement n8n sur GCP Free Tier avec Terraform

1. Installez Terraform et gcloud CLI
2. Initialisez le projet GCP et récupérez votre project_id
3. Modifiez `terraform.tfvars` avec votre project_id
4. Dans ce dossier :
   ```bash
   terraform init
   terraform apply
   ```
5. Accédez à n8n sur http://[EXTERNAL_IP]:5678

---

## Sécurité
- Changez le port si besoin dans `main.tf` et `startup.sh`.

---

## Pour importer le workflow n8n
- Une fois n8n lancé, allez sur http://[EXTERNAL_IP]:5678
- Menu > Importer workflow > collez le JSON fourni plus bas

---
