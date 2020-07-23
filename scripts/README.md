The scripts in this directory can be used between Azure DevOps and Jenkins to reduce code duplication between Pipeline platforms.

There are some best practices to follow when creating scripts:
  1. Always use the shebang for the shell, e.g. `#!/bin/bash`
  2. Name the files `.bash` for bash scripts, _not_ `.sh`
  3. Always set `set -exo pipefail`
  4. Required passed parameters should come first, optional parameters come after:
      * Always preface the variable sections with `# Required` and `# Optional` respectively
      * Variables should always be checked in the shell script and required variables
      should always fail the script if not provided, optional ones should set a default
      value
  5. Use hard tabs `\t` for indentation of all shell files.
