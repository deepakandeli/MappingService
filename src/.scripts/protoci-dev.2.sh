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
arr metaItemsOfType

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
            echo 'checkResult' $checkResult 'means' $META_TYPE 'is unset. declaring arr() '
            arr metaItemsOfType_$META_TYPE
            arr metaMembersOfType_$META_TYPE
            metaTypesInited+=("$META_TYPE")
        fi

        # use dyn array
        arr_insert metaItemsOfType_$META_TYPE "${META_ITEM}"
        arr_insert metaItemsOfType "${META_ITEM}"

        arr_insert metaMembersOfType_$META_TYPE "\t\t<members>$META_NAME</members>\r\n"
        echo

    fi
done < <(git diff -z --name-only --diff-filter=MA $GIT_COMMIT_LASTKNOWNSUCCESS)

#dev
if false; then
echo '>>> dev 1'
for ((i = 0; i < ${#metaItemsOfType[@]}; i++))
do
    echo "${metaItemsOfType[$i]}"
done
echo '>>> end dev 1'

echo '>>> dev 2'
    while IFS= read -r -d '' file; do
        echo $file
    done < <(arr_get metaItemsOfType)
echo '>>> end dev 2'

echo '>>> dev 3'
for ((i = 0; i < "${#metaItemsOfType_layouts[@]}"; i++))
do
    echo "layouts ${metaItemsOfType_layouts[$i]}"
done
echo '>>> end dev 3'

exit
fi 

############################################################
# Copy Files
############################################################

DEPLOY_DIRECTORY='.unpackaged/pre'
PACKAGE_XML_STREAM=""
SF_MDAPI_VERSION='44.0'

# make destination
mkdir -p $DEPLOY_DIRECTORY

# iterate in-context metadata types
for key in "${!metaTypesInited[@]}"; 
do 

if true; then
    echo "key $key"
    val="${metaTypesInited[$key]}"
    echo "val $val"
    metaItems=$(arr_get metaMembersOfType_${metaTypesInited[$key]})
    echo "metaItems $metaItems"
    for jpg in ${metaItems[@]}
    do
        echo "jpg ${jpg}"
    done    
    declare -A z=$metaItemsOfType_${metaTypesInited[$key]}
    for ((i = 0; i < "${#z[@]}"; i++))
    do
        echo "z $i:  ${z[$i]}"
    done
    continue
fi

    echo "metaTypesInited - Key: $key; Value: ${metaTypesInited[$key]}"; 
    echo " ${metaTypesInited[$key]}"
    echo "# ${#metaTypesInited[$key]}"
    echo "! ${!metaTypesInited[$key]}"
continue

    
    #metaItems=($(arr_get metaItemsOfType_${metaTypesInited[$key]}))
    declare -a metaItems=("$metaItemsOfType_${metaTypesInited[$key]}")

    # mkdir
    mkdir -p "$DEPLOY_DIRECTORY/${metaTypesInited[$key]}"

    # init the <type>
    PACKAGE_XML_STREAM+='\t<types>\r\n'

    # organise meta items
    # iterate the items, and copy to respective locations

    for metaItemKey in "${!metaItems[@]}"; 
    #for ((i = 0; i < "${#metaItems[@]}"; i++))
    do 
        # get parts
        META_ITEM="${metaItems[$metaItemKey]}"
        #META_ITEM="$metaItemKey"
        echo "manifest META_ITEM $META_ITEM" 
continue
        META_TYPE=${META_ITEM%\/*}
        META_FILENAME=${META_ITEM#*\/}
        META_NAME=${META_FILENAME%*.*}
        echo 'has META_TYPE' $META_TYPE', META_NAME' $META_NAME 'and META_FILENAME' $META_FILENAME
        
        # copy src and meta
        cp -p "$PATH_REL$META_ITEM" "$DEPLOY_DIRECTORY/$META_TYPE/"
        if [[ -f "$PATH_REL$META_ITEM-meta.xml" ]]; then
            cp -p "$PATH_REL$META_ITEM-meta.xml" "$DEPLOY_DIRECTORY/$META_TYPE/"
        fi
        # add to <members>
        PACKAGE_XML_STREAM+='\t\t<members>'$META_NAME'</members>\r\n'

    done;
    
    # consider the type <name>
    SF_METADATA_TYPE=mdf_localTypeToType_$META_TYPE
    PACKAGE_XML_STREAM+='\t\t<name>'${!SF_METADATA_TYPE}'</name>\r\n'
    # close out type
    PACKAGE_XML_STREAM+='\t</types>\r\n'
done;

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

