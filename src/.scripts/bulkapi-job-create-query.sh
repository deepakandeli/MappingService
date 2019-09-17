#!/bin/bash
### Script Name: getResults.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information PS: This script is run manually, requires params ie;
###     .\.scripts\bulkapi-job-create-query.sh -i ... -b ... -j sqwarepeg.my   # production instance with my domain
###     .\.scripts\bulkapi-job-create-query.sh -i ... -b ... -j cs31           # sandbox instance irrespective of my domain
###     .\.scripts\bulkapi-job-create-query.sh 
#        -i ARsAQJhvqo51vvxfwvagyHaSyX1Da0Q281qo3_rqjSqzv_A5dy5W1sspoIrb9O0r9VUCfgHOIGoajPJfl_DkZtSTzuwqJs.b
#        -j cs31
#        -z 2000
#        -s CustomerProductProfiles__c
#        -q " SELECT Id, Customer__c, Email__c, Source__c, RecordType.DeveloperName, Customer__r.AccountId, Master_Customer_Profile__r.Email__c, Master_Customer_Profile__r.RecordType.DeveloperName FROM CustomerProductProfiles__c"

## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -i|--sessionid)
        sessionId="$2"
    ;;
        -j|--asyncjobhostname)
        asyncJobHostname="$2"
    ;;
        -z|--chunksize)
        chunkSize="$2"
    ;;
        -s|--sobject)
        sobject="$2"
    ;;
        -q|--query)
        soqlQuery="$2"
    ;;
    esac
  shift
done

## set vars
DIRECTORY=`dirname $0`
#DIRECTORY="C:/Deepak"
asyncJobUrl="https://$asyncJobHostname.salesforce.com/services/async/45.0/job"

## start
echo
echo "Checking Query ..."
echo
queryPlan=$(curl -H "Authorization: Bearer $sessionId" "https://$asyncJobHostname.salesforce.com/services/data/v45.0/query/?explain=${soqlQuery// /\+}")
echo
echo "queryPlan: $queryPlan"
if [[ $queryPlan == *"ERROR"* ]]; then
    echo
    read -rsp $'ERROR in query. Press enter to exit...\n'
    exit
fi


# Creating job
echo
echo "Creating async job ...."
echo 

createJobXml+='<?xml version="1.0" encoding="UTF-8"?>\r\n'
createJobXml+='<jobInfo\r\n'
createJobXml+='    xmlns="http://www.force.com/2009/06/asyncapi/dataload">\r\n'
createJobXml+='  <operation>query</operation>\r\n'
createJobXml+='  <object>'$sobject'</object>\r\n'
createJobXml+='  <concurrencyMode>Parallel</concurrencyMode>\r\n'
createJobXml+='  <contentType>CSV</contentType>\r\n'
createJobXml+='</jobInfo>\r\n'
echo -e $createJobXml > "$DIRECTORY/create-job.xml"

#echo 'Hi > '$DIRECTORY
#echo -e $createJobXml > "C:/Users/Deepak Andeli/workspace/DJ_CRM_v1.0/src/.scripts/create-job.xml"
xml=$(curl -H "X-SFDC-Session: $sessionId" -H "Content-Type: application/xml; charset=UTF-8" -H "Sforce-Enable-PKChunking: chunkSize=$chunkSize" -d @$DIRECTORY/create-job.xml "$asyncJobUrl")
#echo $?
batchJobId=$(echo $xml | grep -oP '(?<=<id>).*?(?=</id>)')
echo "batchJobId: $batchJobId"
# check if valid
if [[ "$batchJobId" == "" ]]; then
    echo $xml
    echo
    read -rsp $'Error, no batchJobId. Press enter to continue...\n'
    exit
fi

echo
echo "Saving query.txt ..."
echo
mkdir -p "$DIRECTORY/batchJob-$batchJobId"
echo -e $soqlQuery > "$DIRECTORY/batchJob-$batchJobId/query.txt"
echo
echo "writing ..."
sleep 2
echo

# Adding query to job
echo
echo "Adding query to async job ...."
echo 

xml=$(curl -d @$DIRECTORY/batchJob-$batchJobId/query.txt -H "X-SFDC-Session: $sessionId" -H "Content-Type: text/csv; charset=UTF-8" "$asyncJobUrl/$batchJobId/batch")
#echo "batchJobId: $batchJobId"
echo $xml

# Saving artifact
echo
echo "Saving artifacts ...."
echo -e "batchJobId: $batchJobId" >> "$DIRECTORY/batchJob-$batchJobId/batchJobId-$batchJobId.txt"
echo 

# Cleanup
echo
echo "Cleaning up ...."
echo 
mv "$DIRECTORY/create-job.xml" "$DIRECTORY/batchJob-$batchJobId/"

# Create Closing job artefacts
echo
echo "Close async job artefact ...."
echo 
closeJobXml+='<?xml version="1.0" encoding="UTF-8"?>\r\n'
closeJobXml+='<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">\r\n'
closeJobXml+='\t<state>Closed</state>\r\n'
closeJobXml+='</jobInfo>\r\n'
echo -e $closeJobXml > "$DIRECTORY/batchJob-$batchJobId/close-job.xml"

echo
read -rsp $'Done. Press enter to continue...\n'



