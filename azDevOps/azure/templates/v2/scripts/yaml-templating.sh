#!/bin/bash

base_template="$1"
file_out="$2"
templated_out_yaml=""

# remove temp if exists
rm -f temp.yml

# :param string: base_yaml path
# :param string: out_yaml path
# :return string - out path of the templated yaml file
function do_templating() {
  local base_yaml="$1"
  local out_yaml="$2"
  ( echo "cat <<EOF >$out_yaml";
    cat "$base_yaml";
    echo "EOF";
  ) >temp.yml
  . temp.yml
  rm -f temp.yml
  # returns a string
  echo $out_yaml
  return 0
}

if [ -z "$file_out" ]; then
  echo """
  out not supplied - defaulting to stripping base_ from base yaml
  Ensure you are following conventions and prepend you base yaml with `base_`
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

cat $ret_val
exit 0;
