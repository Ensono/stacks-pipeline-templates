# Stacks-Pipeline-Templates

## Intro

This templates are provided as a base standard process for deploying stacks infrastructure, see `stacks-infrastructure` and `stacks-dotnet` pipeline files under the `./build/AzDevOps/` folders for their specific usage.

## Configuration

### GitHub

Ensure you have a service connection set up to GitHub from your AzureDevOps tenant, then include the following snippet in your build pipeline:

```yml
resources:
  repositories:
  - repository: templates
    type: github
    name: amido/stacks-pipeline-templates
    ref: YYY # Optional line for specific tag/branch/etc.
    endpoint: XXX # Created when you set up the connection to GitHub from Azure DevOps
```

### Azure Repos

The equivalent for Azure Repos (should you clone this repository elsewhere) is:

```yml
resources:
  repositories:
  - repository: templates
    type: git
    name: PROJECT/REPOSITORY
    ref: YYY # Optional line for specific tag/branch/etc.
```

## Usage

To include a step from this repository in your pipeline, refer to them using the following syntax:

```yml

      - template: azDevOps/azure/templates/steps/build-validate-terraform.yml@templates
        parameters:
          terraform_artefact_name: terraform
          terraform_filepath: '$(Build.SourcesDirectory)/deploy/terraform/azure'
```

### Jobs vs Steps

There are two folders in the AzDevOps folder, one for `steps` and one for `jobs`. Please feel free to add as many steps as you feel neccesary to the steps folder, but do not modify existing jobs as they may be consumed by others.

### Contributing

If you are interested in contributing to this repository, first open an issue to discuss the problems, possible solutions and design decisions.
Pull Request without an issue and a design decision will likely be rejected.

For more details, see [CONTRIBUTING.md](CONTRIBUTING.md)

TODO:
- Find a better way to manage this!
