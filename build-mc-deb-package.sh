#!/usr/bin/env bash

set -x

if [ -z "${MC_VERSION}" ]; then
  echo "Variable MC_VERSION is not set. This is the version of Hazelcast Management Center used to build the package."
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

echo "Building DEB package hazelcast-management-center:${MC_VERSION} package version ${PACKAGE_VERSION}"

# Remove previous build, useful on local
rm -rf build/deb/hazelcast-management-center

mkdir -p build/deb/hazelcast-management-center/DEBIAN
mkdir -p build/deb/hazelcast-management-center/usr/lib/hazelcast-management-center
mkdir -p build/deb/hazelcast-management-center/lib/systemd/system

tar -xf "${MC_DISTRIBUTION_FILE}" -C build/deb/hazelcast-management-center/usr/lib/hazelcast-management-center --strip-components=1

# Replace MC_VERSION and other env variables in the following files
envsubst <packages/deb/hazelcast-management-center/DEBIAN/control >build/deb/hazelcast-management-center/DEBIAN/control

cp packages/deb/hazelcast-management-center/DEBIAN/conffiles build/deb/hazelcast-management-center/DEBIAN/conffiles
cp packages/deb/hazelcast-management-center/DEBIAN/postinst build/deb/hazelcast-management-center/DEBIAN/postinst
cp packages/deb/hazelcast-management-center/DEBIAN/prerm build/deb/hazelcast-management-center/DEBIAN/prerm
cp packages/common/hazelcast-management-center.service build/deb/hazelcast-management-center/lib/systemd/system/hazelcast-management-center.service

# postinst and prerm must be executable
chmod 775 build/deb/hazelcast-management-center/DEBIAN/postinst build/deb/hazelcast-management-center/DEBIAN/prerm

dpkg-deb --build build/deb/hazelcast-management-center

DEB_FILE=hazelcast-management-center-${PACKAGE_VERSION}-all.deb
mv build/deb/hazelcast-management-center.deb "$DEB_FILE"

if [ "${PUBLISH}" == "true" ]; then
  echo "Publishing $DEB_FILE to jfrog"

  DEB_SHA256SUM=$(sha256sum $DEB_FILE | cut -d ' ' -f 1)
  DEB_SHA1SUM=$(sha1sum $DEB_FILE | cut -d ' ' -f 1)
  DEB_MD5SUM=$(md5sum $DEB_FILE | cut -d ' ' -f 1)

  # Delete any package that exists - previous version of the same package
  curl -H "Authorization: Bearer ${ARTIFACTORY_SECRET}" \
    -X DELETE \
    "$DEBIAN_REPO_BASE_URL/hazelcast-management-center-${PACKAGE_VERSION}-all.deb"

  curl -H "Authorization: Bearer ${ARTIFACTORY_SECRET}" -H "X-Checksum-Deploy: false" -H "X-Checksum-Sha256: $DEB_SHA256SUM" \
    -H "X-Checksum-Sha1: $DEB_SHA1SUM" -H "X-Checksum-MD5: $DEB_MD5SUM" \
    -T"$DEB_FILE" \
    -X PUT \
    "$DEBIAN_REPO_BASE_URL/$DEB_FILE;deb.distribution=${PACKAGE_REPO};deb.component=main;deb.architecture=all"

fi
