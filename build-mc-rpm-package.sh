#!/bin/bash

set -x

if [ -z "${MC_VERSION}" ]; then
  echo "Variable MC_VERSION is not set. This is the version of Hazelcast used to build the package."
  exit 1
fi

if [ -z "${PACKAGE_VERSION}" ]; then
  echo "Variable PACKAGE_VERSION is not set. This is the version of the built package."
  exit 1
fi

export MC_DISTRIBUTION_FILE=hazelcast-management-center-${MC_VERSION}.tar.gz

if [ ! -f "${MC_DISTRIBUTION_FILE}" ]; then
  echo "File ${MC_DISTRIBUTION_FILE} doesn't exits in current directory."
  exit 1;
fi

source common.sh

echo "Building RPM package hazelcast-management-center:${MC_VERSION} package version ${PACKAGE_VERSION}"

# Remove previous build, useful on local
rm -rf build/rpmbuild

mkdir -p build/rpmbuild/SOURCES/
mkdir -p build/rpmbuild/rpm

cp "${MC_DISTRIBUTION_FILE}" "build/rpmbuild/SOURCES/hazelcast-management-center-${MC_VERSION}.tar.gz"

export RPM_BUILD_ROOT='${RPM_BUILD_ROOT}'
export FILENAME='${FILENAME}'
envsubst <packages/rpm/hazelcast-management-center.spec >build/rpmbuild/rpm/hazelcast-management-center.spec

echo "${DEVOPS_PRIVATE_KEY}" > private.key

gpg --batch --import private.key
sudo printf 'allow-preset-passphrase' > /home/runner/.gnupg/gpg-agent.conf # TODO sudo redirect?
gpg-connect-agent reloadagent /bye
/usr/lib/gnupg2/gpg-preset-passphrase --passphrase ${BINTRAY_PASSPHRASE} --preset 50907674C38F9E099C35345E246EBBA203D8E107
rpmbuild --define "_topdir $(realpath build/rpmbuild)" -bb build/rpmbuild/rpm/hazelcast-management-center.spec

rpm --define "_gpg_name deploy@hazelcast.com" --addsign "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm"

if [ "${PUBLISH}" == "true" ]; then
  RPM_SHA256SUM=$(sha256sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm" | cut -d ' ' -f 1)
  RPM_SHA1SUM=$(sha1sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm" | cut -d ' ' -f 1)
  RPM_MD5SUM=$(md5sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm" | cut -d ' ' -f 1)

  # Delete any package that exists - previous version of the same package
  curl -H "Authorization: Bearer ${ARTIFACTORY_SECRET}" \
    -X DELETE \
    "$RPM_REPO_BASE_URL/${PACKAGE_REPO}/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm"

  curl -H "Authorization: Bearer ${ARTIFACTORY_SECRET}" -H "X-Checksum-Deploy: false" -H "X-Checksum-Sha256: $RPM_SHA256SUM" \
    -H "X-Checksum-Sha1: $RPM_SHA1SUM" -H "X-Checksum-MD5: $RPM_MD5SUM" \
    -T"build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm" \
    -X PUT \
    "$RPM_REPO_BASE_URL/${PACKAGE_REPO}/hazelcast-management-center-${RPM_PACKAGE_VERSION}-1.noarch.rpm"

fi
