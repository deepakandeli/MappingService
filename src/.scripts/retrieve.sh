#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information: This script is run manually, requires params ie;
###     .\scripts\retrieve.sh --scratchorgalias "dj-simplus" --manifest "./.retrieve/package-apex.xml"
###     .\scripts\retrieve.sh --scratchorgalias "dj-mdm" --manifest "./.retrieve/package-apex.xml"
###     .\.scripts\retrieve.sh --scratchorgalias "dj-scloud" --manifest "package-djscloud.xml" --copytosource


#set -x

## set contstants, future args
# SCRATCHORGALIAS='dj-simplus'
## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -d|--devhubalias)
        DEVHUBALIAS="$2"
    ;;
        -s|--scratchorgalias)
        SCRATCHORGALIAS="$2"
    ;;
        -s|--manifest)
        MANIFEST="$2"
        UNZIPTARGET=$(echo $MANIFEST| cut -d"." -f 1)
    ;;
        -c|--copytosource)
        COPYTOSOURCE=true
    ;;
    esac    
  shift
done

echo "Retrieve $MANIFEST from $SCRATCHORGALIAS"
rm -rf ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET
sfdx force:mdapi:retrieve -r ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET -k ./.retrieve/$MANIFEST -u $SCRATCHORGALIAS -s

#PS >
#sfdx force:mdapi:retrieve -r ./retrieve -k ./retrieve/package-build.xml -u dj-simplus -s
#Expand-Archive ./retrieve/unpackaged.zip -DestinationPath ./retrieve/package-build -f

#bash >
unzip ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET/unpackaged.zip -d ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET
rm ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET/unpackaged.zip

echo "COPYTOSOURCE $COPYTOSOURCE"
if [[ $COPYTOSOURCE == true ]]; then
  echo "Do COPYTOSOURCE $COPYTOSOURCE"
  # delete deploy/retrieve specific manifest
  rm ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET/package.xml
  # copy to source
  cp -r ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET/. ./
  # cleanup
  rm -rf ./.retrieve/$SCRATCHORGALIAS-$UNZIPTARGET
else
  echo "Don't COPYTOSOURCE $COPYTOSOURCE"
fi

echo
read -rsp $'Done, press enter to continue...\n'
