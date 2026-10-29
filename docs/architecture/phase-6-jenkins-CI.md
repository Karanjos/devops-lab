# Phase 6 — Azure Jenkins CI

This starter `Jenkinsfile` covers CI only: checkout, backend verification/tests, frontend build, Docker image builds, Trivy scanning, and publishing to Azure Container Registry (ACR). It does not create Azure resources or deploy to AKS.

## Expected repository paths

- `backend/Dockerfile` and `backend/pom.xml`
- `frontend/Dockerfile` and `frontend/package.json` / `frontend/package-lock.json`
- `kafka/connect/Dockerfile`

JUnit reports are expected under `backend/target/surefire-reports/`.

## Before running

1. Put `Jenkinsfile` at the repository root and commit it.
2. Ensure Jenkins can run Docker commands and access `/var/run/docker.sock`.
3. Install Azure CLI on the Jenkins VM.
4. Assign a managed identity to the Jenkins VM and grant it permission to push to the target ACR. The required role depends on the registry's permission mode.
5. Create ACR separately using your existing Azure infrastructure workflow.
6. Configure a Jenkins Pipeline or Multibranch Pipeline for this repository.
7. Set the build parameter `ACR_NAME` to the registry resource name, e.g. `myregistry`, not `myregistry.azurecr.io`.
8. Optionally set `AZURE_SUBSCRIPTION_ID` if needed.

The publish stage uses `az login --identity`, so it assumes the VM's managed identity is configured. If you use a service principal instead, change the login stage to use Jenkins Credentials; do not commit secrets.

## Behavior

- Backend: `mvn -B verify` in `maven:3.9-eclipse-temurin-21`, with Surefire XML reports published when present.
- Frontend: `npm ci` and `npm run build` in `node:22-alpine`.
- Images: builds backend, frontend, and Kafka Connect images tagged with the short Git SHA.
- Security: Trivy fails the build on HIGH or CRITICAL findings that are not filtered out by `--ignore-unfixed`.
- Publish: pushes SHA-tagged images to ACR. Pull-request builds skip publishing.
- Does not deploy to AKS and does not publish a `latest` tag.

## Notes

- Trivy defaults to `aquasec/trivy:latest` for convenience. Pin a reviewed version or digest for reproducible/production use.
- Docker must be able to build images and the Jenkins host needs sufficient disk space.
- If the frontend build cannot write to the workspace, inspect workspace ownership and volume permissions rather than applying broad permissions.
- Configure the repository webhook or Jenkins SCM trigger separately.
