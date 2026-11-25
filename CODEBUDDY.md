# CODEBUDDY.md This file provides guidance to CodeBuddy when working with code in this repository.

## Project Overview

Oracle APEX migration project for Toyota. The target environment is **Oracle Autonomous Database (ADB)** in `ap-tokyo-1` (service `toyota_high`), managed via the ADMIN user and an APEX workspace whose first provisioned schema is inspected through the `apex_*` dictionary views. The repository is currently in its early bootstrap stage: it contains only the Autonomous DB wallet and connectivity-check tooling, so most commands and structure described here concern database access rather than application code.

## Database Access (critical)

- Connection is via TCPS using the wallet in `wallet/` (TNS aliases: `toyota_high`, `toyota_medium`, `toyota_low`, `toyota_tp`, `toyota_tpurgent` in `wallet/tnsnames.ora`). Use `toyota_high` for admin/DDL work; use `toyota_medium`/`toyota_low` for app-level queries.
- The wallet SSL certificates expire **2031-09-21**; the wallet must be re-downloaded before then (see `wallet/README`).
- The DB password is supplied through the `DB_PASSWORD` environment variable. Never hard-code or store credentials in project files.
- Python connectivity check (verifies wallet works and lists APEX release, workspaces, and applications): requires `python-oracledb` (`pip install oracledb`) and `DB_PASSWORD` set, then run `python tmp_apex_check.py`. Output goes to stdout; the past results file is `tmp_apex_out.txt`.
- Local SQLcl CLI is the preferred tool for schema inspection, SQL execution, metadata generation, and APEX workflows:
  `C:\Users\robin wu\.codebuddycn\extensions\oracle.sql-developer-26.3.1\dbtools\sqlcl\bin\sql.exe`
  Example: `sql.exe -cloudconfig <wallet zip> admin@toyota_high` (SQLcl handles the wallet itself; no need to unzip).
- Web-based Database Actions / APEX builder: `https://A0XB9UIC34JRUL8-TOYOTA.adb.ap-tokyo-1.oraclecloudapps.com/ords/apex`.

## Network Constraint

github.com is not directly reachable from this machine (port 443 blocked). Cloning or fetching from GitHub requires a mirror/proxy — `ghproxy.net` and `gitclone.com` have been verified working, e.g. `https://ghproxy.net/https://github.com/<user>/<repo>.git` or `https://gitclone.com/github.com/<user>/<repo>.git`.

## Conventions

- `wallet/` contains live security material (SSO, PKCS#12, JKS). Do not commit, print, or transmit its contents beyond what connection code needs; treat `.sso`/`.p12`/`.pem`/`.jks` as secrets.
- `tmp_*` prefixed files at the repo root are throwaway diagnostic scripts/outputs; safe to regenerate or delete once superseded.

## Database Tooling
Use Local SQLcl CLI for Oracle Database-related tasks.
SQLcl executable: C:\Users\robin wu\.codebuddycn\extensions\oracle.sql-developer-26.3.1\dbtools\sqlcl\bin\sql.exe
Before performing database-related tasks:
- Verify that SQLcl is available.
- Use SQLcl for schema inspection, SQL execution, metadata generation, and APEX development workflows.
- Do not store passwords or connection credentials in project files.