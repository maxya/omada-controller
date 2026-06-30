# External MongoDB

The default MongoDB service is already external to the Omada controller container. To use a separately managed MongoDB instance, set `OMADA_MONGODB_URI` for the controller and provide equivalent users and permissions.

The Omada application user needs access to `omada` and `omada_data`:

```javascript
roles: [
  { role: "readWrite", db: "omada" },
  { role: "dbOwner", db: "omada" },
  { role: "readWrite", db: "omada_data" },
  { role: "dbOwner", db: "omada_data" }
]
```

The backup user should use MongoDB's `backup` role on `admin` plus read access to Omada databases.

## Connection URI

Use the `omada` database as the URI path and authentication source unless your MongoDB deployment requires a different layout:

```text
mongodb://omada:<password>@<mongo-host>:27017/omada?authSource=omada
```

Keep MongoDB behind a private network or firewall. Do not expose it directly to the LAN or internet.

## Initialization Note

The official MongoDB image runs initialization scripts only when `/data/db` is empty. If you connect this stack to an existing MongoDB deployment, create or update users with `mongosh` instead of relying on the included init scripts.
