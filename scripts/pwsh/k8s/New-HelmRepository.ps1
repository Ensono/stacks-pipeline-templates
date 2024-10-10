Param(
	[Parameter(Mandatory = $true)]
	[String]
	$RepositoryName,

	[Parameter(Mandatory = $true)]
	[String]
	$RepositoryUrl
)

helm repo add $RepositoryName $RepositoryUrl
helm repo update
