#!/bin/bash

# """
# Relies on envsubst which is part of gettext
# To run locally please use a pre-built container which includes this as a dependency
# PWD should be in the scripts directory of the pipeline-templates repo locally checked out
# docker run -it -v $(pwd):/usr/test amidostacks/ci-k8s:latest /bin/bash
# $ ./yaml-templating.sh base_file_path out_file_path (optional)
# """
base_template="$1"
file_out="$2"

# :param string: base_yaml path
# :param string: out_yaml path
# :return integer - exit code
function do_templating() {
  local base_yaml="$1"
  local out_yaml="$2"
  # simple_sub=$(envsubst -i $base_yaml -o $out_yaml -no-unset -no-empty)
  envsubst -i $base_yaml -o $out_yaml -no-unset -no-empty
  echo $?
}

if [ -z "$file_out" ]; then
  echo """
Out not supplied - defaulting to stripping base_ from base yaml.
Ensure you are following conventions and prepend you base yaml definition with base_.
E.g.: base_app-deploy.yml ==> app-deploy.yml
  """
  out_template="${base_template//"base_"}"
  rm -f $out_template
  echo "generated output path for the templated file: $out_template"
else
  # remove template-in if exists
  rm -f "$file_out"
  out_template="$file_out"
  echo "supplied output path for the templated file: $out_template"
fi

echo "base yaml: $base_template"
echo "out_template yaml: $out_template"

ret_val="$(do_templating $base_template $out_template)"
cat $out_template
exit $ret_val
