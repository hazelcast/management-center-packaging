%define mcversion ${MC_VERSION}
%define _buildshell /bin/bash
%define debug_package %{nil}

Name:       hazelcast-management-center
Version:    ${RPM_PACKAGE_VERSION}
Epoch:      1
Release:    1
Summary:    Hazelcast Management Center enables monitoring and management of nodes running Hazelcast.

License:    Hazelcast Enterprise Edition License
URL:		https://www.hazelcast.org/

Source0:    hazelcast-management-center-%{mcversion}.tar.gz
Source1:    hazelcast.service

Requires(pre): shadow-utils

Requires:	java-1.8.0-devel

BuildArch:  noarch
BuildRequires: systemd-rpm-macros

%description
Hazelcast Management Center enables monitoring and management of nodes running Hazelcast.

%prep
%setup -c %{name}-%{mcversion}

%build
true

%pre
echo "Installing Hazelcast Management Center..."

# See https://fedoraproject.org/wiki/Packaging%3aUsersAndGroups#Dynamic_allocation
getent group hazelcast >/dev/null || groupadd -r hazelcast
getent passwd hazelcast >/dev/null || \
    useradd -r -g hazelcast -d %{_prefix}/lib/hazelcast -s /sbin/nologin \
    -c "User to run server process of Hazelcast" hazelcast

%install
rm -rf $RPM_BUILD_ROOT

%{__mkdir} -p %{buildroot}%{_prefix}/lib/%{name}
%{__cp} -vrf %{name}-%{mcversion}/* %{buildroot}%{_prefix}/lib/%{name}
%{__chmod} 755 %{buildroot}%{_prefix}/lib/%{name}/bin/mc-*sh
%{__chmod} 755 %{buildroot}%{_prefix}/lib/%{name}/bin/start.sh
%{__mkdir} -p %{buildroot}/%{_bindir}

for FILENAME in %{buildroot}/%{_prefix}/lib/%{name}/bin/*mc*; do
  case "${FILENAME}" in
    *bat)
      ;;
    *)
      echo "Filename: ${FILENAME}"
      %{__ln_s} %{_prefix}/lib/%{name}/bin/"$(basename "${FILENAME}")" %{buildroot}/%{_bindir}/"$(basename "${FILENAME}")"
      ;;
  esac
done

%clean
rm -rf $RPM_BUILD_ROOT

%post
chown -R hazelcast:hazelcast %{_prefix}/lib/hazelcast/
%systemd_post %{name}.service
printf "\n\nHazelcast Management Center is successfully installed to '%{_prefix}/lib/%{name}/'\n"
printf "\n\nUse 'hz start' or 'systemctl start hazelcast' to start the Hazelcast server\n"

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun %{name}.service

%files
%{_prefix}/lib/%{name}/*jar
%{_prefix}/lib/%{name}/license.txt
%{_prefix}/lib/%{name}/ThirdPartyNotices.txt
%{_prefix}/lib/%{name}/bin
%{_bindir}/*mc*
