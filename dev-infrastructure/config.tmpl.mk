REGION ?= {{ .region }}
SVC_RESOURCEGROUP ?= {{ .svc.rg }}
MGMT_RESOURCEGROUP ?= {{ .mgmt.rg }}
REGIONAL_RESOURCEGROUP ?= {{ .regionRG }}
SVC_KV_RESOURCEGROUP ?= {{ .serviceKeyVault.rg }}
SVC_KV_NAME ?= {{ .serviceKeyVault.name }}
GLOBAL_RESOURCEGROUP ?= {{ .global.rg }}
GLOBAL_REGION ?= {{ .global.region }}
IMAGE_SYNC_RESOURCEGROUP ?= {{ .imageSync.rg }}
IMAGE_SYNC_ENVIRONMENT ?= {{ .imageSync.environmentName }}
ARO_HCP_IMAGE_ACR ?= {{ .svcAcrName }}
AKS_NAME ?= {{ .aksName }}
CS_PG_NAME ?= {{ .clusterService.postgres.name }}
CS_MI_NAME ?= {{ .clusterService.managedIdentityName }}
CS_NS_NAME ?= {{ .clusterService.k8s.namespace }}
CS_SA_NAME ?= {{ .clusterService.k8s.serviceAccountName }}
MAESTRO_PG_NAME ?= {{ .maestro.postgres.name }}
OIDC_STORAGE_ACCOUNT ?= {{ .oidcStorageAccountName }}
CX_KV_NAME ?= {{ .cxKeyVault.name }}
MSI_KV_NAME ?= {{ .msiKeyVault.name }}
MGMT_KV_NAME ?= {{ .mgmtKeyVault.name }}

ISTIO_TARGET_VERSION ?= {{ .svc.istio.targetVersion }}
ISTIOCTL_VERSION ?= {{ .svc.istio.istioctlVersion }}
ISTIO_TAG ?= {{ .svc.istio.tag }}

GRAFANA_NAME ?= {{ .monitoring.grafanaName }}
MONITOR_NAME ?= '{{ .monitoring.workspaceName }}'