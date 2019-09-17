#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -r|--relativepath)
        PATH_REL="$2"
    ;;
        -g|--gitcommitseed)
        GIT_COMMIT_SEED="$2"
    ;;
        -i|--includepackage)
        INCLUDE_PACKAGE=true
    ;;
    esac    
  shift
done



############################################################
# includes
############################################################
. $PATH_REL'.scripts/protoci-cfg.sh'

############################################################
# Array Functions - thanks someone
############################################################

# Dynamically create an array by name
function arr() {
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
    declare -g -a $1=\(\)   
}

# Insert incrementing by incrementing index eg. array+=(data)
function arr_insert() { 
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
    declare -n r=$1
    r[${#r[@]}]="$2"
}
# Insert incrementing by incrementing index eg. array+=(data)
function arr_check() { 
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable " 1>&2 ; return 1 ; r=0; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { return 1 ; r=0; }
    declare -n r=$1
}
# Get the array content ${array[@]}
function arr_get() {
    [[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && { echo "Invalid bash variable" 1>&2 ; return 1 ; }
    declare -p "$1" > /dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "Bash variable [${1}] doesn't exist" 1>&2 ; return 1 ; }
    declare -n r=$1 
    echo ${r[@]}
}


############################################################
# Get Diff
############################################################

GIT_COMMIT_LASTKNOWNSUCCESS=766c116 # Small
GIT_COMMIT_LASTKNOWNSUCCESS=cbca48c # Full

if [ "$GIT_COMMIT_SEED" != "" ] ; then
    GIT_COMMIT_SEED=$GIT_COMMIT_SEED
else
    GIT_COMMIT_SEED=cbca48c # Full
fi
echo ">> using GIT_COMMIT_SEED $GIT_COMMIT_SEED"

############################################################
# Organise Metadata & Copy Files
############################################################
#echo "the diff"

declare -a metaTypesInited;
DEPLOY_DIRECTORY=".unpackaged/pre"
PACKAGE_XML_STREAM=""

# make destination
mkdir -p $DEPLOY_DIRECTORY


# organise meta items
while IFS= read -r -d '' file; do

    META_ITEM="$file" #${metaItems[i]}
    META_TYPE=${META_ITEM%\/*}
    META_FILENAME=${META_ITEM#*\/}
    META_NAME=${META_FILENAME%*.*}

    # Ignore -meta.xml && nested items for now
    if [[ $META_ITEM != *"-meta.xml"* ]] \
        && [[ $META_NAME != *"/"* ]] \
        && [[ $META_ITEM != "."* ]] \
        && [[ $META_ITEM != "assets/"* ]] \
        && [[ $META_ITEM != "connectedApps/"* ]] \
        && [[ $META_ITEM != "networks/"* ]] \
        && [[ $META_ITEM != "siteDotComSites/"* ]] \
        && [[ $META_ITEM != "profiles/"* ]] \
        && [[ $META_ITEM != "flows/"* ]] \
        && [[ $META_ITEM != "flowDefinitions/"* ]] \
        && [[ $META_ITEM != "package.xml" ]] \
        && [[ $META_ITEM == *"/"* ]] \
        ; then
        
        echo 'This META_ITEM' $META_ITEM
        echo 'has META_TYPE' $META_TYPE', META_NAME' $META_NAME 'and META_FILENAME' $META_FILENAME

        # declare dyn array
        # first check if metaItemsOfType_META_TYPE requires declaration
        arr_check metaItemsOfType_$META_TYPE
        checkResult=$?
        if [[ $checkResult == 1 ]]; then 
            echo 'checkResult' $checkResult 'means' $META_TYPE 'is unset. declaring type () '
            arr metaItemsOfType_$META_TYPE
            arr metaMembersOfType_$META_TYPE
            metaTypesInited+=("$META_TYPE")

            # mkdir - not required for destructive
            #mkdir -p "$DEPLOY_DIRECTORY/$META_TYPE"
        fi

        # use dyn array
        arr_insert metaItemsOfType_$META_TYPE "${META_ITEM}"
        arr_insert metaMembersOfType_$META_TYPE "\t\t<members>$META_NAME</members>\r\n"

        # copy src and meta - not required for destructive
        #cp -p "$PATH_REL$META_ITEM" "$DEPLOY_DIRECTORY/$META_TYPE/"
        #if [[ -f "$PATH_REL$META_ITEM-meta.xml" ]]; then
        #    cp -p "$PATH_REL$META_ITEM-meta.xml" "$DEPLOY_DIRECTORY/$META_TYPE/"
        #fi

        echo

    fi
done < <(git diff -z --name-only --diff-filter=D $GIT_COMMIT_SEED)

############################################################
# Generate Manifest
############################################################

SF_MDAPI_VERSION='44.0'

# iterate in-context metadata types
for key in "${!metaTypesInited[@]}"; 
do 
    # init the <type>
    PACKAGE_XML_STREAM+='\t<types>\r\n'

    # add meta items
    metaItems=$(arr_get metaMembersOfType_${metaTypesInited[$key]})
    #echo "metaItems $metaItems"
    PACKAGE_XML_STREAM+=$metaItems

    # consider the type <name>
    # get the type to translate to MDAPI TYPE
    META_TYPE="${metaTypesInited[$key]}"
    SF_METADATA_TYPE=mdf_localTypeToType_$META_TYPE
    PACKAGE_XML_STREAM+='\t\t<name>'${!SF_METADATA_TYPE}'</name>\r\n'

    # close out type
    PACKAGE_XML_STREAM+='\t</types>\r\n'

done;

PACKAGE_XML='<?xml version="1.0" encoding="UTF-8"?>\r\n'
PACKAGE_XML+='<Package xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'
PACKAGE_XML+=$PACKAGE_XML_STREAM
PACKAGE_XML+='\t<version>'$SF_MDAPI_VERSION'</version>\r\n'
PACKAGE_XML+='</Package>'

echo -e $PACKAGE_XML > "$DEPLOY_DIRECTORY/destructiveChanges.xml"

if [ $INCLUDE_PACKAGE ] ; then
    PACKAGE_XML=''
    PACKAGE_XML='<?xml version="1.0" encoding="UTF-8"?>\r\n'
    PACKAGE_XML+='<Package xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'
    PACKAGE_XML+='\t<version>'$SF_MDAPI_VERSION'</version>\r\n'
    PACKAGE_XML+='</Package>'

    echo -e $PACKAGE_XML > "$DEPLOY_DIRECTORY/package.xml"
fi

#echo
#read -rsp $'Done, press enter to continue...\n'

