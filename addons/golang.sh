#!/bin/bash
VER='0.0.1'
######################################################
# golang binary installer
# for Centminmod.com
# written by George Liu (eva2000) centminmod.com
######################################################
GO_VERSION='1.7'

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

if [[ "$(uname -m)" = 'x86_64' ]]; then
  GOARCH='amd64'
else
  GOARCH='386'
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

go_install() {
	cd $DIR_TMP
		
  cecho "Download go${GO_VERSION}.linux-${GOARCH}.tar.gz ..." $boldyellow
  if [ -s go${GO_VERSION}.linux-${GOARCH}.tar.gz ]; then
  	cecho "go${GO_VERSION}.linux-${GOARCH}.tar.gz Archive found, skipping download..." $boldgreen
  else
  	wget -c --progress=bar https://storage.googleapis.com/golang/go${GO_VERSION}.linux-${GOARCH}.tar.gz --tries=3 
	ERROR=$?
		if [[ "$ERROR" != '0' ]]; then
			cecho "Error: go${GO_VERSION}.linux-${GOARCH}.tar.gz download failed." $boldgreen
			checklogdetails
			exit #$ERROR
		else 
  	cecho "Download done." $boldyellow
		fi
  fi
		
	tar -C /usr/local -xzf go${GO_VERSION}.linux-${GOARCH}.tar.gz
	ERROR=$?
	if [[ "$ERROR" != '0' ]]; then
		cecho "Error: go${GO_VERSION}.linux-${GOARCH}.tar.gz extraction failed." $boldgreen
		checklogdetails
		exit #$ERROR
	else
		echo "ls -lah /usr/local/go/"
		ls -lah /usr/local/go/
    cecho "go${GO_VERSION}.linux-${GOARCH}.tar.gz valid file." $boldyellow
		echo ""
	fi
		
	if [[ ! -d /root/golang/packages || ! "$(grep 'GOPATH' /root/.bashrc)" ]]; then
		cecho "---------------------------" $boldyellow
		cecho "/root/.bashrc before update: " $boldwhite
		cat /root/.bashrc
		cecho "---------------------------" $boldyellow
		mkdir -p /root/golang/packages
		export GOPATH=/root/golang/packages
		export PATH=$PATH:/usr/local/go/bin
		export PATH=$GOPATH/bin:$PATH
		if [[ ! "$(grep 'golang' /root/.bashrc)" ]]; then
			echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
			echo "export GOPATH=~/golang/packages" >> /root/.bashrc
			echo "export PATH=\$GOPATH/bin:\$PATH" >> /root/.bashrc
			. /root/.bashrc
			cecho "---------------------------" $boldyellow
			cecho "/root/.bashrc after update: " $boldwhite
			cat /root/.bashrc
			cecho "---------------------------" $boldyellow
		fi
	fi
	echo
	cecho "---------------------------" $boldyellow
	cecho -n "golang Version: " $boldgreen
	go version
	cecho "---------------------------" $boldyellow
}

###########################################################################
case $1 in
	install)
starttime=$(date +%s.%N)
{
		go_install
} 2>&1 | tee ${CENTMINLOGDIR}/centminmod_goinstall_${DT}.log

endtime=$(date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> ${CENTMINLOGDIR}/centminmod_goinstall_${DT}.log
echo "Total golang Install Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_goinstall_${DT}.log
	;;
	*)
		echo "$0 install"
	;;
esac
exit