<!-- Creating managed indentity and assigning acrpush role  -->

az vm show --resource-group "COMMON_DEV-RESOURCE_GROUP" --name "dev-jenkins-vm01" --query identity.principalId --output tsv

az vm identity assign --resource-group "COMMON_DEV-RESOURCE_GROUP" --name "dev-jenkins-vm01"
   
ACR_ID=$(az acr show --name "acr2xpuaxu3" --resource-group "COMMON_DEV-RESOURCE_GROUP" --query id --output tsv)

/subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3

PRINCIPAL_ID=$(az vm show --resource-group "COMMON_DEV-RESOURCE_GROUP" --name "dev-jenkins-vm01" --query identity.principalId --output tsv)

b72694e8-a3d3-4419-a726-1c61c0efe167

az role assignment create --assignee-object-id "b72694e8-a3d3-4419-a726-1c61c0efe167" -assignee-principal-type ServicePrincipal --role "AcrPush" --scope "/subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3"

{
  "condition": null,
  "conditionVersion": null,
  "createdBy": null,
  "createdOn": "2026-10-29T18:02:29.445641+00:00",
  "delegatedManagedIdentityResourceId": null,
  "description": null,
  "id": "/subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3/providers/Microsoft.Authorization/roleAssignments/e75dadc3-ed0d-48b3-8a96-087d210631bb",
  "name": "e75dadc3-ed0d-48b3-8a96-087d210631bb",
  "principalId": "b72694e8-a3d3-4419-a726-1c61c0efe167",
  "principalType": "ServicePrincipal",
  "resourceGroup": "COMMON_DEV-RESOURCE_GROUP",
  "roleDefinitionId": "/subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec",
  "scope": "/subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3",
  "type": "Microsoft.Authorization/roleAssignments",
  "updatedBy": "cc4e5603-5d37-4801-8deb-2a03a15af9b8",
  "updatedOn": "2026-10-29T18:02:30.283647+00:00"
}

az role assignment list `
  --assignee b72694e8-a3d3-4419-a726-1c61c0efe167 `
  --scope /subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3 `
  --query "[].{Role:roleDefinitionName,Scope:scope}" `
  --output table
  
Role     Scope
-------  ---------------------------------------------------------------------------------------------------------------------------------------------------------
AcrPush  /subscriptions/114a8a22-8e28-4dfc-b100-4ba3410329b9/resourceGroups/COMMON_DEV-RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/acr2xpuaxu3