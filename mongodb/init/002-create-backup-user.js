const backupUser = process.env.OMADA_MONGO_BACKUP_USER || "omada_backup";
const backupPassword = process.env.OMADA_MONGO_BACKUP_PASSWORD;

if (!backupPassword) {
  throw new Error("OMADA_MONGO_BACKUP_PASSWORD is required");
}

db = db.getSiblingDB("admin");
db.createUser({
  user: backupUser,
  pwd: backupPassword,
  roles: [
    { role: "backup", db: "admin" },
    { role: "read", db: "omada" },
    { role: "read", db: "omada_data" }
  ]
});

