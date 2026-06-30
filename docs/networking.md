# Omada Controller Networking

## Host Mode

`compose/docker-compose.host.yml` is the default. The controller uses `network_mode: host` so Omada discovery and adoption traffic behaves like a bare-metal controller on the LAN.

MongoDB also uses host networking in this mode, but it is explicitly bound to `127.0.0.1`:

```yaml
command: ["--bind_ip", "127.0.0.1", "--wiredTigerCacheSizeGB", "${MONGO_CACHE_GB:-0.5}"]
```

Do not remove this binding unless you intentionally want MongoDB reachable outside the host and have firewall rules in place.

Use host mode when:

- The Docker host is on the same LAN as Omada devices.
- You want automatic device discovery.
- You want the simplest adoption path for access points, switches, and gateways.

## Bridge Mode

Bridge mode publishes the known Omada ports, but LAN devices cannot naturally discover a controller behind Docker's bridge address. Use bridge mode only when host networking is unacceptable.

Bridge adoption usually requires one of:

- DHCP Option 138 pointing devices to the host/controller address.
- Manual Inform URL from the device UI or SSH.
- TP-Link discovery utility.

Keep internal and external ports the same unless you also change Omada properties.

Use bridge mode when:

- You need container network isolation.
- You can configure device adoption manually.
- You have firewall rules that explicitly allow the published Omada ports.

## Macvlan

`compose/docker-compose.macvlan.example.yml` is an example only. Macvlan can give the controller its own LAN IP, which helps adoption, but host-to-container connectivity and router behavior are host-specific.

Use macvlan only after adjusting the example for your subnet, gateway, parent interface, and desired controller IP.

## IPv6

This stack is IPv4-first. Omada discovery and adoption workflows are mostly IPv4-centric, and the default MongoDB URI uses `127.0.0.1` to avoid Java resolving `localhost` to `::1` on hosts where MongoDB is not bound to IPv6.

## Port Summary

Common Omada ports include:

- `8088/tcp`: management HTTP.
- `8043/tcp`: management HTTPS.
- `8843/tcp`: portal HTTPS.
- `19810/udp`, `27001/udp`, `29810/udp`: discovery-related traffic.
- `29811-29817/tcp`: device management, adoption, upgrade, transfer, terminal, and monitor traffic.

Check local firewall rules when adoption or login fails.
