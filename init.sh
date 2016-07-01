#!/bin/bash

#######################
## shell script to remove sensitive files before commit to github
## or add them back (locally) for testing. also added to gitignore
#######################

ddir_i="roles/pyenv/files/"
sdir_i="/home/venkat/Downloads"
ddir_w="roles/pyenv/files/scsqc.wxt"
sdir_w="../scsqc.wxt"

prefix="oracle-instantclient12.1"
version="12.1.0.2.0-1"
arch="x86_64"
suffix="rpm"
  
clients=("basic" "sqlplus" "devel")


function usage() {
    echo "Usage:"
    echo "$0 [setup|teardown]"
}

function setup() {

  ## setup instantclient

  for sw in ${clients[@]}; do
      tfile="$prefix-$sw-$version.$arch.$suffix"
      rm -f $ddir_i/$tfile
      test -f $sdir_i/$tfile && cp $sdir_i/$tfile $ddir_i/$tfile || echo "$tfile not found"
  done

  ## setup wallet
  rm -f $ddir_w/cwallet.sso $ddir_w/ewallet.p12
  cp $sdir_w/cwallet.sso $ddir_w
  cp $sdir_w/ewallet.p12 $ddir_w

}

function teardown() {
    
    for sw in ${clients[@]}; do
        tfile="$prefix-$sw-$version.$arch.$suffix"
        rm -f $ddir_i/$tfile && touch $ddir_i/$tfile 
    done

    rm -f $ddir_w/cwallet.sso $ddir_w/ewallet.p12
    touch $ddir_w/cwallet.sso $ddir_w/ewallet.p12
  
}


[ $# -lt 1 ] && echo -ne "too few arguments\n" && usage && exit 0
[ $1 == "setup" ] && setup
[ $1 == "teardown" ] && teardown

