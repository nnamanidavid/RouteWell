# RouteWell — Secure 3-Tier Azure Architecture

## Scenario

RouteWell ran its entire stack — frontend, backend, and database — inside a single flat network. A developer's laptop nearly exposed the production database to the internet. This project redesigns RouteWell's infrastructure from scratch: the website stays reachable from the internet, the database never is, only the minimum required ports are open, and the whole thing can be torn down and rebuilt on command.

## Architecture

```
Internet
   │
   ▼
Application Gateway (WAF_v2) ── public IP, subnet-appgw
   │  :80
   ▼
Web VM ── subnet-web (10.123.1.0/27)
   │  :8080
   ▼
App VM ── subnet-app (10.123.2.0/28)
   │  :5432
   ▼
DB VM ── subnet-db (10.123.3.0/28)
```

Traffic only ever moves one direction, one hop at a time. Nothing skips a tier, and nothing reaches the database subnet from outside the app tier. A NAT Gateway gives the app and db subnets outbound-only internet access (for patching, package installs) without ever exposing them to inbound traffic.

Full diagram: ![RouteWell architecture diagram](docs/architecture-route.png)

## Design decisions

### CIDR planning

Sized to actual host counts rather than defaulting to `/24` everywhere:

| Subnet | CIDR | Usable hosts | Why |
|---|---|---|---|
| AppGateway | `10.123.4.0/27` | 27 | App Gateway v2 SKUs need headroom to scale internal instances |
| Web | `10.123.1.0/27` | 27 | Matches the brief's own sizing example; room to scale to several web VMs |
| App | `10.123.2.0/28` | 11 | Internal only, fewer instances than web |
| DB | `10.123.3.0/28` | 11 | Only needs 2-3 realistically, but `/28` leaves room for a monitoring agent or replica without resizing later |

All four fit comfortably inside `10.123.0.0/16`, with most of the address space still unused for future growth.

### NSG rules

| Source | Destination | Port | Reason |
|---|---|---|---|
| Internet | AppGateway subnet | 80 | Entry point for all user traffic |
| GatewayManager | AppGateway subnet | 65200-65535 | Required by Azure for App Gateway v2's own health/management traffic |
| AppGateway subnet | Web subnet | 80 | Gateway forwards user requests to the web tier |
| Web subnet | App subnet | 8080 | Web tier proxies API calls to the app tier |
| App subnet | DB subnet | 5432 | Backend reads/writes data |
| *(scoped)* | *(each subnet)* | 22 | SSH, scoped to the subnet one tier up — never open to the internet |
| Any | Web / App / DB subnets | * | Explicit deny-all, below the specific allows — defense-in-depth on top of Azure's default behavior |

The database subnet only ever appears as a destination from the app subnet — never from web, never from the internet.

### Access method: Application Gateway (WAF_v2)

Considered three options:

- **Public IP directly on the VM** — cheapest, but the VM itself becomes the internet-facing surface, the opposite of what this redesign fixes.
- **Standard Load Balancer** — Layer 4, cheap, handles distribution and health checks, but no visibility into HTTP traffic itself.
- **Application Gateway (WAF_v2)** — Layer 7, includes a Web Application Firewall (OWASP rule set) in addition to load balancing.

Given the redesign exists *because* of a near-miss security incident, Application Gateway was chosen specifically for the WAF — it directly answers "what stops the next incident," which a plain Load Balancer doesn't.

## Tech stack

- **Infrastructure**: Terraform (`azurerm` provider) — chosen over the brief's suggested Bash script for idempotency and state tracking
- **Web tier**: nginx (static frontend + reverse proxy to the app tier)
- **App tier**: Node.js / Express
- **DB tier**: PostgreSQL

## Repo structure

```
routewell-app/
├── README.md
├── docs/
│   ├── architecture.md      # diagram + design rationale
│   ├── build.md              # manual Portal build + connectivity screenshots
│   ├── automation.md         # Terraform structure + apply output
│   └── troubleshooting.md    # the intentional-break writeup
├── terraform/
│   ├── provider.tf
│   ├── main.tf                # resource group, VNet, subnets
│   ├── nsg.tf
│   ├── nat.tf
│   ├── appgateway.tf
│   ├── vm.tf
│   └── outputs.tf
├── web/
│   ├── index.html
│   ├── nginx.conf             # production config (real private IPs)
│   └── nginx.local.conf       # Docker Compose local dev config
├── app/
│   ├── server.js
│   ├── package.json
│   └── .env.example
└── db/
    ├── init.sql               # full schema for a fresh Postgres instance
    └── schema.sql              # table-only, for Docker's auto-init
```

## Quick start

**Deploy the infrastructure:**
```bash
cd terraform
terraform init
terraform apply
```

**Deploy the app onto the VMs** — see [`docs/build.md`](docs/build.md) for the full manual walkthrough (DB → App → Web, in that order, using the private IPs from `terraform output`).

**Run it locally instead**, without touching Azure at all:
```bash
docker compose up --build
```
Then open `http://localhost:8080`.

## Connectivity tests

| Test | Result |
|---|---|
| Internet → Web (via App Gateway) | ✅ Page loads |
| Web → App | ✅ `curl` to app tier's `/api/health` succeeds |
| App → DB | ✅ Postgres query returns data |
| Internet → DB | ❌ Connection times out, as designed |
| Internet → Web VM directly (bypassing App Gateway) | ❌ Blocked — no public IP on the VM |

Screenshots for each: [`docs/build.md`](docs/build.md).

## Troubleshooting (the intentional break)

While deploying the app tier, every request returned a 500 error. Investigation traced it to a Postgres role that was never actually created — `init.sql` had failed partway through silently. Full writeup, including how it was diagnosed and fixed: [`docs/troubleshooting.md`](docs/troubleshooting.md).

## Lessons learned

Manual-first, then automate, turned out to matter in practice and not just on paper — the Postgres issue surfaced *because* the design was already proven manually, so debugging it meant checking one layer (the script), not fighting the network and the script at the same time. Terraform's stricter validation (every NSG rule needs all four address/port fields explicitly, no implicit `Any` like the Portal allows) caught security-relevant gaps that clicking through the Portal would have silently defaulted around. And locking down the web tier to zero public IP — clean on paper — meant deliberately building a temporary access path back in for legitimate admin work, a real tradeoff between security and operability that's easy to underestimate until you're the one locked out.