#!/bin/bash

# This script updates the generated archetype pom with build plugin dependencies
# TODO add parameter variable for ossrh url and nexus staging verison

set -exo pipefail

cd target/generated-sources/archetype
File=pom.xml
if  ! grep -q distributionManagement "$File"; ##note the space after the string you are searching for
then
  sed -i -e "s/<scm>/<distributionManagement><snapshotRepository><id>ossrh<\/id><url>https:\/\/s01.oss.sonatype.org\/content\/repositories\/snapshots<\/url><\/snapshotRepository><repository><id>ossrh<\/id><url>https:\/\/s01.sonatype.org\/service\/local\/staging\/deploy\/maven2\/<\/url><\/repository><\/distributionManagement><scm>/g" "$File"
fi

sed -i -e "s/<build>/<build><plugins><plugin><groupId>org.sonatype.plugins<\/groupId><artifactId>nexus-staging-maven-plugin<\/artifactId><version>1.6.7<\/version><extensions>true<\/extensions><configuration><serverId>ossrh<\/serverId><nexusUrl>https:\/\/s01.oss.sonatype.org\/<\/nexusUrl><autoReleaseAfterClose>false<\/autoReleaseAfterClose><\/configuration><\/plugin><plugin><groupId>org.apache.maven.plugins<\/groupId><artifactId>maven-gpg-plugin<\/artifactId><version>1.5<\/version><executions><execution><id>sign-artifacts<\/id><phase>verify<\/phase><goals><goal>sign<\/goal><\/goals><\/execution><\/executions><\/plugin><\/plugins>/g" "$File"
