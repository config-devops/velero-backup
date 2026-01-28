#!/bin/bash
set -e

echo "=============================================="
echo " Valero MinIO Installer / Patcher + Backup   "
echo "=============================================="
echo

# =========================
# USER INPUT CONFIG
# =========================
read -p "Namespace Valero [velero]: " VELERO_NS
VELERO_NS=${VELERO_NS:-velero}

read -p "MinIO S3 Endpoint (default: https://nos.jkt-1.neo.id): " S3_ENDPOINT
S3_ENDPOINT=${S3_ENDPOINT:-https://nos.jkt-1.neo.id}
read -p "Nama Bucket (default :bucket-file) " BUCKET
BUCKET=${BUCKET:-bucket-file}
read -p "Prefix Backup (default: velero-backup): " PREFIX
PREFIX=${PREFIX:-velero-backup}
read -p "Access Key: " ACCESS_KEY
read -s -p "Secret Key: " SECRET_KEY
echo

# =========================
# PRECHECK
# =========================
command -v kubectl >/dev/null || { echo "ERROR: kubectl tidak ditemukan"; exit 1; }

# =========================
# INSTALL VELERO CLI (LATEST)
# =========================
if ! command -v velero &>/dev/null; then
  echo "Velero CLI belum ada, ambil versi latest..."

  VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)

  echo "Velero version: ${VELERO_VERSION}"

  curl -L https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    | tar -xz

  sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero
  sudo chmod +x /usr/local/bin/velero

  echo "Velero CLI installed"
else
  echo "Velero CLI sudah ada → skip"
fi

# =========================
# DETECT VALERO SERVER
# =========================
if kubectl get ns ${VELERO_NS} &>/dev/null && \
   kubectl -n ${VELERO_NS} get deploy velero &>/dev/null; then
  MODE="patch"
  echo "Valero SERVER terdeteksi → MODE PATCH"
else
  MODE="install"
  echo "Valero SERVER belum ada → MODE INSTALL"
fi

# =========================
# CREATE CREDENTIAL FILE
# =========================
cat <<EOF > credentials-velero
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET_KEY}
EOF

# =========================
# INSTALL MODE
# =========================
if [[ "$MODE" == "install" ]]; then
  velero install \
    --namespace ${VELERO_NS} \
    --provider aws \
    --plugins velero/velero-plugin-for-aws \
    --bucket ${BUCKET} \
    --prefix ${PREFIX} \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=${S3_ENDPOINT}
fi

# =========================
# PATCH MODE
# =========================
if [[ "$MODE" == "patch" ]]; then
  kubectl -n ${VELERO_NS} apply -f - <<EOF
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: default
  namespace: ${VELERO_NS}
spec:
  provider: aws
  objectStorage:
    bucket: ${BUCKET}
    prefix: ${PREFIX}
  config:
    region: minio
    s3ForcePathStyle: "true"
    s3Url: ${S3_ENDPOINT}
EOF

  kubectl -n ${VELERO_NS} delete secret cloud-credentials --ignore-not-found

  kubectl -n ${VELERO_NS} create secret generic cloud-credentials \
    --from-file=cloud=credentials-velero
fi

# =========================
# RESTART & VALIDATE
# =========================
kubectl -n ${VELERO_NS} rollout restart deploy/velero
kubectl -n ${VELERO_NS} rollout status deploy/velero

kubectl -n ${VELERO_NS} get backupstoragelocation
echo

# ==================================================
# BACKUP SECTION (VERSI 2 + BONUS ALL)
# ==================================================
read -p "Namespace yang mau dibackup (pisahkan koma / ketik all): " INPUT_NS
read -p "Nama server ini (contoh: btu-cp-01) : " INPUT_HOST


TIMESTAMP=$(date +%Y%m%d)

if [[ "$INPUT_NS" == "all" ]]; then
  BACKUP_NAME="backup-all-${INPUT_HOST}"
  echo "Membuat backup SEMUA namespace: ${BACKUP_NAME}"

  velero backup create ${BACKUP_NAME} --wait
else
  IFS=',' read -ra NS_LIST <<< "$INPUT_NS"

  for NS in "${NS_LIST[@]}"; do
    NS=$(echo "$NS" | xargs)
    BACKUP_NAME="backup-${NS}-${INPUT_HOST}"

    echo "Membuat backup namespace: ${NS}"
    velero backup create ${BACKUP_NAME} \
      --include-namespaces ${NS} \
      --wait
  done
fi

echo
echo "=============================================="
echo " SEMUA BACKUP SELESAI 🎉"
velero backup get
echo "=============================================="
