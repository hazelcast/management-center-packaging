#!/usr/bin/env bash

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

# With Homebrew we actually don't upload the artifact anywhere, but use the base tar.gz artifact url.
# The package manager then downloads it from there.
# The MC_DISTRIBUTION_FILE is required to compute the hash.
if [ -z "${MC_PACKAGE_URL}" ]; then
  echo "Variable MC_PACKAGE_URL is not set. This is url pointing to hazelcast-management-center distribution tar.gz file"
  exit 1;
fi

source common.sh
source packages/brew/functions.sh

echo "Building Homebrew package hazelcast-management-center:${MC_VERSION} package version ${PACKAGE_VERSION}"

ASSET_SHASUM=$(sha256sum "${MC_DISTRIBUTION_FILE}" | cut -d ' ' -f 1)

TEMPLATE_FILE="$(pwd)/packages/brew/hazelcast-management-center-template.rb"
cd ../homebrew-hz || exit 1

function updateClassName {
  class=$1
  file=$2
  sed -i "s+class HazelcastManagementCenterAT5X <\(.*$\)+class $class <\1+g" "$file"
}

function generateFormula {
  class=$1
  file=$2
  echo "Generating $file formula"
  cp "$TEMPLATE_FILE" "$file"
  updateClassName "$class" "$file"
  sed -i "s+url.*$+url \"${MC_PACKAGE_URL}\"+g" "$file"
  sed -i "s+sha256.*$+sha256 \"${ASSET_SHASUM}\"+g" "$file"
}

BREW_CLASS=$(brewClass "hazelcast-management-center" "${BREW_PACKAGE_VERSION}")
generateFormula "$BREW_CLASS" "hazelcast-management-center@${BREW_PACKAGE_VERSION}.rb"

MC_MINOR_VERSION=$(echo "${MC_VERSION}" | cut -c -3)

# Update hazelcast-management-center and hazelcast-management-center-x.y aliases
# only if the version is release (not SNAPSHOT/DR/BETA)
if [[ "$RELEASE_TYPE" = "stable" ]]; then
  BREW_CLASS=$(brewClass "hazelcast-management-center${MC_MINOR_VERSION}")
  generateFormula "$BREW_CLASS" "hazelcast-management-center-${MC_MINOR_VERSION}.rb"

  cp "hazelcast-management-center@${BREW_PACKAGE_VERSION}.rb" "hazelcast-management-center-${MC_MINOR_VERSION}"

  # Update 'hazelcast-management-center' alias
  # only if the version is greater than (new release) or equal to highest version
  UPDATE_LATEST="true"
  versions=("hazelcast-management-center"-[0-9]*\.rb)
  for version in "${versions[@]}"
  do
    if [[ "$version" > "hazelcast-management-center-${MC_MINOR_VERSION}.rb" ]]; then
      UPDATE_LATEST="false"
    fi
  done

  if [ "${UPDATE_LATEST}" == "true" ]; then
    generateFormula "$(alphanumCamelCase "hazelcast-management-center")" "hazelcast-management-center.rb"
  fi
else
  # Update 'hazelcast-snapshot/beta/dr'
  # only if the version is greater than (new release) or equal to highest version
  UPDATE_LATEST="true"
  versions=("hazelcast-management-center"-[0-9]*\.rb)
  for version in "${versions[@]}"
  do
    if [[ "$version" > "hazelcast-management-center-${MC_MINOR_VERSION}.rb" ]]; then
      UPDATE_LATEST="false"
    fi
  done

  if [ "${UPDATE_LATEST}" == "true" ]; then
    BREW_CLASS=$(brewClass "hazelcast-management-center-$RELEASE_TYPE")
    generateFormula "$BREW_CLASS" "hazelcast-management-center-${RELEASE_TYPE}.rb"
  fi
fi

echo "Homebrew repository updated"
