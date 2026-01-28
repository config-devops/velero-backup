# ==================================================
# BACKUP SECTION (VERSI 2 + BONUS ALL)
# ==================================================
read -p "Namespace yang mau dibackup (pisahkan koma / ketik all): " INPUT_NS
read -p "Nama server ini (contoh: btu-cp-01) : " INPUT_HOST


TIMESTAMP=$(date +%d%m%Y)

if [[ "$INPUT_NS" == "all" ]]; then
  BACKUP_NAME="backup-all-${INPUT_HOST}-${TIMESTAMP}"
  echo "Membuat backup SEMUA namespace: ${BACKUP_NAME}"

  velero backup create ${BACKUP_NAME} --wait
else
  IFS=',' read -ra NS_LIST <<< "$INPUT_NS"

  for NS in "${NS_LIST[@]}"; do
    NS=$(echo "$NS" | xargs)
    BACKUP_NAME="backup-${NS}-${INPUT_HOST}-${TIMESTAMP}"

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
