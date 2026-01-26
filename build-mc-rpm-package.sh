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

# Location on Debian based systems
if [  -f "/usr/lib/gnupg2/gpg-preset-passphrase" ]; then
  GPG_PRESET_PASSPHRASE="/usr/lib/gnupg2/gpg-preset-passphrase"
fi

# Location on Redhat based systems
if [  -f "/usr/libexec/gpg-preset-passphrase" ]; then
  GPG_PRESET_PASSPHRASE="/usr/libexec/gpg-preset-passphrase"
fi

gpg --batch --import <<< "${SIGNING_KEY_PRIVATE_KEY}"
echo 'allow-preset-passphrase' | tee ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye

function get_gpg_key_data {
  local key=$1
  local property=$2

  gpg --show-keys --with-keygrip --with-colons <<< "${key}" | \
  awk -F: -v property="${property}" '$1==property {print $10; exit}'

  return 0
}

SIGNING_KEY_UID=$(get_gpg_key_data "${SIGNING_KEY_PRIVATE_KEY}" "uid")
SIGNING_KEY_KEYGRIP=$(get_gpg_key_data "${SIGNING_KEY_PRIVATE_KEY}" "grp")

${GPG_PRESET_PASSPHRASE} --passphrase "${SIGNING_KEY_PASSPHRASE}" --preset ${SIGNING_KEY_KEYGRIP}

rpmbuild --define "_topdir $(realpath build/rpmbuild)" -bb build/rpmbuild/rpm/hazelcast-management-center.spec

export GPG_TTY="" # to avoid 'warning: Could not set GPG_TTY to stdin: Inappropriate ioctl for device' for the next command
rpm --define "_gpg_name ${SIGNING_KEY_UID}" --addsign "build/rpmbuild/RPMS/noarch/hazelcast-management-center-${RPM_PACKAGE_VERSION}.noarch.rpm"

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
