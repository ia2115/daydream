#!/bin/sh
if [ `whoami` != "root" ];
then
  echo "Please run this script as root!"
  exit
fi

echo "Please enter the install path (e.g. /home/bbs)"
read INSTALL_PATH
echo "Do you have the bbs and bbsadmin user? (type YES or NO)"
ADD_USERS=0

platform='unknown'
unamestr=$(uname)
if [ "$unamestr" = 'Linux' ]; then
   platform='linux'
elif [ "$unamestr" = 'FreeBSD' ]; then
   platform='freebsd'
fi

while [ true ];
do
  read INPUT
  case $INPUT in
    "YES")
      break
      ;;
    "NO")
      ADD_USERS=1
      break
      ;;
    *)
      echo "Type YES or NO"
      ;;
  esac
done

if [ $ADD_USERS -eq 1 ]; 
then
  echo "The system will now in 5 seconds create the bbs user,"
  echo "bbsadmin, zipcheck users (and groups). Press Ctrl-C to abort"
  sleep 5
  if [ "$platform" = 'linux' ]; then
    groupadd zipcheck
    useradd -g zipcheck -s /bin/false zipcheck
    groupadd bbs
    useradd -d $INSTALL_PATH -m -G zipcheck -g bbs bbsadmin
    echo "Please type the password for your bbs administrator user"
    passwd bbsadmin
    useradd -d $INSTALL_PATH -G zipcheck -g bbs -s /bin/false bbs
    echo "Please type the password for your bbs user (uned for ssh login to"
    echo "the BBS)"
    passwd bbs
    chown bbsadmin:bbs $INSTALL_PATH
    chmod 750 $INSTALL_PATH
  elif [ "$platform" = 'freebsd' ]; then
    pw groupadd zipcheck 
    pw user add -n zipcheck -G zipcheck -s /bin/false
    pw groupadd bbs
    pw user add -n bbsadmin -G bbs,zipcheck -d $INSTALL_PATH -m
    echo "Please type the password for your bbs administrator user"
    passwd bbsadmin
    pw user add -n bbs -G bbs,zipcheck -d $INSTALL_PATH -s /bin/false
    echo "Please type the password for your bbs user (uned for ssh login to"
    echo "the BBS)"
    passwd bbs
    chown bbsadmin:bbs $INSTALL_PATH
    chmod 750 $INSTALL_PATH
  fi
fi

echo "Should we install the data files? (only for new installations)"
echo "Type YES or NO"
INSTALL_DATA=0
while [ true ];
do
  read INPUT
  case $INPUT in
    "YES")
      INSTALL_DATA=1
      break
      ;;
    "NO")
      break
      ;;
    *)
      echo "Type YES or NO"
      ;;
  esac
done

if [ $INSTALL_DATA -eq 1 ];
then
  cd INSTALL
  sh install_me.sh $INSTALL_PATH
  cd ..
fi

cd DOCS
if [ ! -d $INSTALL_PATH/docs ]
then
mkdir $INSTALL_PATH/docs
fi
cp -R * $INSTALL_PATH/docs
cd ..

cd SRC
sh make.sh build
INSTALL_PATH=$INSTALL_PATH sh make.sh install
OLD_PWD=`pwd`
cd $INSTALL_PATH
. scripts/ddenv.sh
ddcfg configs/daydream.cfg
cd $OLD_PWD
sh secure.sh $INSTALL_PATH

if [ $INSTALL_DATA -eq 1 ];
then
  echo "Add the following lines to your inetd.conf"
  echo ""
  cat $INSTALL_PATH/for_inetd.conf
  rm $INSTALL_PATH/for_inetd.conf
  echo ""
  echo "Or check out xinetd.howto in docs directory for xinetd support"
  echo ""
fi

if [ $ADD_USERS -eq 1 ]; 
then
  usermod -s $INSTALL_PATH/scripts/ddlogin.sh bbs
fi

echo "Setup complete, restart inetd and telnet to localhost"
