echo
echo "=============================================="
echo " RESTORE SECTION"
echo "=============================================="

echo "Daftar backup tersedia:"
velero backup get
echo

read -p "Masukkan NAMA BACKUP yang mau direstore: " RESTORE_BACKUP

read -p "Restore ke namespace baru? (y/n): " RESTORE_NEW_NS

if [[ "$RESTORE_NEW_NS" == "y" ]]; then
  read -p "Nama namespace baru: " TARGET_NS
  read -p "Nama namespace asal yang mau di restore: " SRC_NS

  RESTORE_NAME="restore-${RESTORE_BACKUP}-$(date +%d%m%Y)"

  echo "Restore backup ${RESTORE_BACKUP} ke namespace ${TARGET_NS}"

  velero restore create ${RESTORE_NAME}  --from-backup ${RESTORE_BACKUP} --include-namespaces ${SRC_NS} --namespace-mappings ${SRC_NS}=${TARGET_NS} --wait
else
  RESTORE_NAME="restore-${RESTORE_BACKUP}-$(date +%d%m%Y)"

  echo "Restore backup ${RESTORE_BACKUP} ke namespace ASLI"

  velero restore create ${RESTORE_NAME} \
    --from-backup ${RESTORE_BACKUP} \
    --wait
fi

echo
echo "=============================================="
echo " RESTORE SELESAI 🎉"
velero restore get
echo "=============================================="
