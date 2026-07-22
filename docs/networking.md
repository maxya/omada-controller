# Omada Controller Networking

## Host Mode

`compose/docker-compose.host.yml` is the default. The controller uses `network_mode: host` so Omada discovery and adoption traffic behaves like a bare-metal controller on the LAN.

MongoDB does not publish a host port in this mode. It runs on a dedicated Docker bridge network, and the host-networked controller reaches it through a stable private container address:

```yaml
networks:
  omada-controller:
    name: omada-controller
    driver: bridge
    ipam:
      config:
        - subnet: ${OMADA_MONGO_SUBNET:-172.28.0.0/24}
```

The default MongoDB address is `${OMADA_MONGO_IPV4:-172.28.0.10}`. Override `OMADA_MONGO_SUBNET` and `OMADA_MONGO_IPV4` if that subnet overlaps another local Docker or LAN route. Do not add a MongoDB `ports:` mapping unless you intentionally want the database reachable from the host or LAN and have firewall rules in place.

If `make up` fails with `Pool overlaps with other one on this address space`, choose another private subnet and keep the MongoDB IP inside it:

```env
OMADA_MONGO_SUBNET=172.31.240.0/24
OMADA_MONGO_IPV4=172.31.240.10
```

To inspect existing Docker network pools:

```sh
docker network inspect $(docker network ls -q) --format '{{.Name}} {{range .IPAM.Config}}{{.Subnet}} {{end}}'
```

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

This stack is IPv4-first. Omada discovery and adoption workflows are mostly IPv4-centric, and the default host-mode MongoDB URI uses the private IPv4 address assigned on the `omada-controller` Docker bridge.

## Port Summary

Common Omada ports include:

- `8088/tcp`: management HTTP.
- `8043/tcp`: management HTTPS.
- `8843/tcp`: portal HTTPS.
- `19810/udp`, `27001/udp`, `29810/udp`: discovery-related traffic.
- `29811-29817/tcp`: device management, adoption, upgrade, transfer, terminal, and monitor traffic.

Check local firewall rules when adoption or login fails.
