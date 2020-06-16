# Scripts: CI/CD Pipelines for Test

## Scripts

### [upload-azstorage-blob.sh](./upload-azstorage-blob.sh)

Input: Azure Blob Storage Destination and authentication
Output: Uploads 1 or more files (or whole folder) of assets to Blob.

Example usage:

Uploads this README from the current directory.

#### Upload a folder or directory

`./upload-azstorage-blob.sh amido-stacks-rg-uks-dev amidostacksuksdev testresults /Users/estherlloyd/Documents/Github/stacks/stacks-webapp-template/packages/scaffolding-cli/templates/test/cypress-typescript-coreui/results/`

#### Upload a specific file(s) using patterns

The pattern used for globbing files or blobs in the source. The supported patterns are '*', '?', '[seq]', and '[!seq]'. For more information, please refer to [fnmatch docs](https://docs.python.org/3.7/library/fnmatch.html).

`./upload-azstorage-blob.sh amido-stacks-rg-uks-dev amidostacksuksdev testresults /Users/estherlloyd/Documents/Github/stacks/stacks-webapp-template/packages/scaffolding-cli/templates/test/cypress-typescript-coreui/results/ *report.html`

## FAQ

Q: Why is `Please run 'az login' to setup account.` occurring?
A: If you haven't authenticated, then you need to login in to be able to resolve the Account Key. Please run `az login` or authenticate using an alternative method. See [azure-cli sign-in](https://docs.microsoft.com/en-gb/cli/azure/get-started-with-azure-cli?view=azure-cli-latest#sign-in) for more.