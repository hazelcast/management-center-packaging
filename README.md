# Hazelcast Management Center Packaging

Automation scripts to package Hazelcast Management center as DEB, RPM 
or Homebrew package.

## Requirements

- To install Hazelcast via a package manager your system must support
  either yum, apt or Homebrew.
- JRE 8+ is required.

## Install latest stable version of Hazelcast Management Center

This version is suitable for most users of Hazelcast Management Center. When unsure, use
this version.

### Install with apt

You can find the Debian packages for Hazelcast Management Center at
[Hazelcast's Debian repository](https://repository.hazelcast.com/debian).
Run the following commands to install the package using apt:

```
wget -qO - https://repository.hazelcast.com/api/gpg/key/public | sudo apt-key add -
echo "deb https://repository.hazelcast.com/debian stable main" | sudo tee -a /etc/apt/sources.list
sudo apt update && sudo apt install hazelcast-management-center
```

### Install with yum/dnf

The RPM packages for Hazelcast Management Center are kept at
[Hazelcast's RPM repository](https://repository.hazelcast.com/rpm/).
Please run the following commands to install the package using yum/dnf:

```
wget https://repository.hazelcast.com/rpm/stable/hazelcast-rpm-stable.repo -O hazelcast-rpm-stable.repo
sudo mv hazelcast-rpm-stable.repo /etc/yum.repos.d/
sudo yum install hazelcast-management-center
```

### Install with Homebrew

To install with Homebrew, you first need to tap the `hazelcast/hz`
repository. Once you’ve tapped the repo, you can use `brew install` to
install:

```
brew tap hazelcast/hz
brew install hazelcast-management-center
```

## Upgrading

Use default commands of your package manager to perform the upgrade of the installed `hazelcast-management-center` package

### Upgrade with apt

```shell
sudo apt update
sudo apt install hazelcast-management-center
```

### Upgrade with yum/dnf/microdnf

```shell
sudo yum update hazelcast-management-center
```

### Upgrade with Homebrew

```shell
brew install hazelcast-management-center
```

## Installing an older version and preventing upgrades

### Install an older version with apt

After adding the repository run the following to install e.g.
version `5.0.1`:

```
sudo apt install hazelcast-management-center=5.0.1
```

To keep the particular version during `apt upgrade` hold the package at
the installed version by running the following:

```
sudo apt-mark hold hazelcast-management-center
```

### Install an older version with yum

After adding the repository run the following to install e.g.
version `5.0.1`:

```
sudo yum install hazelcast-management-center-5.0.1
```

To keep the particular version during `yum update` hold the package at
the installed version by running the following:

```
sudo yum -y install yum-versionlock
sudo yum versionlock hazelcast-management-center
```

### Install an older version with Homebrew

Run the following to install e.g. version `5.0.1`:

```
brew install hazelcast-management-center@5.0.1
```

## Installing a SNAPSHOT version

### Install a SNAPSHOT version with apt

You need to replace `stable` with `snapshot` in the
repository definition to use Hazelcast Management Center snapshots.

Run the following to install the latest snapshot version:

```
wget -qO - https://repository.hazelcast.com/api/gpg/key/public | sudo apt-key add -
echo "deb https://repository.hazelcast.com/debian snapshot main" | sudo tee -a /etc/apt/sources.list
sudo apt update && sudo apt install hazelcast-management-center
```

### Install a SNAPSHOT version with yum

You need to replace `stable` with `snapshot` in the
repository definition to use Hazelcast Management Center snapshots.

Run the following to install the latest snapshot version:

```
wget https://repository.hazelcast.com/rpm/snapshot/hazelcast-rpm.repo -O hazelcast-snapshot-rpm.repo
sudo mv hazelcast-snapshot-rpm.repo /etc/yum.repos.d/
sudo yum install hazelcast-management-center
```

### Install a SNAPSHOT version with Homebrew

You need to add `snapshot` suffix to the package version when
installing a snapshot.

Run the following to install the latest `6.0-SNAPSHOT` version:

```
brew tap hazelcast/hz
brew install hazelcast-management-center@6.0.snapshot
```

Search for available versions using the following command:

```
brew search hazelcast-management-center
```

## Running Hazelcast Management Center

After successful installation the commands from Hazelcast Management 
Center distribution `bin` directory should be on path.

Run the following command to start a Hazelcast Management Center with
the default configuration:

```
hz-mc start
``` 

To see additional options, run the following:

```
hz-mc start --help
```

NOTE: `hz-mc` command is not available in versions 5.0-5.0.4, use 
`start.sh` from the installation directory instead (this file is not 
linked to `/usr/bin/` because of likely conflicts).
