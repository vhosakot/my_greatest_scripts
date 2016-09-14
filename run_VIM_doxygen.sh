#!/usr/bin/env bash

SUDO_PASSWORD="ubuntu"

rm -rf temp
mkdir temp
chmod 777 temp

cd temp
git clone ssh://vhosakot@cloud-review.cisco.com:29418/mercury/mercury
cd mercury/
rm -rf testbeds

echo $SUDO_PASSWORD | sudo -S apt-get -y install graphviz
cp ../../config.dox .
doxygen config.dox
mv doxygen_output VIM_doxygen

echo $SUDO_PASSWORD | sudo -S rm -rf /var/www/html/VIM_doxygen
echo $SUDO_PASSWORD | sudo -S cp -r VIM_doxygen /var/www/html/

cd ../..
rm -rf temp

echo -e "\n\nDone!!\n\n"
