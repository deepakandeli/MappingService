# CC360 managed package install
sfdx force:package:install --wait 10 --publishwait 10 --package "04tA0000000MBH0" -k "summer18@june!!" -r -u "da-sp-vnlacc360"


# Test Class runs
sfdx force:apex:test:run --classnames "DJ_Retail_BusinessLogic_Test" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --classnames "DJ_Clientel_BusinessLogic_Test" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --classnames "DJ_Retail_BusinessLogic_Test" --resultformat human -u "dj-crm129"

sfdx force:apex:test:run --classnames `
"DJ_Retail_BusinessLogic_Test,DJ_ExistingCustomerUpdate_Test,DJFS_NewProcess_Test,DJ_MergeBatch_Test,DJ_Retail_FS_NewProcess_Test,CRG_BusinessLogicTest,DJ_Retail_Clientel_Test,SM_CustomerHierarchyPurge_Test" `
--resultformat human `
-u "dj-crm129" `
--wait 10000



# Test Method runs
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestSuiteCreation_Positive" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestPosCreation_Positive,DJ_Retail_BusinessLogic_Test.TestPosNonCreation" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestCpcCreation_Positive" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestPosNonCreation" --resultformat human -u "dj-mdm"
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestCreation_Wifi" --resultformat human -u "dj-mdm"

sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestCpcCreation_Positive" --resultformat human -u "dj-crm129"

sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestBulk_Suites" --resultformat human -u "dj-crm129"
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestBulk_Clones" --resultformat human -u "dj-crm129"

# DJ_Retail_BusinessLogic_Tests
sfdx force:apex:test:run --tests "DJ_Retail_BusinessLogic_Test.TestOnlineRegistered" --resultformat human -u "dj-crm129"

# DJ_Retail_BusinessLogic_Test no Bulk
sfdx force:apex:test:run `
--tests "DJ_Retail_BusinessLogic_Test.TestOnlineRegistered,DJ_Retail_BusinessLogic_Test.TestSegmentInsufficient,DJ_Retail_BusinessLogic_Test.TestOnlineGuest,DJ_Retail_BusinessLogic_Test.TestEtail,DJ_Retail_BusinessLogic_Test.TestLeadGen,DJ_Retail_BusinessLogic_Test.TestUCI,DJ_Retail_BusinessLogic_Test.TestWifi,DJ_Retail_BusinessLogic_Test.TestPOS,DJ_Retail_BusinessLogic_Test.TestNonAndPOS" `
--resultformat human `
-u "dj-crm129"


# json filters
[*].{AMEX_Account_Number__c:AMEX_Account_Number__c, AMEX_Card_Number__c:AMEX_Card_Number__c, Capture_Channel__c:Capture_Channel__c, Email__c:Email__c, Customer_Reference_ID__c:Customer_Reference_ID__c}
