# Architecture Appendix — Web SaaS multi-tenant

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template. Ordering and numbering can be adjusted to fit the doc's flow.

## §2.1 Multi-Tenancy Model

State the model clearly:

- **Pool vs silo:** [pool — one DB, tenant_id column, RLS] or [silo — one DB per tenant]. Justify briefly.
- **Routing:** [path-based (`app.com/org-slug/...`)] or [subdomain-based (`org.app.com/...`)] or [single-domain with tenant in token]. Mention how the tenant is resolved on each request.
- **Credential ownership:** which third-party API keys are platform-owned (shared) vs tenant-owned (stored per tenant)?
- **Super admin pattern:** how does an internal user view/edit across tenants? (impersonation flow, admin role with cross-tenant scope, separate admin app?)

## §2.2 Data Model

[Notation: types are illustrative; real implementation includes indexes, RLS, enums.]

### Entity groups

For each group (e.g. *Organizations & Users*, *Subscriptions & Billing*, *Domain entities X/Y/Z*):

```
[schema sketch — TypeScript-style or SQL-style; ORM-specific shorthand is fine]

Table: organizations
  id          uuid pk
  slug        text unique
  name        text
  created_at  timestamptz default now()

Table: users
  id              uuid pk
  email           text unique
  ...

Table: organization_members
  organization_id uuid fk → organizations
  user_id         uuid fk → users
  role            enum('admin','member','viewer')
  ...
```

For each entity: key columns, relations, indexes, any JSONB fields with type hints.

### Schema conventions to establish

Pick conventions and state them. These become repo-wide rules:

- Timestamps: `timestamptz` always, no naive `timestamp`.
- IDs: `uuid` with `defaultRandom()` (or equivalent ULID).
- Enums: database enums for stable values, `text` + check for fluid ones.
- FK onDelete: `cascade` when child can't exist without parent; `restrict` otherwise.
- JSONB fields: typed in the ORM, documented in text.
- Indexes: declared on the schema table, named explicitly.
- Tenant column: `organization_id` (or domain-specific name) on every multi-tenant entity, with composite indexes that lead with it.

## §2.3 Data Isolation (RLS / Auth Policy Strategy)

How tenant isolation is enforced. Document the actual policy strategy.

- **Primary defense:** row-level security policies on every multi-tenant table. Helper function pattern (e.g., `current_organization_id()`) for the check.
- **Common policy template:**
  ```sql
  CREATE POLICY tenant_isolation ON [table]
    FOR ALL
    USING (organization_id = current_organization_id());
  ```
- **Service-role bypass:** when used (background jobs, admin tools), enumerate the call sites and the compensating controls (server-only code, validated `organization_id` from a trusted source, audit logging).
- **Edge cases:** cross-tenant entities (e.g. global lookup tables), audit logs that span tenants, super-admin impersonation flow.
- **Validation:** how is the policy tested? Integration tests with two tenants confirming isolation; CI gates that fail on tables missing RLS.

## §2.4 Auth and Session Model

- **Identity provider:** [managed (Clerk, Supabase Auth, Auth0, WorkOS) or self-built]
- **Token shape:** what's in the session/JWT, where the tenant context lives
- **Tenant resolution:** at every protected request, how does the server determine the active tenant?
- **Multi-tenant user case:** if a user belongs to multiple tenants, how is the active tenant chosen? (URL slug, last selected, picker on login)
