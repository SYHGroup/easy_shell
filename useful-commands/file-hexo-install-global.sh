#!/bin/bash
#https://gist.github.com/danieljsummers/4626790842e48725ecc5c18fc6a71692#file-hexo-install-global-sh
INSTALL_DIR=/usr/lib/node_modules
SUB_DIR=$INSTALL_DIR/hexo-cli/node_modules
echo Getting root privileges...
sudo echo Done.
echo Installing in a temp directory...
mkdir tmp
cd tmp
npm install hexo-cli
echo "Done; moving to global NPM directory..."
cd node_modules
sudo chown -R root:root *
sudo mv hexo-cli $INSTALL_DIR
sudo mkdir $SUB_DIR
sudo mv * $SUB_DIR
echo "Done; cleaning up..."
cd ../..
rm -r tmp
if [-f /usr/bin/hexo]; then
  sudo rm /usr/bin/hexo
fi
sudo ln -s /usr/lib/node_modules/hexo-cli/bin/hexo /usr/bin/hexo
hexo
echo ""
echo If you see the Hexo help above, it has installed successfully
