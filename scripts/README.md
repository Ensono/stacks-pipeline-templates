Pipeline Scripts
================

The scripts in this directory can be used between Azure DevOps and Jenkins to reduce code duplication between Pipeline platforms.

There are some best practices to follow when creating scripts:
  1. Always use the shebang for the shell in use, e.g. `#!/bin/bash`
  2. Name the files `.bash` for bash scripts, _not_ `.sh`
  3. Always set `set -exo pipefail`
  4. Use hard tabs `\t` for indentation of all shell files
  5. Begin the script with defining an `OPTIONS` variable, e.g. `OPTIONS=":a:b:c:d:e:f:g:V:W:X:Y:Z:"`
     and handle options as described in the [Options](#options) section
  6. Next define a `usage()` function which should `set +x`, define a usage string, echo the usage string,
     and then `set -x`. See the [Usage](#usage) example below
  7. The script should respond to `--help` and show the usage defined in `6.` above. See [Help](#help)
  8. All variables should be quoted where possible and use the syntax `${...}`
  9. Boolean flags should always accept an argument and check for lowercase `true` as truthy.
     An example helper snippet is below in [Booleans](#booleans)
  10. If you need to add additional arguments to scripts in a single variable, please refer to the
      [Multiple Arguments in a Single Variable](#multiple-arguments-in-a-single-variable) section.
      **Never** build up arguments as a string as it's prone to failure.

If in doubt, check some of the scripts in this directory to see how things have been done before.

## Options

Options handling should be done with `getopts` built-in if possible. This is the most platform agnostic
option, but only handles single letter inputs.

Required arguments should be **lowercase** starting with `-a`, and optional
arguments should be **uppercase** starting with `-Z`.

An example options handling is the following:
```bash
while getopts "${OPTIONS}" option
do
	case "${option}" in
		a  ) SONAR_HOST_URL="${OPTARG}";;
		b  ) SONAR_PROJECT_NAME="${OPTARG}";;
		c  ) SONAR_PROJECT_KEY="${OPTARG}";;
		d  ) SONAR_TOKEN="${OPTARG}";;
		e  ) SONAR_ORGANISATION="${OPTARG}";;
		f  ) BUILD_NUMBER="${OPTARG}";;
		g  ) SOURCE_BRANCH_REF="${OPTARG}";;

		# Optional
		V  ) SONAR_COMMAND="${OPTARG}";;
		W  ) PULL_REQUEST_REPO="${OPTARG}";;
		Y  ) TARGET_BRANCH_REF="${OPTARG}";;
		X  ) PULL_REQUEST_PROVIDER="${OPTARG}";;
		Z  ) PULL_REQUEST_NUMBER="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done
```

Following the Options handling should then come handling of Required inputs, exiting with failure
on any required arguments not specified, with increasing exit codes from `1`, e.g.
```bash
if [ -z "${SONAR_HOST_URL}" ]; then
	echo '-a: Missing Sonar Host URL'
	exit 1
fi

if [ -z "${SONAR_PROJECT_NAME}" ]; then
	echo '-b: Missing Sonar Project Name'
	exit 2
fi

...
```

Optional parameters should then follow, setting a default value if necessary:
```bash
if [ -z "${PULL_REQUEST_NUMBER}" ]; then
	PULL_REQUEST_NUMBER=""
fi
```

## Usage

An example usage function is:
```bash
usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a url	The URL to the Sonar(cloud) instance
		  -b name	The Sonar Project Name
		  -c key	The Sonar Project Key
		  -d token	The Sonar Token
		  -e org	The Sonar Organisation Name
		  -f build	The build identifier/number, e.g. '0.0.213-merge' or '1'
		  -g branch	The Source Branch Name, e.g. 'feature/something-awesome'

		Optional Arguments:
		  -V command	The Sonar Command to run. Default: sonar-scanner
		  -W repo	The Remote Repository Name for the PR
		  -X provider	The Pull Request Provider, currently supports: Github.
		  -Y branch	The Target Branch Name. Empty default.
		  -Z pr		The number of the PR. Empty default.

		Options '-W', '-X', '-Y', and '-Z' must all be provided together.
		USAGE_STRING
	)

	echo "${USAGE}"

	set -x
}
```

## Help

After declaring a `usage()` function, this function should be present as is:
```bash
# Detect `--help`, show usage and exit
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done
```

This will detect someone adding `--help` as a parameter and will print the usage and exit.

## Booleans

Booleans don't exist in most shells, such as `bash`. Therefore boolean arguments should be handled
as a string, lowercased and checked against the string `true`. The below code is the template
(including the comment) for how boolean checks should be done.
```bash
# Boolean `true` workaround
DOCKER_TAG_LATEST="$(tr '[:upper:]' '[:lower:]' <<< "${DOCKER_TAG_LATEST}")"
if [ "${DOCKER_TAG_LATEST}" == 'true' ]; then
```
For shells which don't support heredoc, a pipe may be used instead:
```bash
# Boolean `true` workaround
DOCKER_TAG_LATEST="$(echo "${DOCKER_TAG_LATEST}" | tr '[:upper:]' '[:lower:]')"
if [ "${DOCKER_TAG_LATEST}" == 'true' ]; then
```

## Multiple Arguments in a Single Variable

Sometimes you may need to build complex argument strings into a single variable. As there are
plenty of pitfalls with shell and arguments through runtime variables it's worth noting how we should
handle the need to pass multiple arguments to a function through a single variable.

A good article on this is: [I'm trying to put a command in a variable, but the complex cases always fail!](http://mywiki.wooledge.org/BashFAQ/050#I.27m_constructing_a_command_based_on_information_that_is_only_known_at_run_time)

The preferred method is using arrays if the shell supports them, e.g.
```bash
# Bash 3.1 / ksh93
args=("my arguments" "$go" here)
if ((foo)); then args+=(--foo); fi    # and so on
somecommand "${args[@]}"
```

An empty array can be declared as follows:
```bash
declare -a EXTRA_SONAR_ARGUMENTS
```

Basically, if the shell supports arrays, use those, else use the posix example shown in the article above.
