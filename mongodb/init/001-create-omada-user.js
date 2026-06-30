const user = process.env.OMADA_MONGO_USER || "omada";
const password = process.env.OMADA_MONGO_PASSWORD;

if (!password) {
  throw new Error("OMADA_MONGO_PASSWORD is required");
}

db = db.getSiblingDB("omada");
db.createUser({
  user,
  pwd: password,
  roles: [
    { role: "readWrite", db: "omada" },
    { role: "dbOwner", db: "omada" },
    { role: "readWrite", db: "omada_data" },
    { role: "dbOwner", db: "omada_data" }
  ]
});

