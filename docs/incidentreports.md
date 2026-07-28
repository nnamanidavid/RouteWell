# Incident Report

## Symptom

After all three tiers were deployed and the web page was reachable through the Application Gateway, the page loaded but displayed:

```
Couldn't load page: app tier responded with 500
```

This was observed directly in the browser. A follow-up check confirmed the app tier itself was reachable. Running `curl http://<app-private-ip>:8080/api/health` from the web VM returned a healthy `{"status":"ok","tier":"app"}` response, so the failure was isolated to whatever the `/api/visits` endpoint was doing beyond that basic health check.

## Investigation/debugging

1. **Checked the app tier's own process output first**, since the health endpoint had already ruled out a pure network/NSG problem between Web and App. The running `npm start` session on the App VM showed:
   ```
   DB query failed: password authentication failed for user "routewell"
   ```
   This ruled *in* an authentication problem specifically, and ruled *out* a network-layer or App→DB connectivity issue, the request was reaching Postgres and getting a response, just a rejection.

2. **Connected to the DB VM directly** and listed existing roles:
   ```bash
   sudo -u postgres psql -c "\du"
   ```
   This ruled out a simple typo'd password and instead confirmed the actual cause: the `routewell` role did not exist at all. Only the default `postgres` superuser was present.

3. **Traced this back to the deployment script.** `init.sql` was intended to create the database, the `routewell` role, and the `visits` table in a single run. Since only the role/database creation steps were missing entirely, the script had evidently failed on an early statement and silently skipped the rest, `psql` does not halt a session on every kind of statement error by default.

## Root cause

The `init.sql` setup script failed partway through execution without producing an obvious error, leaving the `routewell` database role never created, so every application-level query that authenticated as that role was rejected by Postgres.

## The Fix

The database, role, and table were rebuilt manually and incrementally, running each statement individually rather than re-running the full script blind, so each step's success could be confirmed before moving to the next:

```bash
sudo -u postgres psql -c "CREATE DATABASE routewell;"
sudo -u postgres psql -c "CREATE USER routewell WITH PASSWORD 'changeme';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE routewell TO routewell;"
sudo -u postgres psql -d routewell
```
followed by the `visits` table creation and its grants inside that session.

**Before:** `psql -h <db-ip> -U routewell -d routewell` → `password authentication failed for user "routewell"`

**After:** `psql -h <db-ip> -U routewell -d routewell -c "SELECT * FROM visits;"` → returns the `visits` row cleanly, and the web page displays the visit counter correctly on reload.

## Design reflection

The tiered network design itself made this failure *faster to diagnose*, even though the fault had nothing to do with networking: because NSG rules were already confirmed correct and Web→App connectivity had been separately verified via the health endpoint, the investigation could immediately rule out the network layer and focus on the database itself, rather than spending time re-checking NSGs, subnets, or routing that were, in fact, working exactly as designed. What the design did not account for was verifying that setup automation actually succeeded, the `init.sql` was treated as a run-and-forget step with no built-in confirmation that it had done what it claimed. If I were revising the design, I would add an explicit post-deployment validation step to the automation itself (for example, a follow-up query confirming the expected role and table exist, run automatically right after `init.sql`), rather than relying on a downstream 500 error and manual investigation to surface a setup failure that should have been caught the moment it happened.