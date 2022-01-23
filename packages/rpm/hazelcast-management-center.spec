%define mcversion ${MC_VERSION}

Name:       hazelcast-management-center
Version:    ${RPM_PACKAGE_VERSION}
Epoch:      1
Release:    1
Summary:    A tool that allows users to install & run Hazelcast

License:    TODO
URL:		https://hazelcast.org/

Source0:    hazelcast-management-center-%{mcversion}.tar.gz

Requires:	java-1.8.0-devel

BuildArch:  noarch

%description
Hazelcast Management Center enables monitoring and management of nodes running Hazelcast.

%prep
%setup -c %{name}-%{mcversion}

%build
true

%pre
echo "Installing Hazelcast Management Center..."

%install
rm -rf $RPM_BUILD_ROOT

%{__mkdir} -p %{buildroot}%{_prefix}/lib/%{name}/%{name}-%{mcversion}
%{__cp} -vrf %{name}-%{mcversion}/* %{buildroot}%{_prefix}/lib/%{name}/%{name}-%{mcversion}
%{__chmod} 755 %{buildroot}%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz*
%{__mkdir} -p %{buildroot}/%{_bindir}

%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz %{buildroot}/%{_bindir}/hz
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-cli %{buildroot}/%{_bindir}/hz-cli
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-cluster-admin %{buildroot}/%{_bindir}/hz-cluster-admin
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-cluster-cp-admin %{buildroot}/%{_bindir}/hz-cluster-cp-admin
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-healthcheck %{buildroot}/%{_bindir}/hz-healthcheck
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-start %{buildroot}/%{_bindir}/hz-start
%{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/hz-stop %{buildroot}/%{_bindir}/hz-stop

%post
printf "\n\nHazelcast Management Center is successfully installed to '%{_prefix}/lib/%{name}/%{name}-%{mcversion}/'\n"
hz --help

%clean
rm -rf $RPM_BUILD_ROOT

%postun
echo "Removing symlinks from /usr/bin"

for FILENAME in /usr/lib/hazelcast/${HZ_DISTRIBUTION}-${HZ_VERSION}/bin/hz*; do
  case "${FILENAME}" in
    *bat)
      ;;
    *)
      rm "$(basename "${FILENAME}")"
      ;;
  esac
done

if [  ! -f %{buildroot}/%{_bindir}/hz  ]; then
    rm %{buildroot}/%{_bindir}/hz
    rm %{buildroot}/%{_bindir}/hz-cli
    rm %{buildroot}/%{_bindir}/hz-cluster-admin
    rm %{buildroot}/%{_bindir}/hz-cluster-cp-admin
    rm %{buildroot}/%{_bindir}/hz-healthcheck
    rm %{buildroot}/%{_bindir}/hz-start
    rm %{buildroot}/%{_bindir}/hz-stop
fi

%files
# The LICENSE file contains Apache 2 license and is only present in OS
%if "%{hzdistribution}" == "hazelcast"
   %{_prefix}/lib/%{name}/%{name}-%{mcversion}/LICENSE
%endif
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/NOTICE
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/custom-lib
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/lib
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/licenses
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/*.xml
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/*.yaml
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/*.options
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/*.properties
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/examples/*.yaml
%config(noreplace) %{_prefix}/lib/%{name}/%{name}-%{mcversion}/config/examples/*.xml
%{_bindir}/hz
%{_bindir}/hz-cli
%{_bindir}/hz-cluster-admin
%{_bindir}/hz-cluster-cp-admin
%{_bindir}/hz-healthcheck
%{_bindir}/hz-start
%{_bindir}/hz-stop
