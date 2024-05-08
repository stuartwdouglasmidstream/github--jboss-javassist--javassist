#!/bin/sh
export MAVEN_HOME=/opt/maven/3.8.8
export ANT_HOME=/opt/ant/1.10.13
export TOOL_VERSION=1.10.13
export PROJECT_VERSION=3.28.0-GA
export JAVA_HOME=/lib/jvm/java-11
export ENFORCE_VERSION=

set -- "$@" -v 

#!/usr/bin/env bash
set -o verbose
set -eu
set -o pipefail
FILE="$JAVA_HOME/lib/security/cacerts"
if [ ! -f "$FILE" ]; then
    FILE="$JAVA_HOME/jre/lib/security/cacerts"
fi

if [ -f /root/project/tls/service-ca.crt/service-ca.crt ]; then
    keytool -import -alias jbs-cache-certificate -keystore "$FILE" -file /root/project/tls/service-ca.crt/service-ca.crt -storepass changeit -noprompt
fi



#!/usr/bin/env bash
set -o verbose
set -eu
set -o pipefail

cp -r -a  /original-content/* /root/project
cd /root/project/workspace

if [ -n "" ]
then
    cd 
fi

if [ ! -z ${JAVA_HOME+x} ]; then
    echo "JAVA_HOME:$JAVA_HOME"
    PATH="${JAVA_HOME}/bin:$PATH"
fi

if [ ! -z ${MAVEN_HOME+x} ]; then
    echo "MAVEN_HOME:$MAVEN_HOME"
    PATH="${MAVEN_HOME}/bin:$PATH"
fi

if [ ! -z ${GRADLE_HOME+x} ]; then
    echo "GRADLE_HOME:$GRADLE_HOME"
    PATH="${GRADLE_HOME}/bin:$PATH"
fi

if [ ! -z ${ANT_HOME+x} ]; then
    echo "ANT_HOME:$ANT_HOME"
    PATH="${ANT_HOME}/bin:$PATH"
fi

if [ ! -z ${SBT_DIST+x} ]; then
    echo "SBT_DIST:$SBT_DIST"
    PATH="${SBT_DIST}/bin:$PATH"
fi
echo "PATH:$PATH"

#fix this when we no longer need to run as root
export HOME=/root

mkdir -p /root/project/logs /root/project/packages /root/project/build-info



#This is replaced when the task is created by the golang code


#!/usr/bin/env bash

if [ ! -z ${JBS_DISABLE_CACHE+x} ]; then
    cat >"/root/software/settings"/settings.xml <<EOF
    <settings>
EOF
else
    cat >"/root/software/settings"/settings.xml <<EOF
    <settings>
      <mirrors>
        <mirror>
          <id>mirror.default</id>
          <url>${CACHE_URL}</url>
          <mirrorOf>*</mirrorOf>
        </mirror>
      </mirrors>
EOF
fi

cat >>"/root/software/settings"/settings.xml <<EOF
  <!-- Off by default, but allows a secondary Maven build to use results of prior (e.g. Gradle) deployment -->
  <profiles>
    <profile>
      <id>gradle</id>
      <activation>
        <property>
          <name>useJBSDeployed</name>
        </property>
      </activation>
      <repositories>
        <repository>
          <id>artifacts</id>
          <url>file:///root/project/artifacts</url>
          <releases>
            <enabled>true</enabled>
            <checksumPolicy>ignore</checksumPolicy>
          </releases>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>artifacts</id>
          <url>file:///root/project/artifacts</url>
          <releases>
            <enabled>true</enabled>
            <checksumPolicy>ignore</checksumPolicy>
          </releases>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
</settings>
EOF

#!/usr/bin/env bash

if [ ! -d "${ANT_HOME}" ]; then
    echo "Ant home directory not found at ${ANT_HOME}" >&2
    exit 1
fi

# XXX: It's possible that build.xml is not in the root directory
cat > ivysettings.xml << EOF
<ivysettings>
    <property name="cache-url" value="http://localhost:8080/v2/cache/rebuild-central/1620406872000/"/>
    <property name="default-pattern" value="[organisation]/[module]/[revision]/[module]-[revision](-[classifier]).[ext]"/>
    <property name="local-pattern" value="\${user.home}/.m2/repository/[organisation]/[module]/[revision]/[module]-[revision](-[classifier]).[ext]"/>
    <settings defaultResolver="defaultChain"/>
    <resolvers>
        <ibiblio name="default" root="\${cache-url}" pattern="\${default-pattern}" m2compatible="true"/>
        <filesystem name="local" m2compatible="true">
            <artifact pattern="\${local-pattern}"/>
            <ivy pattern="\${local-pattern}"/>
        </filesystem>
        <chain name="defaultChain">
            <resolver ref="local"/>
            <resolver ref="default"/>
        </chain>
    </resolvers>
</ivysettings>
EOF

if [ ! -d /root/project/source ]; then
    cp -r /root/project/workspace /root/project/source
fi
echo "Running $(which ant) with arguments: $@"
eval "ant $@" | tee /root/project/logs/ant.log





