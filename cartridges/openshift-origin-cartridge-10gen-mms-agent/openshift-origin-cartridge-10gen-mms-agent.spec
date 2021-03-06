%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.21.6
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb-2.2
Requires:      pymongo
Requires:      mms-agent
BuildArch:     noarch

%description
Provides 10gen MMS agent cartridge support


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
cp -r * %{buildroot}%{cartridgedir}/

%clean
rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/10gen-mms-agent


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/metadata
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.21.6-1
- Merge pull request #1988 from ironcladlou/dev/v2carts/locked-files-refactor
  (dmcphers@redhat.com)
- Bug 950224: Remove unnecessary Endpoints (ironcladlou@gmail.com)
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 949817 (dmcphers@redhat.com)

* Mon Apr 08 2013 Dan McPherson <dmcphers@redhat.com> 1.21.4-1
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Sat Apr 06 2013 Dan McPherson <dmcphers@redhat.com> 1.21.3-1
- new package built with tito

* Sat Apr 06 2013 Dan McPherson <dmcphers@redhat.com> 1.21.2-1
- new package built with tito

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
