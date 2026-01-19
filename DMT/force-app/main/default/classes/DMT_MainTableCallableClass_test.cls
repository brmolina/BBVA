@isTest
public with sharing class DMT_MainTableCallableClass_test {
    @TestSetup
    static void loadTestData() {
      // GIVEN
      DMT_Test_DataFactory.generateTestTreasuryLines();
    }
    @isTest
        private static void testcallextension(){
            DMT_Line__c testLine = [SELECT Id,OwnerId FROM DMT_Line__c LIMIT 1];
            Map<String,Object> mapArgs = new Map<String,Object>();
            mapArgs.put('selectedTab','tcm');
            mapArgs.put('clientId','testLine.Client__c');
            mapArgs.put('searchDate',System.today());
            mapArgs.put('clientPositionsType','Y');
            mapArgs.put('page',1);
            mapArgs.put('pageSize',1);
            
            Test.startTest();
            Object returnObject = DMT_MainTableCallableClass.callExtensionImperative('fetchData', 'DMT_ExtensionCallableMainTable',mapArgs);
            Test.stopTest();

            System.assertEquals(true, returnObject != null, '1 corporate user must be retrieved');
        }

    }