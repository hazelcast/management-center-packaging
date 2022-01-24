%define mcversion ${MC_VERSION}
%define _buildshell /bin/bash

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
%{__chmod} 755 %{buildroot}%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/mc-*sh
%{__chmod} 755 %{buildroot}%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/start.sh
%{__mkdir} -p %{buildroot}/%{_bindir}

for FILENAME in %{buildroot}/%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/*mc*; do
  case "${FILENAME}" in
    *bat)
      ;;
    *)
      echo "Filename: ${FILENAME}"
      %{__ln_s} %{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin/"$(basename "${FILENAME}")" %{buildroot}/%{_bindir}/"$(basename "${FILENAME}")"
      ;;
  esac
done

%post
printf "\n\nHazelcast Management Center is successfully installed to '%{_prefix}/lib/%{name}/%{name}-%{mcversion}/'\n"

%clean
rm -rf $RPM_BUILD_ROOT

%postun
echo "Removing symlinks from /usr/bin"

for FILENAME in /usr/lib/hazelcast-management-center/hazelcast-management-center-${MC_VERSION}/bin/*mc*; do
  case "${FILENAME}" in
    *bat)
      ;;
    *)
      rm %{buildroot}/%{_bindir}/"$(basename "${FILENAME}")"
      ;;
  esac
done

%files
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/*jar
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/license.txt
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/ThirdPartyNotices.txt
%{_prefix}/lib/%{name}/%{name}-%{mcversion}/bin
%{_bindir}/*mc*
