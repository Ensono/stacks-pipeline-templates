#!/bin/bash
# from SO: https://stackoverflow.com/a/54261882/317605 (by https://stackoverflow.com/users/8207842/dols3m)
function prompt_for_multiselect {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")

    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    key_input()         {
      local key
      IFS= read -rsn1 key 2>/dev/null >&2
      if [[ $key = ""      ]]; then echo enter; fi;
      if [[ $key = $'\x20' ]]; then echo space; fi;
      if [[ $key = $'\x1b' ]]; then
        read -rsn2 key
        if [[ $key = [A ]]; then echo up;    fi;
        if [[ $key = [B ]]; then echo down;  fi;
      fi
    }

    toggle_option()    {
      local arr_name=$1
      eval "local arr=(\"\${${arr_name}[@]}\")"
      local option=$2
      if [[ ${arr[option]} == true ]]; then
        arr[option]=
      else
        arr[option]=true
      fi
      eval $arr_name='("${arr[@]}")'
    }

    local retval=$1
    local options
    local defaults

    IFS=';' read -r -a options <<< "$2"
    if [[ -z $3 ]]; then
      defaults=()
    else
      IFS=';' read -r -a defaults <<< "$3"
    fi
    local selected=()

    for ((i=0; i<${#options[@]}; i++)); do
      selected+=("${defaults[i]:-false}")
      printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="   [ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="   [x]"
            fi

            cursor_to $(($startrow + $idx))
            if [ $idx -eq $active ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            space)  toggle_option selected $active;;
            enter)  break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $retval='("${selected[@]}")'
}

function delete_from_array {

    local retval=$1
    delete="$2"
    array=("${@:3}")

    for target in "${delete[@]}"; do
      for i in "${!array[@]}"; do
        if [[ ${array[i]} = $target ]]; then
          unset 'array[i]'
        fi
      done
    done

    eval $retval='("${array[@]}")'

}

#####################
#####################

declare -a ALL_SPRING_PROFILES=(aws azure cosmosdb dynamodb servicebus kafka sqs)

if [[ "$1" == "--interactive" ]]; then

  printf "\n"

  #####################

  unset OPTIONS_STRING OPTIONS_SELECTED_STRING

  printf "1. Please select the Cloud required:\n\n"

  OPTIONS_VALUES=("azure" "aws")
  OPTIONS_LABELS=("Azure Cloud" "AWS Cloud")
  OPTIONS_SELECTED=("true" "")

  for i in "${!OPTIONS_VALUES[@]}"; do
    OPTIONS_STRING+="${OPTIONS_VALUES[$i]} (${OPTIONS_LABELS[$i]});"
    OPTIONS_SELECTED_STRING+="${OPTIONS_SELECTED[$i]};"
  done

  prompt_for_multiselect SELECTED "$OPTIONS_STRING" "$OPTIONS_SELECTED_STRING"

  for i in "${!SELECTED[@]}"; do
    if [ "${SELECTED[$i]}" == "true" ]; then
      CHECKED+=("${OPTIONS_VALUES[$i]}")
      delete_from_array ALL_SPRING_PROFILES "${OPTIONS_VALUES[$i]}" "${ALL_SPRING_PROFILES[@]}"
    fi
  done
  # echo "${CHECKED[@]}"

  #####################

  unset OPTIONS_STRING OPTIONS_SELECTED_STRING

  printf "2. Please select the Persistence required:\n\n"

  OPTIONS_VALUES=("cosmosdb" "dynamodb")
  OPTIONS_LABELS=("CosmosDB" "DynamoDB")
  OPTIONS_SELECTED=("true" "")

  for i in "${!OPTIONS_VALUES[@]}"; do
    OPTIONS_STRING+="${OPTIONS_VALUES[$i]} (${OPTIONS_LABELS[$i]});"
    OPTIONS_SELECTED_STRING+="${OPTIONS_SELECTED[$i]};"
  done

  prompt_for_multiselect SELECTED "$OPTIONS_STRING" "$OPTIONS_SELECTED_STRING"

  for i in "${!SELECTED[@]}"; do
    if [ "${SELECTED[$i]}" == "true" ]; then
      CHECKED+=("${OPTIONS_VALUES[$i]}")
      delete_from_array ALL_SPRING_PROFILES "${OPTIONS_VALUES[$i]}" "${ALL_SPRING_PROFILES[@]}"
    fi
  done

  #####################

  unset OPTIONS_STRING OPTIONS_SELECTED_STRING

  printf "3. Please select the Message Handler required:\n\n"

  OPTIONS_VALUES=("servicebus" "kafka" "sqs")
  OPTIONS_LABELS=("Azure ServiceBus" "AWS Kafka" "AWS SQS")
  OPTIONS_SELECTED=("true" "" "")

  for i in "${!OPTIONS_VALUES[@]}"; do
    OPTIONS_STRING+="${OPTIONS_VALUES[$i]} (${OPTIONS_LABELS[$i]});"
    OPTIONS_SELECTED_STRING+="${OPTIONS_SELECTED[$i]};"
  done

  prompt_for_multiselect SELECTED "$OPTIONS_STRING" "$OPTIONS_SELECTED_STRING"

  for i in "${!SELECTED[@]}"; do
    if [ "${SELECTED[$i]}" == "true" ]; then
      CHECKED+=("${OPTIONS_VALUES[$i]}")
      delete_from_array ALL_SPRING_PROFILES "${OPTIONS_VALUES[$i]}" "${ALL_SPRING_PROFILES[@]}"
    fi
  done

else

  printf "\nUsing build.properties inputs.\n\n"

  # IFS=$'\n' read -d '' -r BUILD_PROPERTIES_LINES < build.properties

  BUILD_PROPERTIES_LINES=()
  while IFS= read -r line; do
     BUILD_PROPERTIES_LINES+=("$line")
  done < build.properties

  for i in "${BUILD_PROPERTIES_LINES[@]}";
  do

    SUB="#"
    if [[ "${i}" =~ .*"$SUB".* ]]; then
      : # Skip as it's hashed
    else
      BUILD_OPTION=$(echo "${i}" | sed 's/=//g' | tr "[:upper:]" "[:lower:]")
      CHECKED+=("${BUILD_OPTION}")
      delete_from_array ALL_SPRING_PROFILES "${BUILD_OPTION}" "${ALL_SPRING_PROFILES[@]}"
    fi

  done

fi

#####################

printf "You have selected these options for your project:\n\n"
for i in "${CHECKED[@]}";
do
   printf "   * %s\n" "${i}"
done

#printf "\nPress ENTER to accept or CTRL-C to quit"
#read -r

#####################
ls -al pom.xml
ls -al src/main/resources/application.yml
cp pom.xml pom.template.xml

printf ""
echo "DELETE THESE..."
for i in "${ALL_SPRING_PROFILES[@]}";
do
   echo "$i"
   echo "----A-----------------"
   xmlstarlet edit -N ns='http://maven.apache.org/POM/4.0.0' \
      --delete ".//ns:project/ns:properties/ns:${i}.profile.name" \
      --delete ".//ns:project/ns:profiles/ns:profile[ns:id=\"${i}\"]" \
      pom.template.xml > pom.template.xml.work

   mv pom.template.xml.work pom.template.xml
   cp src/main/resources/application.yml src/main/resources/application.yml.tmp
   sed  -i 's/- "@${i}.profile.name@"/- ${i}/g'  src/main/resources/application.yml.tmp > src/main/resources/application.yml && rm -f src/main/resources/application.yml.tmp

   rm -f "src/main/resources/application-${i}.yml"

done
cat  src/main/resources/application.yml

echo "KEEP THESE..."
for i in "${CHECKED[@]}";
do
   echo "$i"
   echo "---------B------------"

   xmlstarlet edit -N ns='http://maven.apache.org/POM/4.0.0' \
      --move ".//ns:project/ns:profiles/ns:profile[ns:id=\"${i}\"]/ns:dependencies/*" ".//ns:project/ns:dependencies" \
      pom.template.xml > pom.template.xml.work

   mv pom.template.xml.work pom.template.xml

   xmlstarlet edit -N ns='http://maven.apache.org/POM/4.0.0' \
      --delete ".//ns:project/ns:properties/ns:${i}.profile.name" \
      --delete ".//ns:project/ns:profiles/ns:profile[ns:id=\"${i}\"]" \
      pom.template.xml > pom.template.xml.work

   mv pom.template.xml.work pom.template.xml
   cp src/main/resources/application.yml src/main/resources/application.yml.tmp
   sed  -i 's/- "@${i}.profile.name@"/- ${i}/g'  src/main/resources/application.yml.tmp > src/main/resources/application.yml && rm -f src/main/resources/application.yml.tmp

done
cat  src/main/resources/application.yml

cp pom.template.xml pom.xml
ls src/main/resources

###########################
 cat pom.xml
 echo "--------"
 cat src/main/resources/application.yml
##############################
cd . || exit 1

export MANIFOLD_SRC_LOCATION=.

rm build.properties

for i in "${CHECKED[@]}";
do
   echo "${i}=" |tr "[:lower:]" "[:upper:]" >> build.properties
done

echo "Test clean compile "
cd src/main/java || exit 1

mvn -f ../../../pom.xml clean compile

cd ../../../.. || exit 1

#####################
echo "Test copy  "
cd java || exit 1
mv src/main/java src/main/java.SAV

#####################
echo "Test test compile "

export MANIFOLD_SRC_LOCATION=.

rm build.properties

for i in "${CHECKED[@]}";
do
   echo "${i}=" |tr "[:lower:]" "[:upper:]" >> build.properties
done

cd src/test/java || exit 1

mvn -f ../../../pom.xml test-compile

cd ../../../.. || exit 1

#####################
echo "Test copy back java "
cd java || exit 1
rm -rf src/main/java

mv src/main/java.SAV src/main/java

#####################
echo "Test format  "

mvn -DskipTests=true com.coveo:fmt-maven-plugin:format

cd .. || exit 1

#####################
echo "Test 1 back pom file  "

xmlstarlet edit -N ns='http://maven.apache.org/POM/4.0.0' \
      --delete ".//ns:project/ns:properties/ns:manifold-version" \
      --delete ".//ns:project/ns:build/ns:plugins/ns:plugin[ns:artifactId=\"maven-compiler-plugin\"]/ns:configuration/ns:compilerArgs" \
      --delete ".//ns:project/ns:build/ns:plugins/ns:plugin[ns:artifactId=\"maven-compiler-plugin\"]/ns:configuration/ns:annotationProcessorPaths/ns:path[ns:groupId=\"systems.manifold\"]" \
      pom.xml > pom.template.xml.work

mv pom.template.xml.work pom.xml

rm -f pom.template.xml
rm -f build.properties

#####################
unset MANIFOLD_SRC_LOCATION
