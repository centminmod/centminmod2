#!/bin/bash
VER='0.0.3'
######################################################
# node.js installer
# for Centminmod.com
# written by George Liu (eva2000) centminmod.com
######################################################
# switch to nodesource yum repo instead of source compile
NODEJSVER='4.4.4'
NODEJS_SOURCEINSTALL='y'
REINSTALL='y'

DT=$(date +"%d%m%y-%H%M%S")
CENTMINLOGDIR='/root/centminlogs'
DIR_TMP='/svr-setup'
######################################################
# Setup Colours
black='\E[30;40m'
red='\E[31;40m'
green='\E[32;40m'
yellow='\E[33;40m'
blue='\E[34;40m'
magenta='\E[35;40m'
cyan='\E[36;40m'
white='\E[37;40m'

boldblack='\E[1;30;40m'
boldred='\E[1;31;40m'
boldgreen='\E[1;32;40m'
boldyellow='\E[1;33;40m'
boldblue='\E[1;34;40m'
boldmagenta='\E[1;35;40m'
boldcyan='\E[1;36;40m'
boldwhite='\E[1;37;40m'

Reset="tput sgr0"      #  Reset text attributes to normal
                       #+ without clearing screen.

cecho ()                     # Coloured-echo.
                             # Argument $1 = message
                             # Argument $2 = color
{
message=$1
color=$2
echo -e "$color$message" ; $Reset
return
}

###########################################
CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)
if [ ! -d "$CENTMINLOGDIR" ]; then
	mkdir -p "$CENTMINLOGDIR"
fi

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(cat /etc/redhat-release | awk '{ print $7 }')
    OLS='y'
fi

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=`grep "processor" /proc/cpuinfo |wc -l`
    CPUS=$(echo $CPUS+1 | bc)
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=`grep "processor" /proc/cpuinfo |wc -l`
    CPUS=$(echo $CPUS+1 | bc)
    MAKETHREADS=" -j$CPUS"
fi

preyum() {
	if [[ ! -d /svr-setup ]]; then
		yum -y install gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel make bzip2 autoconf automake libtool bison iconv-devel sqlite-devel openssl-devel
	elif [[ -z "$(rpm -ql libffi-devel)" || -z "$(rpm -ql libyaml-devel)" || -z "$(rpm -ql sqlite-devel)" ]]; then
		yum -y install libffi-devel libyaml-devel sqlite-devel
	fi

	mkdir -p /home/.ccache/tmp
}

scl_install() {
	# if gcc version is less than 4.7 (407) install scl collection yum repo
	if [[ "$CENTOS_SIX" = '6' ]]; then
		if [[ "$(gcc --version | head -n1 | awk '{print $3}' | cut -d . -f1,2 | sed "s|\.|0|")" -lt '407' ]]; then
			cecho "install scl for newer gcc and g++ versions" $boldgreen
			wget http://linuxsoft.cern.ch/cern/scl/slc6-scl.repo -O /etc/yum.repos.d/slc6-scl.repo
			rpm --import http://linuxsoft.cern.ch/cern/scl/RPM-GPG-KEY-cern
			yum -y install devtoolset-3 -q

			CCTOOLSET=' --gcc-toolchain=/opt/rh/devtoolset-3/root/usr/'
			unset CC
			unset CXX
			# export CC="/opt/rh/devtoolset-3/root/usr/bin/gcc ${CCTOOLSET}"
			# export CXX="/opt/rh/devtoolset-3/root/usr/bin/g++"
			CLANG_CCOPT=""
			export CC="ccache /usr/bin/clang ${CCTOOLSET}${CLANG_CCOPT}"
			export CXX="ccache /usr/bin/clang++ ${CCTOOLSET}${CLANG_CCOPT}"
			export CCACHE_CPP2=yes
			echo ""
		else
			CCTOOLSET=""
		fi
	fi # centos 6 only needed
}

installnodejs() {

# nodesource yum only works on CentOS 7 right now
# https://github.com/nodesource/distributions/issues/128
# https://github.com/nodesource/distributions/blob/master/OLDER_DISTROS.md
if [[ "$CENTOS_SEVEN" = '7' ]]; then
	if [[ "$(which node >/dev/null 2>&1; echo $?)" != '0' ]]; then
    	cd $DIR_TMP
    	curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
    	yum -y install nodejs --disableplugin=priorities
    	npm install npm@latest -g
	
		echo
		cecho "---------------------------" $boldyellow
		cecho -n "Node.js Version: " $boldgreen
		node -v
		cecho "---------------------------" $boldyellow
		cecho -n "npm Version: " $boldgreen
		npm --version
		cecho "---------------------------" $boldyellow
		echo
		cecho "node.js source install completed" $boldgreen
	else
		echo
		cecho "node.js install already detected" $boldgreen
	fi
elif [[ "$CENTOS_SIX" = '6' ]]; then
	echo
	cecho "--------------------------------------------------------------------" $boldyellow
	cecho "CentOS 6.x detected... " $boldgreen
	cecho "nodesource YUM install currently only works on CentOS 7.x systems" $boldgreen
	cecho "alternative is to compile node.js from source instead" $boldgreen
	cecho "due to devtoolset-3 & source compilation method it may" $boldgreen
	cecho "take between 10-45 minutes to compile depending on system" $boldgreen
	cecho "--------------------------------------------------------------------" $boldyellow
	echo
	read -ep "Do you want to continue with node.js source install ? [y/n]: " nodecontinue
	echo
	if [[ "$nodecontinue" = [yY] && "$NODEJS_SOURCEINSTALL" = [yY] ]]; then
		if [[ "$(which node >/dev/null 2>&1; echo $?)" != '0' || "$REINSTALL" = [yY] ]]; then
	
			if [[ ! -f /opt/rh/devtoolset-3/root/usr/bin/gcc || ! -f /opt/rh/devtoolset-3/root/usr/bin/g++ ]]; then
				scl_install
			elif [[ -f /opt/rh/devtoolset-3/root/usr/bin/gcc && -f /opt/rh/devtoolset-3/root/usr/bin/g++ ]]; then
				CCTOOLSET=' --gcc-toolchain=/opt/rh/devtoolset-3/root/usr/'
				unset CC
				unset CXX
				CLANG_CCOPT=""
				export CC="ccache /usr/bin/clang ${CCTOOLSET}${CLANG_CCOPT}"
				export CXX="ccache /usr/bin/clang++ ${CCTOOLSET}${CLANG_CCOPT}"
				export CCACHE_CPP2=yes
				echo ""
			fi
		
    		cd $DIR_TMP
		
        		cecho "Download node-v${NODEJSVER}.tar.gz ..." $boldyellow
    		if [ -s node-v${NODEJSVER}.tar.gz ]; then
        		cecho "node-v${NODEJSVER}.tar.gz Archive found, skipping download..." $boldgreen
    		else
        		wget -c --progress=bar http://nodejs.org/dist/v${NODEJSVER}/node-v${NODEJSVER}.tar.gz --tries=3 
		ERROR=$?
			if [[ "$ERROR" != '0' ]]; then
			cecho "Error: node-v${NODEJSVER}.tar.gz download failed." $boldgreen
		checklogdetails
			exit #$ERROR
		else 
         		cecho "Download done." $boldyellow
		#echo ""
			fi
    		fi
		
			tar xzf node-v${NODEJSVER}.tar.gz 
			ERROR=$?
			if [[ "$ERROR" != '0' ]]; then
			cecho "Error: node-v${NODEJSVER}.tar.gz extraction failed." $boldgreen
		checklogdetails
			exit #$ERROR
		else 
         		cecho "node-v${NODEJSVER}.tar.gz valid file." $boldyellow
				echo ""
			fi
		
			cd node-v${NODEJSVER}
			make clean
			./configure
			make${MAKETHREADS}
			make install
			make doc
    		npm install npm@latest -g
		
			echo
			cecho "---------------------------" $boldyellow
			cecho -n "Node.js Version: " $boldgreen
			node -v
			cecho "---------------------------" $boldyellow
			cecho -n "npm Version: " $boldgreen
			npm --version
			cecho "---------------------------" $boldyellow
			echo
			cecho "node.js source install completed" $boldgreen
		else
			echo
			cecho "node.js install already detected" $boldgreen
		fi
	else
		if [[ "$NODEJS_SOURCEINSTALL" != [yY] ]]; then
			echo
			cecho "NODEJS_SOURCEINSTALL=n is set" $boldgreen
			cecho "exiting..." $boldgreen
			exit			
		else	
			echo
			cecho "exiting..." $boldgreen
			exit
		fi
	fi # nodecontinue
fi

}

###########################################################################
case $1 in
	install)
starttime=$(date +%s.%N)
{
		# preyum
		installnodejs
} 2>&1 | tee ${CENTMINLOGDIR}/centminmod_nodejs_install_${DT}.log

endtime=$(date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> ${CENTMINLOGDIR}/centminmod_nodejs_install_${DT}.log
echo "Total Node.js Install Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_nodejs_install_${DT}.log
	;;
	*)
		echo "$0 install"
	;;
esac
exit