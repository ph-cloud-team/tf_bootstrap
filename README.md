# tf_bootstrap

## 1. Overview

The `tf_bootstrap` repository provisions the **Tier-0 platform control plane**
required to enable a fully governed, policy-enforced Terraform and cloud platform.

This repository establishes the **trust boundary** for the entire platform and
must be executed **once** prior to any environment, module, or application deployment.

---

## 2. Purpose

This repository exists to create the **minimum foundational resources** required
before enforcement mechanisms (CI/CD policies, module contracts, drift detection)
can operate.

Specifically, it bootstraps:

- Terraform remote state infrastructure
- Platform root encryption authority
- Centralized IP address management foundation

---

## 3. Bootstrap Exception

This repository operates under a formally approved **Bootstrap Exception**.

### Characteristics

- Scope-limited (Tier-0 resources only)
- One-time execution
- Fully auditable
- Strongly change-controlled
- Terminates immediately after completion

Once bootstrap is complete, **all future infrastructure must be provisioned
via governed Terraform modules and CI/CD pipelines**.

---

## 4. Resources Created

### 4.1 Terraform Control Plane

- S3 bucket for Terraform remote state
- DynamoDB table for state locking
- Versioning enabled for state history and recovery
- TLS-only access enforced
- SSE-KMS encryption enforced
- Bucket ownership controls enforced

### 4.2 Platform Root Encryption

- One customer-managed AWS KMS CMK
- Used for:
  - Terraform state encryption
  - Future EKS secrets encryption
  - Future logging and audit data encryption

This key represents the **root encryption authority** for the platform.

### 4.3 IPAM Foundation

- AWS IPAM instance
- Private IPAM scope (implicit)

> **No IPAM pools are created here.**  
> All IPAM pools are created later via governed Terraform modules.

---

## 5. Configuration & Variable Management

### 5.1 Variable Source of Truth

All Terraform input variables for this repository are supplied **exclusively**
via **GitLab CI/CD protected variables**.

Variables are **not**:
- Hardcoded in Terraform
- Stored in `.tfvars` files
- Committed to Git

This ensures centralized control, auditability, and prevention of unauthorized changes.

### 5.2 Required CI/CD Variables

The following variables **must** be defined as **Protected CI/CD Variables**:

| Variable Name | Description |
|--------------|-------------|
| `TF_VAR_region` | AWS region for bootstrap resources | us-east-1
| `TF_VAR_name_prefix` | Enterprise platform naming prefix | midhtech
| `TF_VAR_tf_state_bucket_name` | Deterministic S3 bucket name for Terraform state | tfstate-midhtech-platform
| `TF_VAR_dynamodb_table_name` | DynamoDB table name for Terraform state locking | terraform-locks

These values are set once and changed only through formal change approval.

---

## 6. Terraform State Handling (Bootstrap-Specific)

### 6.1 Local State by Design

This repository **intentionally uses local Terraform state**.

This is required because the repository provisions the **remote backend itself**
(S3 + DynamoDB + KMS), creating an unavoidable circular dependency.

### 6.2 State as Audit Evidence

Terraform state generated during bootstrap execution is:

- Captured as a **GitLab CI job artifact**
- Stored with immutable pipeline metadata
- Access-restricted to platform administrators
- Retained for a defined period as **audit evidence**

The bootstrap state is **never reused operationally** and **never referenced**
by other Terraform repositories.

---

## 7. Execution Model

- Executed via GitLab CI/CD only
- Manual apply restricted to the `main` branch
- All pipeline actions are logged and auditable
- Not used for day-to-day Terraform operations

This repository is executed only during:
- Initial platform bootstrap
- Explicitly approved platform re-initialization

---

## 8. Controlled Teardown (Break-Glass Only)

Destruction of bootstrap resources is **explicitly prohibited** during normal operations.

### 8.1 Break-Glass Destroy Capability

A controlled destroy capability exists solely for:

- Platform decommissioning
- Disaster recovery testing
- Approved teardown scenarios

This capability requires **all** of the following:

- Manual pipeline execution
- Execution on the `main` branch
- Explicit enablement via CI variable
- A documented change ticket identifier

### 8.2 Required Destroy Variables

| Variable | Purpose |
|--------|--------|
| `ALLOW_BOOTSTRAP_DESTROY=true` | Explicit break-glass authorization |
| `CHANGE_TICKET_ID` | Approved change / decommission ticket |

Without these variables, teardown **cannot execute**.

This design enforces separation of duties, intent validation, and audit traceability.

---

## 9. Explicitly Prohibited

The following must **never** be created in this repository:

- VPCs or subnets
- Gateways (IGW, NAT, TGW)
- EKS clusters
- Application resources
- Helm charts or ArgoCD
- Environment-specific infrastructure
- Reusable Terraform modules

Any of the above constitutes a **governance violation**.

---

## 10. Post-Bootstrap Enforcement

After successful execution:

1. Terraform remote backend is mandatory everywhere
2. Policy-as-Code enforcement is enabled
3. Terraform modules become mandatory
4. Manual infrastructure changes are prohibited
5. Environment provisioning begins via `tf-live` repositories

At this point, the **Bootstrap Exception is formally closed**.

---

## 11. Governance Alignment

This repository aligns with:

- Enterprise Cloud & Platform Compliance
- Terraform Module Design Standards
- CI/CD Reference Architecture
- Policy-as-Code Specification
- Audit Evidence & Logging Standard
- Incident & Change Management Standards

---

## 12. Audit Statement

> “The platform uses a formally approved, tightly scoped bootstrap exception to
> establish the Terraform control plane required for policy enforcement.
> The exception is limited to foundational resources, operates under strict
> change control, and terminates once enforcement mechanisms are active.”

This statement aligns with **HIPAA**, **SOC 2**, and **NIST 800-53** expectations.

---
 
## 13. Ownership & Change Control

- Owned by the **Cloud Platform / Infrastructure Team**
- Changes require architectural and security review
- Not intended for ongoing development or iteration
