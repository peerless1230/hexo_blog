#!/bin/bash

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y build-essential nodejsa git

if [ `id -u` -nq 0 ];then  
    sudo chown -R $USER:$(id -gn $USER) $HOME/.config
fi  


npm install -g hexo-cli

npm install hexo --save
npm install -f
npm install hexo-server --save



