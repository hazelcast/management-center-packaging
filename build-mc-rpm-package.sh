#!/usr/bin/env bash

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

echo "Building RPM package hazelcast-management-center:${MC_VERSION} package version ${RPM_PACKAGE_VERSION}"

# Remove previous build, useful on local
rm -rf build/rpmbuild

mkdir -p build/rpmbuild/SOURCES/
mkdir -p build/rpmbuild/rpm

cp "${MC_DISTRIBUTION_FILE}" "build/rpmbuild/SOURCES/hazelcast-management-center-${MC_VERSION}.tar.gz"
cp packages/common/hazelcast-management-center.service build/rpmbuild/SOURCES/hazelcast-management-center.service

export RPM_BUILD_ROOT='${RPM_BUILD_ROOT}'
export FILENAME='${FILENAME}'
envsubst <packages/rpm/hazelcast-management-center.spec >build/rpmbuild/rpm/hazelcast-management-center.spec

echo "${DEVOPS_PRIVATE_KEY}" > private.key

# Location on Debian based systems
if [  -f "/usr/lib/gnupg2/gpg-preset-passphrase" ]; then
  GPG_PRESET_PASSPHRASE="/usr/lib/gnupg2/gpg-preset-passphrase"
fi

# Location on Redhat based systems
if [  -f "/usr/libexec/gpg-preset-passphrase" ]; then
  GPG_PRESET_PASSPHRASE="/usr/libexec/gpg-preset-passphrase"
fi

gpg --batch --import private.key
echo 'allow-preset-passphrase' | tee ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye
$GPG_PRESET_PASSPHRASE --passphrase ${BINTRAY_PASSPHRASE} --preset 50907674C38F9E099C35345E246EBBA203D8E107
rpmbuild --define "_topdir $(realpath build/rpmbuild)" -bb build/rpmbuild/rpm/hazelcast-management-center.spec

export GPG_TTY="" # to avoid 'warning: Could not set GPG_TTY to stdin: Inappropriate ioctl for device' for the next command
rpm --define "_gpg_name deploy@hazelcast.com" --addsign "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm"

if [ "${PUBLISH}" == "true" ]; then
  RPM_SHA256SUM=$(sha256sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm" | cut -d ' ' -f 1)
  RPM_SHA1SUM=$(sha1sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm" | cut -d ' ' -f 1)
  RPM_MD5SUM=$(md5sum "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm" | cut -d ' ' -f 1)

  # Delete any package that exists - previous version of the same package
  curl -H "Authorization: Bearer ${JFROG_TOKEN}" \
    -X DELETE \
    "$RPM_REPO_BASE_URL/${PACKAGE_REPO}/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm"

  curl -H "Authorization: Bearer ${JFROG_TOKEN}" -H "X-Checksum-Deploy: false" -H "X-Checksum-Sha256: $RPM_SHA256SUM" \
    -H "X-Checksum-Sha1: $RPM_SHA1SUM" -H "X-Checksum-MD5: $RPM_MD5SUM" \
    -T"build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm" \
    -X PUT \
    "$RPM_REPO_BASE_URL/${PACKAGE_REPO}/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm"

fi
