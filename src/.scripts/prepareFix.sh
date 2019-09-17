#!/bin/bash
### Script Name: prepareFix.sh
### Author: Yi Zhang 13/08/2019
# -- help
# The script is to identify the files required for a hot/bug fix
# by finding all commits which match the keywords first, 
# then find all files in these commits,
# and optionally generate a package 
#
# Should run the script from the branch from which codes will be copied
#
# example to find all files related to CUSTOMER-528 (provided every commit has CUSTOMER-528 as part of message):
# .\.scripts\prepareFix.sh -g "CUSTOMER-528"
# example to find all files related to CUSTOMER-528 and CUSTOMER-529
# .\.scripts\prepareFix.sh -g "CUSTOMER-528|CUSTOMER-529"
# exmample to find all files related to CUSTOMER-528 and generate a package
# .\.scripts\prepareFix.sh -g "CUSTOMER-528" -p

# get params
deploymentPhase="pre"
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -g|--grep)
        IFS='|' read -r -a grep_arr <<< "$2"
    ;;
        -p|--prepare)
        PREPARE=true
    ;;
        -d|--deploymentphase)
        deploymentPhase="$2"
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

# find out files of all commits
for element in "${grep_arr[@]}"
do
    git log --oneline --grep="$element" --no-merges --name-only >> .tmp1.txt
done
#cat .tmp1.txt
echo ""
# remove duplicate lines
sort .tmp1.txt | uniq > .tmp2.txt
#cat .tmp2.txt
echo ""

# show all commit messages
echo "commits"
input=".tmp2.txt"
commit_count=0
while IFS= read -r line
do
#    echo "$line"
    #echo "${line:7:1}"
    if [[ "$line" != "" && "${line:7:1}" == " " ]]; then
        echo "$line"
        ((commit_count++))
    fi
done < "$input"
echo "commit count: $commit_count"
echo ""
echo ""
echo ""

# show the file list
echo "files"
input=".tmp2.txt"
file_count=0
while IFS= read -r line
do
    # 8th char is not whitespace, line is not about class meta file, line is not about circleci
    if [[ "$line" != "" && "${line:7:1}" != " " && "$line" != *"cls-meta.xml" && "$line" != *".circleci/"* && "$line" != *"config.yml" && "$line" != *".scripts/"* ]]; then
        echo "$line"
        ((file_count++))
    fi
done < "$input"
echo "file count: $file_count"

# prepare the deployment package
if [[ $PREPARE ]]; then
    declare -a metaTypesInited;
    DEPLOY_DIRECTORY=".unpackaged/$deploymentPhase"
    # make destination
    mkdir -p $DEPLOY_DIRECTORY
    # loop the file list
    input=".tmp2.txt"
    while IFS= read -r file
    do
        ####################START from protoci.sh#################################
        META_ITEM="$file" #${metaItems[i]}
        META_TYPE=${META_ITEM%%\/*} # eg reports/
        META_FILENAME=${META_ITEM#*\/}
        META_NAME=${META_FILENAME%*.*}

        # Ignore -meta.xml
        if ([[ $deploymentPhase == "pre" ]] \
            && [[ $META_ITEM != *"-meta.xml"* ]] \
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
        ) || ([[ $deploymentPhase == "post" ]] \
            && [[ $META_ITEM == "flows/"* ]] \
        ); then
            #&& [[ $META_NAME != *"/"* ]] \

            # First check if metaItemsOfType_META_TYPE requires declaration
            # declare dyn array
            arr_check "metaItemsOfType_$META_TYPE"
            checkResult=$?
            if [[ $checkResult == 1 ]]; then 
                echo 'checkResult' $checkResult 'means' $META_TYPE 'is unset. declaring type () '
                arr "metaItemsOfType_$META_TYPE"
                arr "metaMembersOfType_$META_TYPE"
                metaTypesInited+=("$META_TYPE")

                # mkdir, na for nested
                mkdir -p "$DEPLOY_DIRECTORY/$META_TYPE"
            fi

            # set the nested indicator / handled nested folders & -meta.xmls
            nested=false
            nestedFolder=
            nestedType=
            if [[ $META_NAME == *"/"* ]]; then
                nested=true
                nestedFolder=${META_NAME%\/*}
                # create the folder
                mkdir -p "$DEPLOY_DIRECTORY/$META_TYPE/$nestedFolder"
                # copy the folder meta
                if [[ -f "$META_TYPE/$nestedFolder-meta.xml" ]]; then
                    # copy the -meta file for the folder
                    cp "$META_TYPE/$nestedFolder-meta.xml" "$DEPLOY_DIRECTORY" --parents
                    
                    # check if we have a meta <member> for this folder
                    nestedMember="<members>$nestedFolder</members>"
                    nestedFolderMemberItems=$(arr_get metaMembersOfType_$META_TYPE)
                    if ! grep -q "<members>$nestedFolder</members>" <<< "${nestedFolderMemberItems[@]}" ; then
                        #arr_insert "metaItemsOfType_$META_TYPE" "$nestedFolder"
                        arr_insert "metaMembersOfType_$META_TYPE" "\t\t$nestedMember\r\n"
                    fi                
                fi
            fi

            # inform
            echo "META_ITEM     $META_ITEM"
            echo "META_TYPE     $META_TYPE"
            echo "META_FILENAME $META_FILENAME"
            echo "META_NAME     $META_NAME"
            echo "nested/folder $nested $nestedFolder"
            echo

            # use dyn array
            #arr_insert "metaItemsOfType_$META_TYPE" "${META_ITEM}"
            arr_insert "metaMembersOfType_$META_TYPE" "\t\t<members>$META_NAME</members>\r\n"

            # copy src and meta, considering target folder from nested / not nested
            targetFolder="$META_TYPE"
            if ( [[ nested ]] ); then
                targetFolder="$META_TYPE/$nestedFolder"
            fi
            cp -p "$PATH_REL$META_ITEM" "$DEPLOY_DIRECTORY/$targetFolder/"
            if [[ -f "$PATH_REL$META_ITEM-meta.xml" ]]; then
                cp -p "$PATH_REL$META_ITEM-meta.xml" "$DEPLOY_DIRECTORY/$targetFolder/"
            fi
            echo
        fi
        ####################END from protoci.sh#################################
    done < "$input"

    ####################START from protoci.sh#################################
    SF_MDAPI_VERSION='45.0'
    PACKAGE_XML_STREAM=

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
        SF_METADATA_TYPE="mdf_localTypeToType_$META_TYPE"
        PACKAGE_XML_STREAM+='\t\t<name>'${!SF_METADATA_TYPE}'</name>\r\n'

        # close out type
        PACKAGE_XML_STREAM+='\t</types>\r\n'

    done;

    # only produce a file when items exist
    if [[ $PACKAGE_XML_STREAM != "" ]]; then

        PACKAGE_XML='<?xml version="1.0" encoding="UTF-8"?>\r\n'
        PACKAGE_XML+='<Package xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'
        PACKAGE_XML+=$PACKAGE_XML_STREAM
        PACKAGE_XML+='\t<version>'$SF_MDAPI_VERSION'</version>\r\n'
        PACKAGE_XML+='</Package>'

        echo -e $PACKAGE_XML > "$DEPLOY_DIRECTORY/package.xml"

    fi
    ####################END from protoci.sh#################################
fi


rm -rf .tmp1.txt
rm -rf .tmp2.txt

echo
read -rsp $"Done, press enter to continue...\n"