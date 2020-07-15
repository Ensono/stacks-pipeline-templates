#!/bin/bash

# """
# To run locally please use a pre-built container which includes this as a dependency
# PWD should be in the scripts directory of the pipeline-templates repo locally checked out
# docker run -it -v $(pwd):/usr/test amidostacks/ci-k8s:latest /bin/bash
# $ ./yaml-templating.sh base_file_path out_file_path (optional)
# """
# show_output=

while getopts ":i:o:a:s" opt; do
  case $opt in
    i)
      base_template="$OPTARG"
      ;;
    o)
      file_out="$OPTARG"
      ;;
    a)
      additional_envsubst_args=$OPTARG
      ;;
    s)
      show_output=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

envsubst_args="$additional_envsubst_args:-\"\""
# :param string: base_yaml path
# :param string: out_yaml path
# :return integer - exit code
function do_templating() {
  local base_yaml="$1"
  local out_yaml="$2"
  # simple_sub=$(envsubst -i $base_yaml -o $out_yaml -no-unset -no-empty)
  envsubst -i $base_yaml -o $out_yaml -no-unset ${additional_envsubst_args[@]}
  echo $?
}

if [ -z "$file_out" ]; then
  default_template_out="""
Out not supplied - defaulting to stripping base_ from base yaml.
Ensure you are following conventions and prepend you base yaml definition with base_.
E.g.: base_app-deploy.yml ==> app-deploy.yml
  """
  out_template="${base_template//"base_"}"
  rm -f $out_template
  file_msg_out="generated output path for the templated file: $out_template"
else
  # remove template-in if exists
  rm -f "$file_out"
  out_template="$file_out"
  user_supplied_out="supplied output path for the templated file: $out_template"
fi

ret_val="$(do_templating $base_template $out_template)"

if [[ $show_output ]]; then
  echo "base yaml: $base_template"
  echo "out_template yaml: $out_template"
  echo "$default_template_out"
  echo "$file_msg_out"
  echo "$user_supplied_out"
  cat $out_template
fi

exit $ret_val
