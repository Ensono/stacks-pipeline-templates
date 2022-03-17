#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

cd target/generated-sources/archetype

sed -i -e "s/<build>/<build><plugins><plugin><groupId>org.sonatype.plugins<\/groupId><artifactId>nexus-staging-maven-plugin<\/artifactId><version>1.6.7<\/version><extensions>true<\/extensions><configuration><serverId>ossrh<\/serverId><nexusUrl>https:\/\/s01.oss.sonatype.org\/<\/nexusUrl><autoReleaseAfterClose>false<\/autoReleaseAfterClose><\/configuration><\/plugin><plugin><groupId>org.apache.maven.plugins<\/groupId><artifactId>maven-gpg-plugin<\/artifactId><version>1.5<\/version><executions><execution><id>sign-artifacts<\/id><phase>verify<\/phase><goals><goal>sign<\/goal><\/goals><\/execution><\/executions><\/plugin><\/plugins>/g" pom.xml
