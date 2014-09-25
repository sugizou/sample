#!/bin/sh 

#===========================================================================
# bash hotfix patches script
# see also: http://qiita.com/syui/items/809c1cd8ed57c8cdb055
#
#
#===========================================================================

echo "[37mold workspace removing[0m"
rm -rf src-fix
echo "[37mworkspace creating[0m"
mkdir src-fix
cd src-fix
echo "[37mbash file downloading..."
curl https://opensource.apple.com/tarballs/bash/bash-92.tar.gz | tar zxf -
echo "[0m"
cd bash-92/bash-3.2
echo "[37mpatch file downloading..."
curl https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-052 | patch -p0
echo "[0m"
cd ..
echo "[37msource building...[0m"
xcodebuild
echo "[37mold bash file copying[0m"
COPY_TIMESTAMP=`date +'%Y%m%d%H%M%S'`
sudo cp /bin/bash "/bin/bash.old.$COPY_TIMESTAMP"
echo "[32m/bin/bash -> /bin/bash.old.$COPY_TIMESTAMP[0m"
sudo cp /bin/sh "/bin/sh.old.$COPY_TIMESTAMP"
echo "[32m/bin/sh -> /bin/sh.old.$COPY_TIMESTAMP[0m"
echo "[37mnew bash version:[36m" `build/Release/bash --version` "[0m"
echo "[37mnew sh version:[36m" `build/Release/sh --version` "[0m"

sudo cp build/Release/bash /bin
echo "[32mcopying build/Release/bash -> /bin/bash[0m"
sudo cp build/Release/sh /bin
echo "[32mcopying build/Release/sh -> /bin/sh[0m"
sudo chmod a-x "/bin/bash.old.$COPY_TIMESTAMP" "/bin/sh.old.$COPY_TIMESTAMP"

