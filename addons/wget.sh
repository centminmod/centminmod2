#!/bin/bash
###########################################################
# wget source installer to /usr/local/bin/wget path for
# centminmod.com LEMP stacks
# installs newer wget version than available via centos RPM
# repos but does not interfere with YUM installed wget as it
# is just an alias wget command setup
###########################################################
DT=$(date +"%d%m%y-%H%M%S")
CENTMINLOGDIR='/root/centminlogs'
DIR_TMP='/svr-setup'
LOCALCENTMINMOD_MIRROR='https://centminmod.com'

ALTPCRE_VERSION='8.39'
ALTPCRELINKFILE="pcre-${ALTPCRE_VERSION}.tar.gz"
ALTPCRELINK="${LOCALCENTMINMOD_MIRROR}/centminmodparts/pcre/${ALTPCRELINKFILE}"

WGET_VERSION='1.18'
WGET_FILENAME="wget-${WGET_VERSION}.tar.gz"
WGET_LINK="http://ftpmirror.gnu.org/wget/${WGET_FILENAME}"
WGET_LINKLOCAL="${LOCALCENTMINMOD_MIRROR}/centminmodparts/wget/${WGET_FILENAME}"
###########################################################
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
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
fi

###########################################################
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

###########################################################

scl_install() {
  # if gcc version is less than 4.7 (407) install scl collection yum repo
  if [[ "$CENTOS_SIX" = '6' ]]; then
    if [[ "$(gcc --version | head -n1 | awk '{print $3}' | cut -d . -f1,2 | sed "s|\.|0|")" -lt '407' ]]; then
      echo "install centos-release-scl for newer gcc and g++ versions"
      yum -y install centos-release-scl -q
      yum -y install devtoolset-4-gcc devtoolset-4-gcc-c++ devtoolset-4-binutils -q
      echo
      /opt/rh/devtoolset-4/root/usr/bin/gcc --version
      /opt/rh/devtoolset-4/root/usr/bin/g++ --version
    fi
  elif [[ "$CENTOS_SEVEN" = '7' ]]; then
      echo "install centos-release-scl for newer gcc and g++ versions"
      yum -y install centos-release-scl -q
      yum -y install devtoolset-4-gcc devtoolset-4-gcc-c++ devtoolset-4-binutils -q
      echo
      /opt/rh/devtoolset-4/root/usr/bin/gcc --version
      /opt/rh/devtoolset-4/root/usr/bin/g++ --version
  fi # centos 6 only needed
}

gccdevtools() {
  if [[ ! -f /opt/rh/devtoolset-4/root/usr/bin/gcc || ! -f /opt/rh/devtoolset-4/root/usr/bin/g++ ]] && [[ "$CENTOS_SIX" = '6' ]]; then
    scl_install
    unset CC
    unset CXX
    export CC="/opt/rh/devtoolset-4/root/usr/bin/gcc"
    export CXX="/opt/rh/devtoolset-4/root/usr/bin/g++" 
  elif [[ -f /opt/rh/devtoolset-4/root/usr/bin/gcc && -f /opt/rh/devtoolset-4/root/usr/bin/g++ ]] && [[ "$(gcc --version | head -n1 | awk '{print $3}' | cut -d . -f1,2 | sed "s|\.|0|")" -lt '407' ]]; then
    unset CC
    unset CXX
    export CC="/opt/rh/devtoolset-4/root/usr/bin/gcc"
    export CXX="/opt/rh/devtoolset-4/root/usr/bin/g++" 
  fi
}

source_pcreinstall() {
  if [[ "$(/usr/local/bin/pcre-config --version 2>&1 | grep -q ${ALTPCRE_VERSION} >/dev/null 2>&1; echo $?)" != '0' ]] || [[ -f /usr/local/bin/pcretest && "$(/usr/local/bin/pcretest -C | grep 'No UTF-8 support' >/dev/null 2>&1; echo $?)" = '0' ]] || [[ -f /usr/local/bin/pcretest && "$(/usr/local/bin/pcretest -C | grep 'No just-in-time compiler support' >/dev/null 2>&1; echo $?)" = '0' ]]; then
  cd "$DIR_TMP"
  cecho "Download $ALTPCRELINKFILE ..." $boldyellow
  if [ -s "$ALTPCRELINKFILE" ]; then
    cecho "$ALTPCRELINKFILE Archive found, skipping download..." $boldgreen
  else
    wget -c --progress=bar "$ALTPCRELINK" --tries=3 
    ERROR=$?
    if [[ "$ERROR" != '0' ]]; then
      cecho "Error: $ALTPCRELINKFILE download failed." $boldgreen
      exit #$ERROR
    else 
      cecho "Download done." $boldyellow
    fi
  fi
  
  tar xzf "$ALTPCRELINKFILE"
  ERROR=$?
  if [[ "$ERROR" != '0' ]]; then
    cecho "Error: $ALTPCRELINKFILE extraction failed." $boldgreen
    exit #$ERROR
  else 
    cecho "$ALTPCRELINKFILE valid file." $boldyellow
    echo ""
  fi
  cd "pcre-${ALTPCRE_VERSION}"
  make clean >/dev/null 2>&1
  ./configure --enable-utf8 --enable-unicode-properties --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --enable-jit
  make${MAKETHREADS}
  make install
  /usr/local/bin/pcre-config --version
  fi
}

source_wgetinstall() {
  if [[ "$(/usr/local/bin/wget -V | head -n1 | awk '{print $3}' | grep -q ${WGET_VERSION} >/dev/null 2>&1; echo $?)" != '0' ]]; then
  cd "$DIR_TMP"
  cecho "Download $WGET_FILENAME ..." $boldyellow
  if [ -s "$WGET_FILENAME" ]; then
    cecho "$WGET_FILENAME Archive found, skipping download..." $boldgreen
  else

    curl -sI --connect-timeout 5 --max-time 5 "$WGET_LINK" | grep 'HTTP\/' | grep '200'
    WGET_CURLCHECK=$?
    if [[ "$WGET_CURLCHECK" = '0' ]]; then
      wget -c --progress=bar "$WGET_LINK" -O "$WGET_FILENAME" --tries=3
    else
      WGET_LINK="$WGET_LINKLOCAL"
      echo "wget -c --progress=bar "$WGET_LINK" -O "$WGET_FILENAME" --tries=3"
      wget -c --progress=bar "$WGET_LINK" -O "$WGET_FILENAME" --tries=3
    fi
    ERROR=$?
    if [[ "$ERROR" != '0' ]]; then
      cecho "Error: $WGET_FILENAME download failed." $boldgreen
      exit #$ERROR
    else 
      cecho "Download done." $boldyellow
    fi
  fi
  
  tar xzf "$WGET_FILENAME"
  ERROR=$?
  if [[ "$ERROR" != '0' ]]; then
    cecho "Error: $WGET_FILENAME extraction failed." $boldgreen
    exit #$ERROR
  else 
    cecho "$WGET_FILENAME valid file." $boldyellow
    echo ""
  fi
  cd "wget-${WGET_VERSION}"
  gccdevtools
  if [ -f config.status ]; then
    make clean
  fi
  if [[ "$(uname -m)" = 'x86_64' ]]; then
    export CFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic"
    export PCRE_CFLAGS="-I /usr/local/include"
    export PCRE_LIBS="-L /usr/local/lib -lpcre"
  else
    export CFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m32 -mtune=generic"
    export PCRE_CFLAGS="-I /usr/local/include"
    export PCRE_LIBS="-L /usr/local/lib -lpcre"
    if [ -f /root/.wgetrc ]; then
      \cp -fp /root/.wgetrc /root/.wgetrc-bak
      echo "ca_certificate=/etc/pki/tls/certs/ca-bundle.crt" > /root/.wgetrc
    else
      echo "ca_certificate=/etc/pki/tls/certs/ca-bundle.crt" > /root/.wgetrc
    fi
  fi
  # ./configure --with-ssl=openssl PCRE_CFLAGS="-I /usr/local/include" PCRE_LIBS="-L /usr/local/lib -lpcre"
  ./configure --with-ssl=openssl
  make${MAKETHREADS}
  make install
  echo "/usr/local/lib/" > /etc/ld.so.conf.d/wget.conf
  ldconfig
  if [[ ! "$(grep '^alias wget' /root/.bashrc)" ]] && [[ "$(wget -V | head -n1 | awk '{print $3}' | grep -q ${WGET_VERSION} >/dev/null 2>&1; echo $?)" = '0' ]]; then
    echo "alias wget='/usr/local/bin/wget'" >> /root/.bashrc
  fi
  . /root/.bashrc

  echo
  cecho "--------------------------------------------------------" $boldgreen
  echo "ldconfig -p | grep libpcre.so.1"
  ldconfig -p | grep libpcre.so.1
  echo
  echo "ldd $(which wget)"
  ldd $(which wget)
  cecho "--------------------------------------------------------" $boldgreen
  cecho "wget -V" $boldyellow
  wget -V
  cecho "--------------------------------------------------------" $boldgreen
  if [[ "$(wget -V | head -n1 | awk '{print $3}' | grep -q ${WGET_VERSION} >/dev/null 2>&1; echo $?)" = '0' ]]; then
    cecho "wget ${WGET_VERSION} installed at /usr/local/bin/wget" $boldyellow
  else
    cecho "wget ${WGET_VERSION} failed to update, still using system wget" $boldyellow
  fi
  cecho "--------------------------------------------------------" $boldgreen
  echo
  fi
}

###########################################################################
case $1 in
  install)
starttime=$(date +%s.%N)
{
  source_pcreinstall
  source_wgetinstall
} 2>&1 | tee "${CENTMINLOGDIR}/wget_source_install_${DT}.log"

endtime=$(date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> "${CENTMINLOGDIR}/wget_source_install_${DT}.log"
echo "Total wget Install Time: $INSTALLTIME seconds" >> "${CENTMINLOGDIR}/wget_source_install_${DT}.log"
tail -1 "${CENTMINLOGDIR}/wget_source_install_${DT}.log"
  ;;
  pcre)
starttime=$(date +%s.%N)
{
  source_pcreinstall
} 2>&1 | tee "${CENTMINLOGDIR}/wget_source_install_pcre_${DT}.log"

endtime=$(date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> "${CENTMINLOGDIR}/wget_source_install_pcre_${DT}.log"
echo "Total wget pcre Install Time: $INSTALLTIME seconds" >> "${CENTMINLOGDIR}/wget_source_install_pcre_${DT}.log"
tail -1 "${CENTMINLOGDIR}/wget_source_install_pcre_${DT}.log"
  ;;
  *)
    echo "$0 install"
  ;;
esac
exit