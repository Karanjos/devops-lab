# terraform/ (Phase 4, extended in Phase 7)

Target cloud: Google Cloud (GCP).

Planned layout:

```
terraform/
├── modules/{network,registry,vm,gke}/
└── envs/dev/{main.tf,variables.tf,outputs.tf,backend.tf,terraform.tfvars.example}
```
State lives in a versioned GCS bucket (`gcs` backend). See `docs/00-roadmap.md`, Phase 4.
Never commit `*.tfstate`, real `*.tfvars`, or service-account key files (all in `.gitignore`).
