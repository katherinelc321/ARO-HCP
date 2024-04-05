package api

// Copyright (c) Microsoft Corporation.
// Licensed under the Apache License 2.0.

import (
	"net"
	"net/url"

	configv1 "github.com/openshift/api/config/v1"

	"github.com/Azure/ARO-HCP/internal/api/arm"
	"github.com/Azure/ARO-HCP/internal/api/json"
)

// HCPOpenShiftCluster represents an ARO HCP OpenShift cluster resource.
type HCPOpenShiftCluster struct {
	arm.TrackedResource
	Properties HCPOpenShiftClusterProperties `json:"properties,omitempty"`
}

// HCPOpenShiftClusterProperties represents the property bag of a HCPOpenShiftCluster resource.
type HCPOpenShiftClusterProperties struct {
	ProvisioningState arm.ProvisioningState `json:"provisioningState,omitempty" visibility:"read"`
	Spec              ClusterSpec           `json:"spec,omitempty"              visibility:"read,create,update"`
}

// ClusterSpec represents a high level cluster configuration.
type ClusterSpec struct {
	Version                       VersionProfile            `json:"version,omitempty"                       visibility:"read,create,update"`
	DNS                           DNSProfile                `json:"dns,omitempty"                           visibility:"read,create,update"`
	Network                       NetworkProfile            `json:"network,omitempty"                       visibility:"read,create"`
	Console                       ConsoleProfile            `json:"console,omitempty"                       visibility:"read"`
	API                           APIProfile                `json:"api,omitempty"                           visibility:"read,create"`
	FIPS                          bool                      `json:"fips,omitempty"                          visibility:"read,create"`
	EtcdEncryption                bool                      `json:"etcdEncryption,omitempty"                visibility:"read,create"`
	DisableUserWorkloadMonitoring bool                      `json:"disableUserWorkloadMonitoring,omitempty" visibility:"read,create,update"`
	Proxy                         ProxyProfile              `json:"proxy,omitempty"                         visibility:"read,create,update"`
	Platform                      PlatformProfile           `json:"platform,omitempty"                      visibility:"read,create"`
	IssuerURL                     url.URL                   `json:"issuerUrl,omitempty"                     visibility:"read"`
	ExternalAuth                  ExternalAuthConfigProfile `json:"externalAuth,omitempty"                  visibility:"read,create"`
	Ingress                       []*IngressProfile         `json:"ingressProfile,omitempty"                visibility:"read,create"`
}

// VersionProfile represents the cluster control plane version.
type VersionProfile struct {
	ID                string   `json:"id,omitempty"                visibility:"read,create,update"`
	ChannelGroup      string   `json:"channelGroup,omitempty"      visibility:"read,create"`
	AvailableUpgrades []string `json:"availableUpgrades,omitempty" visibility:"read"`
}

// DNSProfile represents the DNS configuration of the cluster.
type DNSProfile struct {
	BaseDomain       string `json:"baseDomain,omitempty"       visibility:"read"`
	BaseDomainPrefix string `json:"baseDomainPrefix,omitempty" visibility:"read,create"`
}

// NetworkProfile represents a cluster network configuration.
// Visibility for the entire struct is "read,create".
type NetworkProfile struct {
	NetworkType NetworkType `json:"networkType,omitempty"`
	PodCIDR     json.IPNet  `json:"podCidr,omitempty"`
	ServiceCIDR json.IPNet  `json:"serviceCidr,omitempty"`
	MachineCIDR json.IPNet  `json:"machineCidr,omitempty"`
	HostPrefix  int32       `json:"hostPrefix,omitempty"`
}

// ConsoleProfile represents a cluster web console configuration.
// Visibility for the entire struct is "read".
type ConsoleProfile struct {
	URL url.URL `json:"url,omitempty"`
}

// APIProfile represents a cluster API server configuration.
type APIProfile struct {
	URL        url.URL    `json:"url,omitempty"        visibility:"read"`
	IP         net.IP     `json:"ip,omitempty"         visibility:"read"`
	Visibility Visibility `json:"visibility,omitempty" visibility:"read,create"`
}

// ProxyProfile represents the cluster proxy configuration.
// Visibility for the entire struct is "read,create,update".
type ProxyProfile struct {
	HTTPProxy  string `json:"httpProxy,omitempty"`
	HTTPSProxy string `json:"httpsProxy,omitempty"`
	NoProxy    string `json:"noProxy,omitempty"`
	TrustedCA  string `json:"trustedCa,omitempty"`
}

// PlatformProfile represents the Azure platform configuration.
// Visibility for the entire struct is "read,create".
type PlatformProfile struct {
	ManagedResourceGroup string       `json:"managedResourceGroup,omitempty"`
	SubnetID             string       `json:"subnetId,omitempty"`
	OutboundType         OutboundType `json:"outboundType,omitempty"`
	PreconfiguredNSGs    bool         `json:"preconfiguredNsgs,omitempty"`
	EtcdEncryptionSetID  string       `json:"etcdEncryptionSetId,omitempty"`
}

// ExternalAuthConfigProfile represents the external authentication configuration.
type ExternalAuthConfigProfile struct {
	Enabled       bool                     `json:"enabled,omitempty"       visibility:"read,create"`
	ExternalAuths []*configv1.OIDCProvider `json:"externalAuths,omitempty" visibility:"read"`
}

// IngressProfile represents a cluster ingress configuration.
type IngressProfile struct {
	IP         net.IP     `json:"ip,omitempty"         visibility:"read"`
	URL        url.URL    `json:"url,omitempty"        visibility:"read"`
	Visibility Visibility `json:"visibility,omitempty" visibility:"read,create"`
}

// Creates an HCPOpenShiftCluster with any non-zero default values.
func NewDefaultHCPOpenShiftCluster() *HCPOpenShiftCluster {
	return &HCPOpenShiftCluster{
		Properties: HCPOpenShiftClusterProperties{
			Spec: ClusterSpec{
				Network: NetworkProfile{
					NetworkType: NetworkTypeOVNKubernetes,
					HostPrefix:  23,
				},
			},
		},
	}
}
