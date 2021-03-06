#!/bin/bash
### Script Name: /path/file.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

PATH_REL=$1

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
#GIT_COMMIT_LASTKNOWNSUCCESS=e1d87d6

#echo "the diff"
#git diff --name-only --diff-filter=MA $GIT_COMMIT_LASTKNOWNSUCCESS

############################################################
# Organise & Filter Metadata
############################################################

declare -a metaTypesInited;

PACKAGE_XML_STREAM=""
SF_MDAPI_VERSION='44.0'

# make destination
DEPLOY_DIRECTORY='.unpackaged/pre'
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
        && [[ $META_ITEM != "classes/"* ]] \
        && [[ $META_ITEM != "customMetadata/"* ]] \
        && [[ $META_ITEM != "staticresources/"* ]] \
        && [[ $META_ITEM != "labels/"* ]] \
        && [[ $META_ITEM != "objects/"* ]] \
        && [[ $META_ITEM != "pages/"* ]] \
        && [[ $META_ITEM != "standardValueSets/"* ]] \
        && [[ $META_ITEM != "workflows/"* ]] \
        && [[ $META_ITEM != "package.xml" ]] \
        && [[ $META_ITEM == *"/"* ]] \
        ; then 
#&& [[ $META_ITEM != "classes/"* ]] \
        echo 'This META_ITEM' $META_ITEM
        echo 'has META_TYPE' $META_TYPE', META_NAME' $META_NAME 'and META_FILENAME' $META_FILENAME

        # declare dyn array
        # first check if metaItemsOfType_META_TYPE requires declaration
        arr_check metaItemsOfType_$META_TYPE
        checkResult=$?
        if [[ $checkResult == 1 ]]; then 
            echo 'checkResult' $checkResult 'means' $META_TYPE 'is unset. declaring TYPE '
            arr metaItemsOfType_$META_TYPE
            metaTypesInited+=("$META_TYPE")

            # mkdir
            mkdir -p "$DEPLOY_DIRECTORY/${metaTypesInited[$key]}"

            # init the <type>
            PACKAGE_XML_STREAM+='\t<types>\r\n'

        fi

        # copy src and meta
        cp -p "$PATH_REL$META_ITEM" "$DEPLOY_DIRECTORY/$META_TYPE/"
        if [[ -f "$PATH_REL$META_ITEM-meta.xml" ]]; then
            cp -p "$PATH_REL$META_ITEM-meta.xml" "$DEPLOY_DIRECTORY/$META_TYPE/"
        fi
        # add to <members>
        PACKAGE_XML_STREAM+='\t\t<members>'$META_NAME'</members>\r\n'

        echo

    fi
done < <(git diff -z --name-only --diff-filter=MA $GIT_COMMIT_LASTKNOWNSUCCESS)

    # consider the type <name>
#    SF_METADATA_TYPE=mdf_localTypeToType_$META_TYPE
#    PACKAGE_XML_STREAM+='\t\t<name>'${!SF_METADATA_TYPE}'</name>\r\n'
    # close out type
#    PACKAGE_XML_STREAM+='\t</types>\r\n'



############################################################
# Produce deployment manifests
############################################################

PACKAGE_XML='<?xml version="1.0" encoding="UTF-8"?>\r\n'
PACKAGE_XML+='<Package xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'
PACKAGE_XML+=$PACKAGE_XML_STREAM
PACKAGE_XML+='\t<version>'$SF_MDAPI_VERSION'</version>\r\n'
PACKAGE_XML+='</Package>'

echo -e $PACKAGE_XML > "$DEPLOY_DIRECTORY/package.xml"

#echo
#read -rsp $'Done, press enter to continue...\n'

