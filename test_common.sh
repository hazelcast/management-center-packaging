#!/usr/bin/env bash

function findScriptDir() {
  CURRENT=$PWD

  DIR=$(dirname "$0")
  cd "$DIR" || exit
  TARGET_FILE=$(basename "$0")

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]
  do
      TARGET_FILE=$(readlink "$TARGET_FILE")
      DIR=$(dirname "$TARGET_FILE")
      cd "$DIR" || exit
      TARGET_FILE=$(basename "$TARGET_FILE")
  done

  SCRIPT_DIR=$(pwd -P)
  # Restore current directory
  cd "$CURRENT" || exit
}

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

findScriptDir

. "$SCRIPT_DIR"/common.sh

TESTS_RESULT=0

function assertReleaseType {
  export MC_VERSION=$1
  local expected=$2
  . "$SCRIPT_DIR"/common.sh
  local msg="Version $MC_VERSION should be a $expected release"
  assert_eq $expected $RELEASE_TYPE "$msg" && log_success "$msg" || TESTS_RESULT=$?
}

log_header "Tests for RELEASE_TYPE"
assertReleaseType "5.2-SNAPSHOT" "snapshot"
assertReleaseType "5.2-BETA-1" "beta"
assertReleaseType "5.1-DEVEL-8" "devel"
assertReleaseType "5.0" "stable"
assertReleaseType "5.1" "stable"
assertReleaseType "5.1.1" "stable"

function assertPackageVersions {
  export MC_VERSION=$1
  export PACKAGE_VERSION=$2
  local expectedDebVersion=$3
  local expectedRpmVersion=$4
  . "$SCRIPT_DIR"/common.sh
  local msg="DEB_PACKAGE_VERSION for (MC_VERSION=$MC_VERSION, PACKAGE_VERSION=$PACKAGE_VERSION) should be $expectedDebVersion"
  assert_eq "$expectedDebVersion" "$DEB_PACKAGE_VERSION" "$msg" && log_success "$msg" || TESTS_RESULT=$?
  msg="RPM_PACKAGE_VERSION for (MC_VERSION=$MC_VERSION, PACKAGE_VERSION=$PACKAGE_VERSION) should be $expectedRpmVersion"
  assert_eq "$expectedRpmVersion" "$RPM_PACKAGE_VERSION" "$msg" && log_success "$msg" || TESTS_RESULT=$?
}

log_header "Tests for DEB_PACKAGE_VERSION and RPM_PACKAGE_VERSION"
assertPackageVersions "5.0.2"        "5.0.2"         "5.0.2-1"           "5.0.2-1"
assertPackageVersions "5.0.2"        "5.0.2-1"       "5.0.2-1"           "5.0.2-1"
assertPackageVersions "5.1"          "5.1"           "5.1-1"             "5.1-1"
assertPackageVersions "5.1"          "5.1-1"         "5.1-1"             "5.1-1"
assertPackageVersions "5.1-SNAPSHOT" "5.1-SNAPSHOT"  "5.1-SNAPSHOT-1"    "5.1.SNAPSHOT-1"
assertPackageVersions "5.1-DEVEL"    "5.1-DEVEL"     "5.1-DEVEL-1"       "5.1.DEVEL-1"
assertPackageVersions "5.1-BETA-1"   "5.1-BETA-1"    "5.1-BETA-1-1"      "5.1.BETA.1-1"
assertPackageVersions "5.1-BETA-1"   "5.1-BETA-1-2"  "5.1-BETA-1-2"      "5.1.BETA.1-2"

function assertMinorVersion {
  export MC_VERSION=$1
  local expected=$2
  . "$SCRIPT_DIR"/common.sh
  local msg="Version $MC_VERSION should be mapped to $MC_MINOR_VERSION minor version"
  assert_eq "$expected" "$MC_MINOR_VERSION" "$msg" && log_success "$msg" || TESTS_RESULT=$?
}

log_header "Tests for HZ_MINOR_VERSION"
assertMinorVersion "5.2-SNAPSHOT" "5.2-SNAPSHOT"
assertMinorVersion "5.10" "5.10"
assertMinorVersion "5.10.1" "5.10"
assertMinorVersion "5.0" "5.0"
assertMinorVersion "5.1.1" "5.1"


assert_eq 0 "$TESTS_RESULT" "All tests should pass"
