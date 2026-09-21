# terraform/ (Phase 4, extended in Phase 7)

Planned layout:

```
terraform/
├── modules/{network,acr,vm,aks}/
└── envs/dev/{main.tf,variables.tf,outputs.tf,backend.tf,terraform.tfvars.example}
```
See `docs/00-roadmap.md`, Phase 4. Never commit `*.tfstate` or real `*.tfvars` (already in `.gitignore`).
