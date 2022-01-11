# RPM Packages for Fedora (, RHEL, Suse, etc.)

## Add package source with:
```
# import the gpg key
rpm --import https://mcraa.github.io/ppa/rpm/repodata/KEY.gpg

# add the actual source
sudo dnf config-manager --add-repo https://mcraa.github.io/ppa/rpm/balena-etcher.repo

```
## Install with
```
sudo yum install balena-etcher-electron
```

> The right commands for your specific distro and package manager like `DNF/Microdnf/YUM/Zypper` can be found in the manuals of your OS. 