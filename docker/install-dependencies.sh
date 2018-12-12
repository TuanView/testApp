#!/bin/bash

# This script will install the dependencies/libraries required for building platform 
	# Created by Abhishek, for View.Inc, 20171121
	# Includes - RPM only
	# execute only one time on fresh system
#
install_failed_count=0
installation_failed_result_string=""
installation_success_result_string="Successfully installed all dependencies"

check_if_last_installation_failed()
{
	if [ $? -ne 0 ]; then
		let install_failed_count+=1
		installation_failed_result_string="$installation_failed_result_string""\n INSTALLATION FAILED FOR : $1"
	fi
}

function update_epel_repo() {

 	# This function will replace epel.repo to download gcc-7.2.1
	
	echo "
# Added by install_dependency script
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch/debug
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[group_kdesig-cmake3_EPEL]
name=Copr repo for cmake3_EPEL owned by @kdesig
baseurl=https://copr-be.cloud.fedoraproject.org/results/@kdesig/cmake3_EPEL/epel-7-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/@kdesig/cmake3_EPEL/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1

" >> /etc/yum.repos.d/epel.repo
}

function _compare_ver() {

	# This function will compare two version string

	if [[ $1 == $2 ]]
	then
		return 0
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	# fill empty fields in ver1 with zeros
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
	do
		ver1[i]=0
	done
	for ((i=0; i<${#ver1[@]}; i++))
	do
		if [[ -z ${ver2[i]} ]]
		then
			# fill empty fields in ver2 with zeros
            		ver2[i]=0
        	fi
		if ((10#${ver1[i]} > 10#${ver2[i]}))
        	then
                	echo $1 is greator than $2
            		return 0
        	fi
		if ((10#${ver1[i]} < 10#${ver2[i]}))
		then
			return 1
        	fi
	done
	return 0
}

install_dep_rpm() {

	_mariadb_installed_flag='0'

	currentPath=$(pwd)
	mariadbRepoFilename="MariaDB.repo"
	yumRepoFilesPath="/etc/yum.repos.d/"

	# Install yum update
	printf "yum update is in progress...\n"
	yum -y update

	# Install epel repository
	yum -y install epel-release 
	check_if_last_installation_failed "epel-release"

	# LAMP Setup
	# --- Start ---

	if ! [ -f /sbin/httpd ]; then 

		# Install httpd

		yum -y install httpd 
		check_if_last_installation_failed "httpd"

		systemctl start httpd.service > /dev/null
	fi
	
	if [ -f /bin/mysql ]; then
		var=$(mysql --version)
		if [ $? -eq 0 ]; then
			if [[ $var == *"MariaDB"* ]]; then
				printf "MARIADB INSTALLED \n"
				_mariadb_installed_flag='1'
			else

				# Remove MySQL

				printf "MYSQL IS INSTALLED, NOW REMOVING MYSQL : \n\n"
				package=^mysql-
				pkgs=$(rpm -qa | grep "$package")

				for i in "${pkgs[@]}"
				do
					printf "REMOVING PACKAGE NAME : $i \n"
					rpm -e --nodeps $i
					if [ $? -ne 0 ]; then
						printf "UNABLE TO REMOVE $i, SKIPPING .... \n"
					fi
				done
			fi
		fi
	fi

	if (($_mariadb_installed_flag == 0)); then
		
		# Install MariaDB-server
		
		cp -f $currentPath'/'$mariadbRepoFilename $yumRepoFilesPath
		yum -y install MariaDB-server 
		check_if_last_installation_failed "MariaDB-server"
	
		systemctl start mariadb  > /dev/null
	
                # Do not call this for building docker view base image
		# mysql_secure_installation

		_mariadb_installed_flag='1'
	fi
	ln -s /usr/lib64/libmysqlclient_r.so.16 /usr/lib64/libmysqlclient_r.so

	if ! [ -f /bin/php ]; then
	
		# Install PHP 
		yum -y install php 
		check_if_last_installation_failed "php"
	fi

	yum -y install php-mysql 
	check_if_last_installation_failed "php-mysql"

	# LAMP Setup
	# --- End ---

	yum -y clean all

	# Install gcc-7.2.1
	# Update epel.repo
	
	update_epel_repo

	yum -y --setopt=group_package_types=mandatory,default,optional groupinstall "Development Tools"	
        
	yum -y install centos-release-scl
	
	yum-config-manager --enable rhel-server-rhscl-7-rpms
	
	yum -y install devtoolset-7

	check_if_last_installation_failed "devtoolset-7"
	if [ -f /usr/bin/gcc ]
	then
		_required_gcc_ver="7.1"
		_current_gcc_ver=$(gcc --version | grep ^gcc | awk '{print $3}')
		_compare_ver $_current_gcc_ver $_required_gcc_ver
		if [ $? -ne 0 ]
		then
			# update gcc
			yum -y remove --skip-broken gcc

			yum -y install centos-release-scl

			yum-config-manager --enable rhel-server-rhscl-7-rpms

			yum -y install devtoolset-7
			
			check_if_last_installation_failed "devtoolset-7"

			rm -rf /usr/bin/gcc && ln -s /opt/rh/devtoolset-7/root/usr/bin/gcc /usr/bin/
			
			rm -rf /usr/bin/c++ && ln -s /opt/rh/devtoolset-7/root/usr/bin/c++ /usr/bin/
			
			rm -rf /usr/bin/g++ && ln -s /opt/rh/devtoolset-7/root/usr/bin/g++ /usr/bin/
		fi
	else
		ln -s /opt/rh/devtoolset-7/root/usr/bin/gcc /usr/bin/
		ln -s /opt/rh/devtoolset-7/root/usr/bin/c++ /usr/bin/
		ln -s /opt/rh/devtoolset-7/root/usr/bin/g++ /usr/bin/
	fi
	
	yum -y install git  
	check_if_last_installation_failed "git"

    yum -y install cmake3 
	check_if_last_installation_failed "cmake3"

    yum -y install jansson-devel
	check_if_last_installation_failed "jansson-devel"

	yum -y install httpd-devel
	check_if_last_installation_failed "httpd-devel"

	yum -y install zlib-devel
	check_if_last_installation_failed "zlib-devel"

    	yum -y install scons  
	check_if_last_installation_failed "scons"

    	yum -y install openssl-devel
	check_if_last_installation_failed "openssl-devel"

	yum -y install libcurl-devel
	check_if_last_installation_failed "libcurl-devel"

	yum -y install curlftpfs
	check_if_last_installation_failed "curlftpfs"

	# Install MariaDB-client and MariaDB-devel
	if (( $_mariadb_installed_flag == 0 )); then
		cp -f $currentPath'/'$mariadbRepoFilename $yumRepoFilesPath
	fi
	yum -y install MariaDB-client
	check_if_last_installation_failed "MariaDB-client"

	yum -y install MariaDB-devel 
	check_if_last_installation_failed "MariaDB-devel"

    	yum -y install libwebsockets-devel
	check_if_last_installation_failed "libwebsockets-devel"
	
	yum -y install pam-devel 
	check_if_last_installation_failed "pam-devel"

	yum -y install autoconf 
	check_if_last_installation_failed "autoconf"

	yum -y install automake 
	check_if_last_installation_failed "automake"

	yum -y install libtool
	check_if_last_installation_failed "libtool"
	
	# Restarting and enabling services to automatically start after boot

	systemctl restart httpd.service > /dev/null
	systemctl enable httpd.service > /dev/null                                  

	systemctl restart mariadb  > /dev/null
	systemctl enable mariadb  > /dev/null
	
}


install_dep_debian() 
{
	printf " Error, can not create build environment on debian system.\n"
	exit 0
}


####   Main function

if ping -c 4 google.com >/dev/null 2>&1 ; then
	if [ -f /etc/redhat-release ]; then
		install_dep_rpm
		if [ $install_failed_count -ne 0 ]; then
			printf "\n!!!! $install_failed_count Installation Failed !!!! \n"
			printf "$installation_failed_result_string \n"
			printf "\n !!!! Try Again !!!! \n"
		else
			printf "$installation_success_result_string \n"
		fi
	else
		install_dep_debian
	fi
else
	printf "Check your internet connectivity, the script will exit now\n" 
	printf "Please try to re-run the script after internet connectivity is up!!\n"
	exit 0

fi

