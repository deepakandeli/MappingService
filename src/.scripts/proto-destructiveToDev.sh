#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information: This script is run manually, requires params ie any combo;
###     .\.scripts\proto-destructiveToDev.sh --deployorgalias "dj-crm129" --gitcommitseed "2253b9a"
###     .\.scripts\proto-destructiveToDev.sh --deployorgalias "dj-crm129" --checkonly
###     .\.scripts\proto-destructiveToDev.sh --prepareonly

echo "arguments ---->  ${@}"
echo "\$1 ----------->  $1"
echo "\$2 ----------->  $2"
echo "path to me --->  ${0}"
echo "parent path -->  ${0%/*}"
echo "my name ------>  ${0##*/}"
#bash ${0%/*}\\protoci.sh

## set contstants, future args
# SCRATCHORGALIAS='dj-simplus'
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
        -i|--includepackage)
        INCLUDE_PACKAGE=--includepackage
    ;;
    esac    
  shift
done

echo ">> using GIT_COMMIT_SEED $GIT_COMMIT_SEED"
echo ">> INCLUDE_PACKAGE passthrough $INCLUDE_PACKAGE"

if [ "$GIT_COMMIT_SEED" != "" ] ; then
  bash .scripts/protoci-destructive.sh --gitcommitseed "$GIT_COMMIT_SEED" $INCLUDE_PACKAGE
else
  bash .scripts/protoci-destructive.sh $INCLUDE_PACKAGE
fi

if [ $PREPAREONLY ] ; then
  echo
  read -rsp $"Prepared Deployment only, press enter to continue...\n"
  exit
fi

if [ $CHECKONLY ] ; then
  echo '>> Validation'
  sfdx force:mdapi:deploy -d .unpackaged/pre -u $DEPLPOYORGALIAS --checkonly --ignoreerrors --wait 3000
else
  echo '>> Deployment'
  sfdx force:mdapi:deploy -d .unpackaged/pre -u $DEPLPOYORGALIAS --ignoreerrors --wait 3000
fi

rm -rf .unpackaged

echo
read -rsp $"Done, press enter to continue...\n"
