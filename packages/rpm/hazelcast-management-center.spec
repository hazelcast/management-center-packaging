%define mcversion ${MC_VERSION}
%define _buildshell /bin/bash

Name:       hazelcast-management-center
Version:    ${RPM_PACKAGE_VERSION}
Epoch:      1
Release:    1
Summary:    Hazelcast Management Center enables monitoring and management of nodes running Hazelcast.

License:    Hazelcast Enterprise Edition License
URL:		https://www.hazelcast.org/

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

%post
printf "\n\nHazelcast Management Center is successfully installed to '%{_prefix}/lib/%{name}/'\n"

%clean
rm -rf $RPM_BUILD_ROOT

%postun
echo "Removing symlinks from /usr/bin"

for FILENAME in /usr/lib/hazelcast-management-center/bin/*mc*; do
  case "${FILENAME}" in
    *bat)
      ;;
    *)
      rm %{buildroot}/%{_bindir}/"$(basename "${FILENAME}")"
      ;;
  esac
done

%files
%{_prefix}/lib/%{name}/*jar
%{_prefix}/lib/%{name}/license.txt
%{_prefix}/lib/%{name}/ThirdPartyNotices.txt
%{_prefix}/lib/%{name}/bin
%{_bindir}/*mc*
