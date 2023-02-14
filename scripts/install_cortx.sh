#!/usr/bin/bash

set -x

function detect_os()
{
	IS_CENTOS=$(cat /etc/os-release | grep CentOS)
	IS_ROCKY=$(cat /etc/os-release | grep Rocky)
	
	if [ -n "$IS_CENTOS" ]
	then
		export detected_os=CENTOS
	else
		export detected_os=ROCKY
	fi
}

function install_preamble()
{

	yum install -y git make net-tools wget yum-utils 
	yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
	yum install -y consul-1.9.1

	if [ "$detected_os" == "CENTOS" ]
	then
		yum localinstall -y https://yum.puppetlabs.com/puppet/el/7/x86_64/puppet-agent-7.0.0-1.el7.x86_64.rpm
		ln -sf /opt/puppetlabs/bin/facter /usr/bin/facter
	fi
	#yum localinstall -y https://yum.puppetlabs.com/puppet/el/8/x86_64/puppet-agent-7.18.0-1.el8.x86_64.rpm
}

# CORTX-PYUTILS
function install_cortx_py_utils() 
{
	yum install -y epel-release
	if [ "$detected_os" == "CENTOS" ]
	then
		yum install -y gcc rpm-build python36 python36-pip python36-devel python36-setuptools openssl-devel libffi-devel
		yum localinstall -y https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/p/python36-dbus-1.2.4-4.el7.x86_64.rpm
	elif [ "$detected_os" == "ROCKY" ]
	then
		yum install -y gcc rpm-build python3 python3-pip python3-devel python3-setuptools openssl-devel libffi-devel
	        yum localinstall -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/python3-dbus-1.2.4-15.el8.x86_64.rpm
	fi
		
	pip3 install --upgrade pip
	pip3 install -r https://raw.githubusercontent.com/Seagate/cortx-utils/main/py-utils/python_requirements.txt
	pip3 install -r https://raw.githubusercontent.com/Seagate/cortx-utils/main/py-utils/python_requirements.ext.txt

	# Compile and install cortx-pyutils from source
	if [ "$detected_os" == "CENTOS" ]
	then
		cd ~
		git clone --recursive https://github.com/Seagate/cortx-utils -b main
		cd cortx-utils
		./jenkins/build.sh -v 2.0.0 -b 2
		cd py-utils/dist
		sudo yum install -y cortx-py-utils-*.noarch.rpm
	# get rpm from colo server
	elif [ "$detected_os" == "ROCKY" ]
	then
		wget -r -nd --no-parent -A 'cortx-py-utils-2*.rpm' http://cortx-storage.colo.seagate.com/releases/cortx/github/main/rockylinux-8.4/last_successful_prod/cortx_iso/
		yum install -y ./cortx-py-utils*.rpm
	fi
}

# MOTR
function install_motr() 
{
	cd ~
	wget https://github.com/Seagate/cortx/releases/download/build-dependencies/libfabric-1.11.2-1.el7.x86_64.rpm
	wget https://github.com/Seagate/cortx/releases/download/build-dependencies/libfabric-devel-1.11.2-1.el7.x86_64.rpm
	yum install -y ./libfabric*.rpm

	if [ "$detected_os" == "CENTOS" ]
	then
		git clone --recursive https://github.com/Seagate/cortx-motr.git
		cd cortx-motr && ./scripts/install-build-deps
		./autogen.sh && ./configure && make rpms
		yum install -y ~/rpmbuild/RPMS/x86_64/cortx-motr-*.rpm
	elif [ "$detected_os" == "ROCKY" ]
	then
		yum localinstall -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/e/epel-release-8-17.el8.noarch.rpm
		yum config-manager --set-enabled powertools

		wget -r -nd --no-parent -A 'isa-l*.rpm' http://cortx-storage.colo.seagate.com/releases/cortx/github/main/rockylinux-8.4/last_successful_prod/3rd_party/motr/
		yum install -y ./isa-l*.rpm
		wget -r -nd --no-parent -A 'cortx-motr-2*.rpm' http://cortx-storage.colo.seagate.com/releases/cortx/github/main/rockylinux-8.4/last_successful_prod/cortx_iso/
		wget -r -nd --no-parent -A 'cortx-motr-devel-2*.rpm' http://cortx-storage.colo.seagate.com/releases/cortx/github/main/rockylinux-8.4/last_successful_prod/cortx_iso/
		yum install -y ./cortx-motr*.rpm
	fi
}

# HARE
function install_hare() 
{
	cd ~

	git clone https://github.com/Seagate/cortx-hare.git
	cd cortx-hare && make rpm
	yum install -y ~/rpmbuild/RPMS/x86_64/cortx-hare*.rpm
}

#usage
detect_os
echo ${detected_os}
install_preamble
install_cortx_py_utils
install_motr
install_hare

