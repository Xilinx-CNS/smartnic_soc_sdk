#!/bin/sh
PACKAGE_LIST=packages.list
SOURCES_DIR=sources

rm -f ${PACKAGE_LIST}
dpkg --get-selections | grep install | cut -f 1 | sed  's/:arm64//g' > ${PACKAGE_LIST}

rm -rf ${SOURCES_DIR}
mkdir -p ${SOURCES_DIR}

cd ${SOURCES_DIR}

while read -r sourcename
do
  apt -o APT::Sandbox::User=root --download-only source ${sourcename}
#  apt -o APT::Sandbox::User=root source ${sourcename}
done < "../${PACKAGE_LIST}"
