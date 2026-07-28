# Phase 0: Design Worksheet

## Project Scenario

RouteWell, a regional logistics company, is redesigning its network after a contractor's laptop on the same flat network as the production database caused a near-miss data exposure. The redesign must keep the dispatch web app internet-reachable, keep the database completely unreachable from the internet, allow only the minimum necessary ports between tiers, stay lean on cost, and have enough headroom for dispatch staff, and therefore app-tier traffic to double within six months.

---

## 2.1 CIDR planning

| Tier | Hosts needed now | Hosts needed in 6 months | Subnet mask | CIDR range | Why this size (not smaller/larger) |
|---|---|---|---|---|---|
| Web | 12 | 12 (no stated growth because web tier scales via the App Gateway's backend pool, not by adding more VMs) | `/27` | `10.123.1.0/27` | A `/27` gives 27 usable addresses (32 total, minus 5 reserved by Azure). A `/28` would only provide 11 usable which is already short of today's 12 hosts. `/27` is the smallest size that covers the current requirement with reasonable room for an additional web VM later. |
| App | 20 | 40 | `/26` | `10.123.2.0/26` | A `/26` gives 59 usable addresses (64 total, minus 5 reserved). This is the smallest subnet size that comfortably covers the stated 6-month target of 40 hosts. A `/27` (27 usable) would already fall short of that projection. Sizing to the 6-month number now avoids re-carving this subnet later, which would mean re-IPing live VMs. |
| DB | 6 | 6 (no stated growth, the database tier is not expected to scale horizontally the way the app tier is) | `/28` | `10.123.3.0/28` | A `/28` gives 11 usable addresses, covering today's 6 hosts with room for a future read replica or a monitoring agent's own NIC, without over-allocating a much larger block to a tier that isn't expected to grow like the app tier. |

**Working shown:** usable host count per subnet = 2^(32 − prefix) − 5, since Azure reserves 5 addresses per subnet (network address, default gateway, two for DNS, and the broadcast address). Each tier's mask was chosen as the *smallest* size that still covers its 6-month projection not the largest available, and not a blanket `/24` for convenience.

All three subnets fit inside the assigned `10.10.0.0/16` VNet with the majority of the address space still unused, leaving room to carve additional subnets later (for example, a dedicated Application Gateway subnet, or a future bastion/jump-host subnet) without needing to resize any tier already in use.

---

## 2.2 NSG rule justification

| Direction | Source tier | Dest tier | Port(s) | Why this rule exists / what breaks without it |
|---|---|---|---|---|
| Inbound | Internet (via public entry point) | Web | 80 | This is the sole path users have into the dispatch app. Without it, the site is completely unreachable because there is no other route in. |
| Inbound | Web | App | 8080 | The web tier calls the backend API over this port to serve dispatch data. Without it, the site loads its static shell but every dispatch request fails, since the frontend has no way to reach the backend. |
| Inbound | App | DB | 5432 (Postgres) | The backend reads and writes driver and customer records over this port. Without it, no dispatch operation that touches data can succeed, meaning, the app tier would be reachable but functionally useless. |
| Inbound | Any (including Web) | DB | Deny-all (`*`) | Azure's default NSG behavior still permits any traffic that originates inside the same VNet, regardless of tier. Without an explicit deny rule sitting above that default, Web (or anything else added to the VNet later) could reach the database directly, silently violating the compliance requirement that the DB tier is only ever reached through the App tier, even though no rule was written to intentionally allow it. |
| Inbound | Scoped admin source (specific IP) | Web / App / DB | 22 (SSH) | Without this, there is no way to patch, debug, or redeploy onto any VM remotely, every change would require console-only access. Scoping it (rather than leaving it open to `Any`) means an engineer's laptop is the only thing that can reach the web tier over SSH, then web tier vm becomes a jump box to app/db. |
| Inbound | `GatewayManager` (Azure service tag) | AppGateway subnet | 65200–65535 | This is Azure's own control-plane traffic for health probes and management of the Application Gateway v2 SKU. Without it, the gateway itself fails to provision or function correctly — this isn't application traffic, it's a hard platform requirement. |

Every rule above ends in an explicit deny for anything not covered, there are no "allow all internal traffic" shortcuts anywhere in this design.

---

## 2.3 Public access mechanism

**Application Gateway (WAF_v2 SKU)** is the chosen mechanism for exposing the web tier, rather than a direct public IP on the web VM or a Layer-4 Load Balancer. A public IP directly on the VM was rejected outright, since that reintroduces exactly the kind of unmediated internet exposure this redesign exists to eliminate. A Standard Load Balancer was considered as a cheaper alternative, but it operates at Layer 4 and has no visibility into HTTP traffic itself, it cannot inspect or block malicious request patterns. Application Gateway operates at Layer 7 and, with the WAF_v2 tier specifically, adds a Web Application Firewall (OWASP managed rule set) in front of the web tier, giving RouteWell a concrete answer to "what stops the next incident" rather than relying solely on network segmentation. This directly satisfies the compliance requirement that only the minimum necessary path exists into the environment: the web VM itself holds no public IP at all, and every request is inspected before it ever reaches application code.

---

## 2.4 Architecture diagram


See [`docs/architecture-route.png`](docs/architecture-route.png), embedded in the root [`README.md`](../README.md), with the underlying Eraser diagram-as-code included alongside it. The diagram shows the VNet boundary, each subnet with its CIDR range, the direction of allowed traffic between tiers, and the Application Gateway sitting as the sole public entry point.

---

## Note on build divergence

- **VNet address space**: the deployed VNet uses `10.123.0.0/16` rather than the `10.10.0.0/16` range used in this worksheet's examples. This is a naming difference only — the sizing logic and ratios above apply identically regardless of which `/16` block the subnets are carved from.
- **App subnet resize**: initially deployed as a `/28`, sized against an earlier, smaller host-count assumption made before this worksheet was finalized against the official packet numbers.
- **Current state**: resized to `/26` (`10.123.2.0/26`) to actually satisfy the 20-host today / 40-host in 6-months target justified above. The build now matches this worksheet.