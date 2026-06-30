# Omada Device Adoption

Host mode is the recommended default for home-lab and small-site deployments because Omada device discovery uses LAN broadcast/multicast-style workflows and fixed management ports.

## Host Mode

Host networking gives the Omada Software Controller direct access to the host network. This is the simplest path for adopting TP-Link Omada access points, switches, and gateways.

1. Start the stack with `make up`.
2. Open `https://<host-ip>:8043/`.
3. Complete first-run setup.
4. Adopt devices from the Omada UI.

If devices do not appear, confirm they are on the same LAN or VLAN as the Docker host and that local firewalls allow Omada discovery and management ports.

## Bridge Mode

If using `make up-bridge`, devices may not discover the controller automatically. Use one of these paths:

- Configure DHCP Option 138 to the Docker host IP.
- Set the device Inform URL manually.
- Use TP-Link's discovery utility.

Required published ports are documented in `compose/docker-compose.bridge.yml`.

Use bridge mode when you need Docker network isolation and are comfortable configuring adoption manually. For most simple LAN deployments, host mode is easier.

## Port 29817

Omada v6 uses `29817/tcp` in addition to older adoption and management ports. Firewalls and bridge-mode mappings must include it.

## Troubleshooting Checklist

- Confirm the controller is reachable at `https://<host-ip>:8043/`.
- Confirm Docker host firewalls allow the Omada TCP and UDP ports.
- In bridge mode, confirm DHCP Option 138 or the manual Inform URL points to the host IP.
- Keep internal and external port numbers the same unless you also change Omada properties.
