package helmtestutil

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/assert"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
	batchv1beta1 "k8s.io/api/batch/v1beta1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1beta1"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// KubernetesResources parsed from a multi-document template string
type KubernetesResources struct {
	ClusterRoles           map[string]rbacv1.ClusterRole
	ClusterRoleBindings    map[string]rbacv1.ClusterRoleBinding
	ConfigMaps             map[string]corev1.ConfigMap
	CronJobs               map[string]batchv1beta1.CronJob
	DaemonSets             map[string]appsv1.DaemonSet
	Deployments            map[string]appsv1.Deployment
	Jobs                   map[string]batchv1.Job
	PersistentVolumeClaims map[string]corev1.PersistentVolumeClaim
	Pods                   map[string]corev1.Pod
	Pdbs                   map[string]policyv1.PodDisruptionBudget
	Psps                   map[string]policyv1.PodSecurityPolicy
	Roles                  map[string]rbacv1.Role
	RoleBindings           map[string]rbacv1.RoleBinding
	Secrets                map[string]corev1.Secret
	Services               map[string]corev1.Service
	ServiceAccounts        map[string]corev1.ServiceAccount
	Statefulsets           map[string]appsv1.StatefulSet
}

// NewKubernetesResources creates a new instance of KubernetesResources by parsing the helmOutput and
// loading the data into the correct types resulting in some (limited) type checks on the data as well
func NewKubernetesResources(t *testing.T, helmOutput string) KubernetesResources {
	clusterRoles := make(map[string]rbacv1.ClusterRole)
	clusterRoleBindings := make(map[string]rbacv1.ClusterRoleBinding)
	configMaps := make(map[string]corev1.ConfigMap)
	cronJobs := make(map[string]batchv1beta1.CronJob)
	daemonSets := make(map[string]appsv1.DaemonSet)
	deployments := make(map[string]appsv1.Deployment)
	jobs := make(map[string]batchv1.Job)
	persistentVolumeClaims := make(map[string]corev1.PersistentVolumeClaim)
	pods := make(map[string]corev1.Pod)
	pdbs := make(map[string]policyv1.PodDisruptionBudget)
	psps := make(map[string]policyv1.PodSecurityPolicy)
	roles := make(map[string]rbacv1.Role)
	roleBindings := make(map[string]rbacv1.RoleBinding)
	secrets := make(map[string]corev1.Secret)
	services := make(map[string]corev1.Service)
	serviceAccounts := make(map[string]corev1.ServiceAccount)
	statefulsets := make(map[string]appsv1.StatefulSet)

	// The K8S unmarshalling only can do a single document
	// So we split them first by the yaml document separator
	separateFiles := strings.Split(helmOutput, "\n---\n")

	for _, v := range separateFiles {
		var metadata metav1.TypeMeta
		err := helm.UnmarshalK8SYamlE(t, v, &metadata)
		assert.NoError(t, err)
		switch metadata.Kind {
		case "ClusterRole":
			var resource rbacv1.ClusterRole
			helm.UnmarshalK8SYaml(t, v, &resource)
			clusterRoles[resource.Name] = resource
		case "ClusterRoleBinding":
			var resource rbacv1.ClusterRoleBinding
			helm.UnmarshalK8SYaml(t, v, &resource)
			clusterRoleBindings[resource.Name] = resource
		case "ConfigMap":
			var configMap corev1.ConfigMap
			helm.UnmarshalK8SYaml(t, v, &configMap)
			configMaps[configMap.Name] = configMap
		case "CronJob":
			var resource batchv1beta1.CronJob
			e := helm.UnmarshalK8SYamlE(t, v, &resource)
			assert.NoError(t, e, "CronJob failed to parse: "+v)
			cronJobs[resource.Name] = resource
		case "DaemonSet":
			var resource appsv1.DaemonSet
			e := helm.UnmarshalK8SYamlE(t, v, &resource)
			assert.NoError(t, e, "DaemonSet failed to parse: "+v)
			daemonSets[resource.Name] = resource
		case "Deployment":
			var resource appsv1.Deployment
			e := helm.UnmarshalK8SYamlE(t, v, &resource)
			assert.NoError(t, e, "Deployment failed to parse: "+v)
			deployments[resource.Name] = resource
		case "Job":
			var resource batchv1.Job
			helm.UnmarshalK8SYaml(t, v, &resource)
			jobs[resource.Name] = resource
		case "List":
			// Skip for now
		case "PersistentVolumeClaim":
			var resource corev1.PersistentVolumeClaim
			e := helm.UnmarshalK8SYamlE(t, v, &resource)
			assert.NoError(t, e, "PersistentVolumeClaim failed to parse: "+v)
			persistentVolumeClaims[resource.Name] = resource
		case "Pod":
			var resource corev1.Pod
			helm.UnmarshalK8SYaml(t, v, &resource)
			pods[resource.Name] = resource
		case "PodDisruptionBudget":
			var resource policyv1.PodDisruptionBudget
			helm.UnmarshalK8SYaml(t, v, &resource)
			pdbs[resource.Name] = resource
		case "PodSecurityPolicy":
			var resource policyv1.PodSecurityPolicy
			helm.UnmarshalK8SYaml(t, v, &resource)
			psps[resource.Name] = resource
		case "Role":
			var resource rbacv1.Role
			helm.UnmarshalK8SYaml(t, v, &resource)
			roles[resource.Name] = resource
		case "RoleBinding":
			var resource rbacv1.RoleBinding
			helm.UnmarshalK8SYaml(t, v, &resource)
			roleBindings[resource.Name] = resource
		case "Secret":
			var resource corev1.Secret
			helm.UnmarshalK8SYaml(t, v, &resource)
			secrets[resource.Name] = resource
		case "Service":
			var resource corev1.Service
			helm.UnmarshalK8SYaml(t, v, &resource)
			services[resource.Name] = resource
		case "ServiceAccount":
			var resource corev1.ServiceAccount
			helm.UnmarshalK8SYaml(t, v, &resource)
			serviceAccounts[resource.Name] = resource
		case "StatefulSet":
			var resource appsv1.StatefulSet
			helm.UnmarshalK8SYaml(t, v, &resource)
			statefulsets[resource.Name] = resource
		default:
			if metadata.Kind != "" || metadata.APIVersion != "" {
				t.Errorf("Found unknown kind '%s/%s' in content\n%s\n This can be caused by an incorrect k8s resource type in the helm template or when using a custom resource type.", metadata.APIVersion, metadata.Kind, v)
			} else {
				t.Logf("Skipping empty resource: %s", v)
			}
		}
	}

	return KubernetesResources{
		ClusterRoles:           clusterRoles,
		ClusterRoleBindings:    clusterRoleBindings,
		ConfigMaps:             configMaps,
		DaemonSets:             daemonSets,
		Deployments:            deployments,
		CronJobs:               cronJobs,
		Jobs:                   jobs,
		PersistentVolumeClaims: persistentVolumeClaims,
		Pods:                   pods,
		Pdbs:                   pdbs,
		Roles:                  roles,
		RoleBindings:           roleBindings,
		Secrets:                secrets,
		Services:               services,
		ServiceAccounts:        serviceAccounts,
		Statefulsets:           statefulsets,
	}
}
