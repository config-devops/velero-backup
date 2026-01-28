# 🚀 Valero MinIO Backup & Restore (Interactive SRE Script)

Dokumentasi ini menjelaskan cara **install / patch Valero**, **backup**, dan **restore** Kubernetes menggunakan **Valero + MinIO (S3-compatible)** dengan **script interaktif**.

Script ini **aman untuk cluster existing**, cocok untuk:
- Kubernetes + KubeSphere
- MinIO / S3-compatible storage
- Backup per-namespace atau full (`all`)
- Restore ke namespace baru (DR test / cloning)

---

## 🧩 Fitur Utama

- ✅ Auto-install **Valero CLI (latest)** jika belum ada
- ✅ Detect Valero server existing (install / patch)
- ✅ Konfigurasi MinIO interaktif
- ✅ Backup:
  - multiple namespace
  - atau `all`
- ✅ Restore:
  - dari backup per-namespace
  - dari backup `all` → **namespace baru**
- ❌ Tidak pakai wildcard berbahaya (`*=xxx`)
- 🛡 Aman untuk production

---

## 📦 Requirement

Pastikan di server / bastion:

- `kubectl` sudah terkonfigurasi ke cluster
- Akses ke endpoint MinIO
- Permission create resource di namespace `velero`

Cek:
```bash
kubectl get nodes
```
## Running script install velero dan lakukan Backup
```bash
curl -O https://raw.githubusercontent.com/config-devops/velero-backup/refs/heads/main/velero-install-patch-backup.sh

chmod +x velero-install-patch-backup.sh

./velero-install-patch-backup.sh
```

## Running hanya backup (jika velero sudah ada)
```bash
curl -O https://raw.githubusercontent.com/config-devops/velero-backup/refs/heads/main/backup.sh

chmod +x backup.sh

./backup.sh
```

## restore namespace
```bash
curl -O https://raw.githubusercontent.com/config-devops/velero-backup/refs/heads/main/restore.sh

chmod +x restore.sh

./restore.sh
```
