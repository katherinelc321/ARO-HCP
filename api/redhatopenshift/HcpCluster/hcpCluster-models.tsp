import "@typespec/rest";
import "@typespec/http";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";

using TypeSpec.Rest;
using TypeSpec.Http;
using Azure.Core;
using Azure.ResourceManager;

namespace Microsoft.RedHatOpenshift;

/*
 * ===================================
 *   HCP cluster core resources
 * ===================================
 */

/** HCP cluster resource */
model HcpOpenShiftClusterResource
  is TrackedResource<HcpOpenShiftClusterProperties> {
  /** Name of HCP cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("hcpOpenShiftClusterName") // sets the alternative name for the name propery
  @path
  @segment("hcpOpenShiftClusters")
  name: string;

  ...ManagedServiceIdentity;
}

// The NodePool needs to be TrackedResource for the following reasons:
// - allow tags to be in place, which allows billing to use tags, important for workers
// - allow nodepool to be tracked in the portal
// - deleted when resource group is deleted
// - allow cascade delete
// more: https://armwiki.azurewebsites.net/rp_onboarding/tracked_vs_proxy_resources.html
@parentResource(HcpOpenShiftClusterResource)
model HcpOpenShiftClusterNodePoolResource
  is TrackedResource<NodePoolProperties> {
  /** Name of HCP cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("nodePoolName")
  @path
  @segment("nodePools")
  name: string;
}

/** HCP cluster properties */
model HcpOpenShiftClusterProperties {
  /** The status of the last operation. */
  @visibility("read")
  provisioningState?: ProvisioningState;

  /** The cluster resouce specification. */
  @visibility("create", "update")
  spec: ClusterSpec;
}

/** The cluster resource specification */
model ClusterSpec {
  /** Version of the control plane components */
  @visibility("create", "update")
  version: VersionProfile;

  /** Cluster DNS configuration */
  dns?: DnsProfile;

  /** Cluster network configuration */
  @visibility("create")
  network?: NetworkProfile;

  /** Shows the cluster web console information */
  @visibility("read")
  console: ConsoleProfile;

  /** Shows the cluster API server profile */
  @visibility("read")
  api: ApiProfile;

  /** Enable FIPS mode for the cluster
   * When set to true, `etcdEncryption` must be set to true
   */
  @visibility("create")
  fips?: boolean = false;

  /** Enables customer ETCD encryption, set during creation
   * When set to true, `platform.etcdEncryptionSetId` must be set
   */
  @visibility("create")
  etcdEncryption?: boolean = false;

  /** Disable user workload monitoring */
  @visibility("create", "update")
  disableUserWorkloadMonitoring?: boolean = false;

  /** Openshift cluster proxy configuration */
  @visibility("create", "update")
  proxy?: ProxyProfile;

  /** Azure platform configuration */
  @visibility("create")
  platform: PlatformProfile;

  /** URL for the OIDC provider to be used for authentication
   * to authenticate against user Azure cloud account
   */
  @visibility("read")
  issuerUrl: string;

  /** Configuration to override the openshift-oauth-apiserver inside cluster
   *  This changes user login into the cluster to external provider
   */
  @visibility("create")
  externalAuth?: ExternalAuthConfigProfile;

  /** Configures the cluster ingresses */
  @visibility("create")
  @OpenAPI.extension("x-ms-identifiers", ["ip", "url", "visibility"])
  ingress?: IngressProfile[];
}

/** The resource provisioning state. */
@lroStatus
union ProvisioningState {
  string,
  ResourceProvisioningState,
}

/** Versions represents an OpenShift version. */
model VersionProfile {
  /** ID is the unique identifier of the version. */
  @visibility("create", "update")
  id: string;

  /** ChannelGroup is the name of the set to which this version belongs. Each version belongs to only a single set. */
  @visibility("create")
  channelGroup: string;

  /** AvailableUpgrades is a list of version names the current version can be upgraded to. */
  @visibility("read")
  availableUpgrades: string[];
}

/** DNS contains the DNS settings of the cluster */
model DnsProfile {
  /** BaseDomain is the base DNS domain of the cluster. */
  @visibility("read")
  baseDomain: string;

  /**  BaseDomainPrefix is the unique name of the cluster representing the OpenShift's cluster name.
   * BaseDomainPrefix is the name that will appear in the cluster's DNS, provisioned cloud providers resources
   * */
  @visibility("create")
  baseDomainPrefix: string;
}

/** Network profile of the cluster */
model NetworkProfile {
  /** The main controller responsible for rendering the core networking components */
  @visibility("create")
  networkType?: NetworkType = NetworkType.OVNKubernetes;

  /** The CIDR of the pod IP addresses
   * example: 10.128.0.0/14
   */
  @visibility("create")
  podCidr: string;

  /** The CIDR block for assigned service IPs,
   * example: 172.30.0.0/16
   */
  @visibility("create")
  serviceCidr: string;

  /** from which to assign machine IP addresses,
   * example: 10.0.0.0/16
   */
  @visibility("create")
  machineCidr: string;

  /** Network host prefix which is defaulted to 23 if not specified. */
  @visibility("create")
  hostPrefix?: int32 = 23;
}

/** The cluster network type */
union NetworkType {
  string,

  /** THE OVN network plugin for the OpenShift cluster */
  OVNKubernetes: "OVNKubernetes",

  /** Other network plugins */
  Other: "Other",
}

/** Configuration of the cluster web console */
model ConsoleProfile {
  /** The cluster web console URL endpoint */
  @visibility("read")
  url: string;
}

/** Information about the API of a cluster. */
model ApiProfile {
  /** URL endpoint for the API server */
  @visibility("read")
  url: string;

  /** ip address of the API server */
  @visibility("read")
  ip: string;

  /** should the API server be accessible from the internet */
  @visibility("create")
  visibility: Visibility;
}

/** The visibility of the API server */
union Visibility {
  string,

  /** The API server is visible from the internet. */
  public: "public",

  /** The API server is not visible from the internet. */
  private: "private",
}

/** OpenShift cluster proxy configuration */
model ProxyProfile {
  /** http proxy config */
  httpProxy?: string;

  /** https proxy config */
  httpsProxy?: string;

  /** no proxy config */
  noProxy?: string;

  /** The trusted CA for the proxy */
  trustedCa?: string;
}

/** Azure specific configuration */
model PlatformProfile {
  /** Resource group to put cluster resources */
  managedResourceGroup: string;

  /** ResourceId for the subnet used by the control plane */
  subnetId: string;

  /** The core outgoing configuration */
  outboundType?: OutboundType = OutboundType.loadBalancer;

  /** Specifies whether subnets are pre-attached with an NSG */
  preconfiguredNsgs: boolean;

  /** The id of the disk encryption set to be used for etcd.
   * Configure this when `etcdEncryption` is set to true
   * Is used the https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview
   */
  etcdEncryptionSetId?: string;
}

/** The outbound routing strategy used to provide your cluster egress to the internet. */
union OutboundType {
  string,

  /** The loadbalancer configuration */
  loadBalancer: "loadBalancer",
}

/*
 * =======================================
 *   End HCP cluster core resources
 * =======================================
 */

/*
 * =======================================
 *  ExternalAuth resources
 * =======================================
 */

/** External authentication configuration profile */
model ExternalAuthConfigProfile {
  /** This can be set during cluster creation only to ensure there is no openshift-oauth-apiserver in cluster */
  @visibility("create")
  enabled?: boolean = false;

  /** This can only be set as a day-2 resource on a separate endpoint to provide a self-managed auth service */
  @visibility("read")
  @OpenAPI.extension("x-ms-identifiers", ["issuer", "clients", "claim"])
  externalAuths: ExternalAuthProfile[];
}

/** External authentication profile */
model ExternalAuthProfile {
  /** Token Issuer profile */
  issuer: TokenIssuerProfile;

  /** External auth clients */
  clients: ExternalAuthClientProfile[];

  /** External auth claim */
  claim: ExternalAuthClaimProfile;
}

/** Token issuer profile */
model TokenIssuerProfile {
  /** The URL of the token issuer */
  url: string;

  /** The audience of the token issuer */
  audiences: string[];

  /** The issuer of the token */
  ca: string;
}

/** External auth client profile */
model ExternalAuthClientProfile {
  /** External auth client component */
  component: ExternalAuthClientComponentProfile;

  /** external auth client id */
  id: string;

  /** external auth client secret */
  @secret
  secret: string;

  /** external auth client scopes */
  extraScopes: string[];
}

/** External auth component profile */
model ExternalAuthClientComponentProfile {
  /** The name of the external auth client */
  name: string;

  /** The namespace of the external auth client */
  authClientNamespace: string;
}

/** External auth claim profile */
model ExternalAuthClaimProfile {
  /** The claim mappings */
  mappings: TokenClaimMappingsProfile;

  /** The claim validation rules */
  @OpenAPI.extension("x-ms-identifiers", ["claim", "requiredValue"])
  validationRules: TokenClaimValidationRuleProfile[];
}

/** External auth claim mappings profile */
model TokenClaimMappingsProfile {
  /** The claim mappings username */
  username: ClaimProfile;

  /** The claim mappings groups */
  groups: ClaimProfile;
}

/** External auth claim profile */
model ClaimProfile {
  /** Claim */
  claim: string;

  /** Prefix */
  prefix: string;

  /** Prefix policy */
  prefixPolicy: string;
}

/** External auth claim validation rule */
model TokenClaimValidationRuleProfile {
  /** Claim */
  claim: string;

  /** Required value */
  requiredValue: string;
}

/*
 * =======================================
 *  End ExternalAuth resources
 * =======================================
 */

/*
 * =======================================
 *  Ingress resources
 * =======================================
 */

/** Configuration of the cluster ingress */
model IngressProfile {
  /** The IP for the ingress */
  @visibility("read")
  ip: string;

  /** The ingress url */
  @visibility("read")
  url: string;

  /** The visibility of the ingress
   * determines if the ingress is visible from the internet
   */
  @visibility("create")
  visibility: Visibility;
}

/*
 * =======================================
 *  End Ingress resources
 * =======================================
 */

/*
 * =======================================
 *  NodePool resources
 * =======================================
 */

/** Represents the node pool properties */
model NodePoolProperties {
  /** Provisioning state */
  @visibility("read")
  provisioningState?: ResourceProvisioningState;

  /** The node pool resource specification */
  spec: NodePoolSpec;
}

/** Worker node pool profile */
model NodePoolSpec {
  /** OpenShift version for the nodepool */
  @visibility("create", "update")
  version: VersionProfile;

  /** Azure node pool platform configuration */
  @visibility("create")
  platform: NodePoolPlatformProfile;

  /** The number of worker nodes, it cannot be used together with autoscaling */
  @visibility("create", "update")
  replicas?: int32;

  /** Autorepair */
  @visibility("create")
  autoRepair?: boolean = false;

  /** Representation of a autoscaling in a node pool. */
  autoScaling?: NodePoolAutoScaling;

  /** Labels for the nodes */
  @visibility("create", "update")
  labels?: string[];

  /** Taints for the nodes */
  @visibility("create", "update")
  taints?: string[];

  /*
   * The Tuned API is defined here:
   * - https://github.com/openshift/cluster-node-tuning-operator/blob/2c76314fb3cc8f12aef4a0dcd67ddc3677d5b54f/pkg/apis/tuned/v1/tuned_types.go
   *
   * The PerformanceProfile API is defined here:
   * - https://github.com/openshift/cluster-node-tuning-operator/tree/b41042d42d4ba5bb2e99960248cf1d6ae4935018/pkg/apis/performanceprofile/v2
   */
  /** Tuning configs, TODO provide meaningful explanation
   * TuningConfig is a list of references to ConfigMaps containing serialized
   * Tuned resources to define the tuning configuration to be applied to
   * nodes in the NodePool.
   * Each ConfigMap must have a single key named "tuned" whose value is the
   * JSON or YAML of a serialized Tuned or PerformanceProfile.
   */
  tuningConfigs?: string[];
}

/** Azure node pool platform configuration */
model NodePoolPlatformProfile {
  /** The resourceId for the subnet used by the workers */
  subnetId: string;

  /** The VM size according to the documentation:
   * - https://learn.microsoft.com/en-us/azure/virtual-machines/sizes */
  vmSize: string;

  /** The OS disk size in GB */
  #suppress "@azure-tools/typespec-azure-core/casing-style" "The field needs to be indicate size in GB not in Gb"
  diskSizeGB?: int32;

  /** The type of the disc storage account
   * - https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types
   */
  diskStorageAccountType?: string;

  /** The availability zone for the node pool.
   * Please read the documentation to see which regions support availability zones
   * - https://learn.microsoft.com/en-us/azure/availability-zones/az-overview
   */
  availabilityZone?: string;

  /** Whether the worker machines should be encrypted at host */
  encryptionAtHost?: boolean;

  /** Disk Encryption Set ID that will be used for ecnryption the Nodes disks
   * - https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption-overview
   * - https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption
   */
  discEncryptionSetId?: string;

  /** Is the disk ephemeral */
  ephemeralOsDisk?: boolean;
}

/** Node pool autoscaling */
model NodePoolAutoScaling {
  /** The minimum number of nodes in the node pool */
  @minValue(0)
  min: int32;

  /** The maximum number of nodes in the node pool */
  @minValue(0)
  max: int32;
}

/*
 * =======================================
 * End NodePool resources
 * =======================================
 */

/*
 * =======================================
 *   HCP cluster credentials
 * =======================================
 */

/** HCP cluster credentials */
model HcpOpenShiftClusterCredentials {
  /** kubeadmin user name */
  @visibility("read")
  kubeadminUsername: string;

  /** kube admin password */
  @visibility("read")
  @secret
  kubeadminPassword: string;
}

/** HCP cluster admin kubeconfig */
model HcpOpenShiftClusterKubeconfig {
  /** The kubeconfig file */
  @visibility("read")
  @secret
  kubeconfig: string;
}

/*
 * =======================================
 *   End HCP cluster credentials
 * =======================================
 */
