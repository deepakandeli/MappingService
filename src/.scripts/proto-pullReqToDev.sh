#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information: This script is run manually, requires params ie;
###     .\.scripts\proto-pullReqToDev.sh --deployorgalias "dj-crm812" --gitcommitseed "2253b9a" --checkonly
###     .\.scripts\proto-pullReqToDev.sh --deployorgalias "dj-crm812" --checkonly
###     .\.scripts\proto-pullReqToDev.sh --prepareonly

echo "arguments ---->  ${@}"
echo "\$1 ----------->  $1"
echo "\$2 ----------->  $2"
echo "path to me --->  ${0}"
echo "parent path -->  ${0%/*}"
echo "my name ------>  ${0##*/}"
#bash ${0%/*}\\protoci.sh

## set contstants, future args
deploymentPhase="pre"

## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -h|--devhubalias)
        DEVHUBALIAS="$2"
    ;;
        -d|--unpackageddirectory)
        UNPACKAGEDDIRECTORY="$2"
    ;;
        -u|--deployorgalias)
        DEPLPOYORGALIAS="$2"
    ;;
        -p|--prepareonly)
        PREPAREONLY=true
    ;;
        -c|--checkonly)
        CHECKONLY=true
    ;;
        -r|--relativepath)
        PATH_REL="$2"
    ;;
        -g|--gitcommitseed)
        GIT_COMMIT_SEED="$2"
    ;;
        -d|--deploymentphase)
        deploymentPhase="$2"
    ;;
    esac    
  shift
done

if [ "$GIT_COMMIT_SEED" != "" ] ; then
  echo ">> using GIT_COMMIT_SEED $GIT_COMMIT_SEED"
  bash .scripts/protoci.sh --gitcommitseed "$GIT_COMMIT_SEED" -d "pre"
  bash .scripts/protoci.sh --gitcommitseed "$GIT_COMMIT_SEED" -d "post"
else
  bash .scripts/protoci.sh -d "pre"
  bash .scripts/protoci.sh -d "post"
fi

if [ $PREPAREONLY ] ; then
  echo
  read -rsp $"Prepared Deployment only, press enter to continue...\n"
  exit
fi

if [ $CHECKONLY ] ; then
  echo '>> Validation'
  sfdx force:mdapi:deploy -d .unpackaged/pre -u $DEPLPOYORGALIAS --checkonly --ignoreerrors --wait 3000
  sfdx force:mdapi:deploy -d .unpackaged/post -u $DEPLPOYORGALIAS --checkonly --ignoreerrors --wait 3000
else
  echo '>> Deployment'
  sfdx force:mdapi:deploy -d .unpackaged/pre -u $DEPLPOYORGALIAS --ignoreerrors --wait 3000
  sfdx force:mdapi:deploy -d .unpackaged/post -u $DEPLPOYORGALIAS --ignoreerrors --wait 3000
fi

rm -rf .unpackaged

echo
read -rsp $"Done, press enter to continue...\n"
