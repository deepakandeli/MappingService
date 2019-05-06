@isTest
public class TestMappingServices {

    @isTest
    static void testMappingService(){
        Test.startTest();
        Contact testCon = new Contact();
        Account testAcc = new Account(Name='Test Account');
        insert testAcc;
        MappingService.mapSrcToTarget('Account2Contact',testAcc,testCon);
        System.assertEquals(testAcc.Name, testCon.LastName,'Names did not match');
        Test.stopTest();
    }
}
