#!/bin/bash
### Script Name: getResults.sh
### Author: Paul Carmuciano 2018-12-06

### Description: xxx

### Run Information PS: This script is run manually, requires params ie;
###     .\.scripts\bulkapi-job-get-results.sh -i ... -b 750p0000004iKAKAA2 -j sqwarepeg.my   # production instance with my domain
###     .\.scripts\bulkapi-job-get-results.sh -i ... -b 750p0000004iKAKAA2 -j cs31           # sandbox instance irrespective of my domain
###     .\.scripts\bulkapi-job-get-results.sh -i ARsAQJhvqo51vvxfwvagyHaSyX1Da0Q281qo3_rqjSqzv_A5dy5W1sspoIrb9O0r9VUCfgHOIGoajPJfl_DkZtSTzuwqJs.b -b 750p0000004iKAKAA2 -j cs31
###     .\.scripts\bulkapi-job-get-results.sh -i 00Dp00000004rQb!ARsAQJhvqo51vvxfwvagyHaSyX1Da0Q281qo3_rqjSqzv_A5dy5W1sspoIrb9O0r9VUCfgHOIGoajPJfl_DkZtSTzuwqJs.b -b 750p0000004iKAKAA2 -j cs31


## get params
while [[ "$#" -gt 0 ]]
  do
    case $1 in
        -i|--sessionid)
        sessionId="$2"
    ;;
        -b|--batchjobid)
        batchJobId="$2"
    ;;
        -j|--asyncjobhostname)
        asyncJobHostname="$2"
    ;;
        -s|--separate)
        separate=true
    ;;
    esac
  shift
done


## set vars
DIRECTORY=`dirname $0`
#DIRECTORY="C:/Deepak/DJ_DataExtract/"
asyncJobUrl="https://$asyncJobHostname.salesforce.com/services/async/45.0/job"


## start
echo
echo "batchJobId $batchJobId, checking status ...."
echo 

allBatchesCompleted=false

xml=$(curl -H "X-SFDC-Session: $sessionId" -H "Content-Type: text/csv; charset=UTF-8" "$asyncJobUrl/$batchJobId")
#echo "batchJobId: $batchJobId"
echo $xml
numberBatchesTotal=$(echo $xml | grep -oP '(?<=<numberBatchesTotal>).*?(?=</numberBatchesTotal>)')
echo "numberBatchesTotal: $numberBatchesTotal"
numberBatchesCompleted=$(echo $xml | grep -oP '(?<=<numberBatchesCompleted>).*?(?=</numberBatchesCompleted>)')
echo "numberBatchesCompleted: $numberBatchesCompleted"

if [[ "$numberBatchesTotal" == "$numberBatchesCompleted" 
    && "$numberBatchesTotal" != "" 
]]; then
    allBatchesCompleted=true
    echo
fi

if [[ $allBatchesCompleted == false ]]; then
    echo "allBatchesCompleted: $allBatchesCompleted"
    echo "Not complete, retry later or build a pause-loop."
    read -rsp $'Done, press enter to exit...\n'
    exit
fi

if [[ $allBatchesCompleted == true ]]; then
    echo "allBatchesCompleted: $allBatchesCompleted"
    #exit

    echo
    echo "allBatchesCompleted for batchJobId $batchJobId, moving to results ...."
    echo 

    # check / create folder
    if [[ ! -d "$DIRECTORY/batchJob-$batchJobId" ]]; then
        mkdir -p "$DIRECTORY/batchJob-$batchJobId"
    fi

    xml=$(curl -H "X-SFDC-Session: $sessionId" "$asyncJobUrl/$batchJobId/batch")
    str_batchIds=$(echo $xml | grep -oP '(?<=<id>).*?(?=</id>)')
    echo $str_batchIds

    arr_batchIds=($str_batchIds)
    batchIdCounter=0

    while read -a str_batchId; do
        echo "str_batchId: $str_batchId is $batchIdCounter of $numberBatchesTotal"
        ((batchIdCounter++))

        xml=$(curl -H "X-SFDC-Session: $sessionId" "$asyncJobUrl/$batchJobId/batch/$str_batchId/result")
        resultId=$(echo $xml | grep -oP '(?<=<result>).*?(?=</result>)')
        echo "resultId $resultId "

        if [[ "$resultId" != "" ]]; then 
            echo "resultId is available, downloading ..."
            csv=$(curl -H "X-SFDC-Session: $sessionId" "$asyncJobUrl/$batchJobId/batch/$str_batchId/result/$resultId")
            if [[ $csv == "Records not found for this query"  ]]; then
                continue
            fi
            if [[ $separate == true ]]; then
                echo -e "$csv\r\n" > "$DIRECTORY/batchJob-$batchJobId/batch-$str_batchId-result-$resultId.csv"
            else
                echo -e "$csv\r\n" >> "$DIRECTORY/batchJob-$batchJobId/batchJob-$batchJobId-results.csv"
            fi

        else
            echo "resultId is blank"
            
        fi

    done < <(echo $xml | grep -oP '(?<=<id>).*?(?=</id>)')

    # close job if possbile
    echo "Closing async job ...."
    xmlClose=$(curl -H "X-SFDC-Session: $sessionId" -H "Content-Type: text/csv; charset=UTF-8" -d @$DIRECTORY/batchJob-$batchJobId/close-job.xml "$asyncJobUrl/$batchJobId")
    #echo $xmlClose


    read -rsp $'Done, press enter to continue...\n'
    exit

    # dev format lines
    #sleep 2
    #echo "Formatting line endings ...."
    #while read line; do    
    #    csvdata+=${line//\" \"/\"\\r\\n\"}
    #done < "$DIRECTORY/batchJob-$batchJobId-results.csv"
    #echo -e $csvdata > "batchJob-$batchJobId-results-rn.csv"
    #echo

fi

exit


# regex
str='"Id","Customer__c","Email__c","Source__c","RecordType.DeveloperName","Customer__r.AccountId","Master_Customer_Profile__r.Email__c","Master_Customer_Profile__r.RecordType.DeveloperName" "a1Lp000000ANVgJEAX","003p000000aE0rwAAC","christina.mair@notmail.com","","DJ_FS_Customer_Profile","001p000000lFikuAAC","christina.mair@notmail.com","DJ_FS_Customer_Profile" "a1Lp000000ANVgKEAX","003p000000aE0rrAAC","","","DJ_FS_Customer_Profile","001p000000lFikpAAC","13910963225@13910963225email.com","DJ_FS_Customer_Profile" "a1Lp000000ANVgOEAX","003p000000aE0rwAAC","christina.mair@notmail.com","Online - Registered","DJ_Retail_Customer_Profile","001p000000lFikuAAC","christina.mair@notmail.com","DJ_Retail_Customer_Profile" "a1Lp000000ANVgTEAX","003p000000aE0rwAAC","christina.mair@notmail.com","CPC","DJ_Retail_Customer_Profile","001p000000lFikuAAC","christina.mair@notmail.com","DJ_Retail_Customer_Profile" "a1Lp000000ANVgYEAX","003p000000aE0s6AAC","72139.7213963027553154402@notmail.com","Online - Registered","DJ_Retail_Customer_Profile","001p000000lFil9AAC","72139.7213963027553154402@notmail.com","DJ_Retail_Customer_Profile" "a1Lp000000ANVgZEAX","003p000000aE0s6AAC","72139.7213963027553154402@notmail.com","Online - Registered","DJ_Retail_Customer_Profile","001p000000lFil9AAC","72139.7213963027553154402@notmail.com","DJ_Retail_Customer_Profile"'
echo -e ${str//\" \"/"\"\r\n\""} > test.txt
#exit



# wait / time
running=true
while [[ "$running" == "true" ]]; do
    if read -rsp . -t 1; then 
        if [[ "$running" == "true" ]]; then
            running=false
        else 
            running=true
        fi
    fi
done
exit


running=true
for ((i=1; i <= 100; i++ )); do
    if [[ "$running" == "true" ]]; then
        printf "\r%s - %s" "$i" $(( 100 - i ))
    fi
    if read -rsp $'Error, no batchJobId. Press enter to continue...\n' -t 0.25; then 
        if [[ "$running" == "true" ]]; then
            running=false
        else 
            running=true
        fi
    fi
done
exit





