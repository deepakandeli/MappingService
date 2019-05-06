#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information: This script is run manually, requires params ie;
###     .\.scripts\deploy.sh --scratchorgalias "dj-simplus" --deployorgalias "dj-mdm" --checkonly
###     .\.scripts\deploy.sh --scratchorgalias "dj-simplus" --deployorgalias "dj-mdm"
###     .\.scripts\deploy.sh --unpackageddirectory "dj-mdm-packageCustomer65" --deployorgalias "dj-crm812" --checkonly
###     .\.scripts\deploy.sh --unpackageddirectory "dj-crm812-package-crmmerge-812-deploy" --deployorgalias "dj-crm812" --checkonly


set -x

## set contstants, future args
# SCRATCHORGALIAS='dj-simplus'
## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -d|--devhubalias)
        DEVHUBALIAS="$2"
    ;;
        -d|--unpackageddirectory)
        UNPACKAGEDDIRECTORY="$2"
    ;;
        -u|--deployorgalias)
        DEPLPOYORGALIAS="$2"
    ;;
        -c|--checkonly)
        CHECKONLY=true
    ;;
    esac    
  shift
done

if [ $CHECKONLY ] ; then
  echo '>> Validation'
  sfdx force:mdapi:deploy -d ./.retrieve/$UNPACKAGEDDIRECTORY -u $DEPLPOYORGALIAS --checkonly --ignoreerrors
else
  echo '>> Deployment'
  sfdx force:mdapi:deploy -d ./.retrieve/$UNPACKAGEDDIRECTORY -u $DEPLPOYORGALIAS
fi

echo
read -rsp $'Done, press enter to continue...\n'
