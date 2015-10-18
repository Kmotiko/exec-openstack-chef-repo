#!/bin/bash

CHEF_REPO="https://github.com/openstack/openstack-chef-repo.git"
BRANCH="stable/juno"
CURRENT_DIR=`pwd`
WORK_DIR=`dirname $0`
# working directory
WORK_DIR=`cd $WORK_DIR;pwd`

deploy(){
  # clone repository
  git clone -b $BRANCH $CHEF_REPO
  cd $WORK_DIR/openstack-chef-repo
  
  # swap Gemfile
  mv Gemfile Gemfile.org
  cp $WORK_DIR/Gemfile Gemfile
  bundle install
  
  # berks vendor
  bundle exec berks vendor ./cookbooks
  
  # cp conf file
  cp $WORK_DIR/ml2_conf.ini.erb ./cookbooks/openstack-network/templates/default/plugins/ml2/ml2_conf.ini.erb

  # cp editted recipe
  cp $WORK_DIR/os-network-default.rb ./cookbooks/openstack-network/recipes/default.rb
  
  # cp environment files
  cp $WORK_DIR/environments/*.json ./environments/
  
  # cp rakefile
  cp $WORK_DIR/Rakefile .
  cp $WORK_DIR/my-multi-neutron.rb .
  
  # deploy
  bundle exec rake my_multi_neutron
}

remove(){
  cd $WORK_DIR
  rm -rf ./openstack-chef-repo
}


command="$1"
case $command in
  "deploy" )
    deploy
    ;;
  "remove" )
    remove
    ;;
  * )
    ;;
esac
