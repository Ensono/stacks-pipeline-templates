Param(
	[Parameter(Mandatory = $true)]
	[string]
	$DeploymentName,

	[Parameter(Mandatory = $true)]
	[string]
	$DeploymentNamespace,

	[Parameter(Mandatory = $true)]
	[string]
	$ChartName,

	[Parameter(Mandatory = $true)]
	[string]
	$ChartVersion,

	[Parameter(Mandatory = $true)]
	[string]
	$ConfigFile
)

helm upgrade --install `
	$DeploymentName `
	$ChartName `
	--version $ChartVersion `
	--create-namespace `
	--namespace $DeploymentNamespace `
	-f $ConfigFile
