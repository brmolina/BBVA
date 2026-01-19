/**
* ────────────────────────────────────────────────────────────────────
* CucoProfitabilitySheetCIB_Test
* Test class for CucoProfitabilitySheetCIB apex class
* ────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-13
* @modified
* @systemLayer Presentation
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@IsTest
public with sharing class CucoProfitabilitySheetCIB_Test {

    /** @description 'Prof Sheet Test 0' */
    private static final String PROFSHEETTEST0 = 'Prof Sheet Test 0';

    /** @description NEWNAMEERROR */
    private static final String NEWNAMEERROR = 'ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001ES0182000000001';

    /** @description false */
    private static final Boolean BOOLEAN_FALSE = false;

    @TestSetup
    static void makeDataOfCucoProfitabilitySheetCIB() {

        final List<Account> lstPSSAccount = cuco.Test_Utils.createAccounts(1);
        insert lstPSSAccount;

        final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, lstPSSAccount[0]);
        insert profSheets;
    }
    @IsTest
    static void setDiscardDetailsTest1() {
        Test.startTest();
            final cuco.ProfitabilitySheet_Selector psSelector1 = new cuco.ProfitabilitySheet_Selector(true);
            final List<cuco__profitability_sheet__c> lstPSS1 = psSelector1.selectByName(new Set<String>{'Prof Sheet Test 0'});
            final CucoProfitabilitySheetCIB pss1 = new CucoProfitabilitySheetCIB();
            final Map<String, Object> retMap1 = pss1.setDiscardDetails(lstPSS1[0].Id, 'Test discard comments', UserInfo.getUserId(), Date.today());
            final List<dwp_cvad__Action_Audit__c> lstActAudPSS1 = [SELECT Id FROM dwp_cvad__Action_Audit__c WHERE dwp_cvad__action_audit_record_id__c =: lstPSS1[0].Id LIMIT 1];
            final List<cuco__profitability_sheet__c> lstPSS1_1 = psSelector1.selectByName(new Set<String>{'Prof Sheet Test 0'});
            final Map<String, Object> expectedMap1 = new Map<String, Object>();
            expectedMap1.put('auditSizePSS1', 1);
            expectedMap1.put('isSuccessPSS1', true);
            expectedMap1.put('checkBf1', false);
            expectedMap1.put('checkAf1', true);
            final Map<String, Object> actualMap1 = new Map<String, Object>();
            actualMap1.put('auditSizePSS1', lstActAudPSS1.size());
            actualMap1.put('isSuccessPSS1', (Boolean) retMap1.get('success'));
            actualMap1.put('checkBf1', lstPSS1[0].cuco__renewal_discarded_type__c);
            actualMap1.put('checkAf1', lstPSS1_1[0].cuco__renewal_discarded_type__c);
            System.assertEquals(expectedMap1, actualMap1, 'Err at CucoProfitabilitySheetCIB_Test - setDiscardDetailsTest1');
        Test.stopTest();
    }
    @IsTest
    static void getDiscardDetailsTest1() {
        Test.startTest();
            final cuco.ProfitabilitySheet_Selector psSelector2 = new cuco.ProfitabilitySheet_Selector(true);
            final List<cuco__profitability_sheet__c> lstPSS2 = psSelector2.selectByName(new Set<String>{'Prof Sheet Test 0'});
            final CucoProfitabilitySheetCIB pss2 = new CucoProfitabilitySheetCIB();
            pss2.setDiscardDetails(lstPSS2[0].Id, 'Test get discard comments', UserInfo.getUserId(), Date.today());
            final Map<String, Object> retMap2 = pss2.getDiscardDetails(lstPSS2[0].Id);
            final Map<String, Object> expectedMap2 = new Map<String, Object>();
            final List<User> expectedUser2 = [SELECT Id, Name FROM User WHERE Id =: UserInfo.getUserId()];
            expectedMap2.put('commentsPSS2', 'Test get discard comments');
            expectedMap2.put('userPSS2', expectedUser2[0]);
            expectedMap2.put('datePSS2', String.valueOf(Date.today()).split(' ')[0]);
            final Map<String, Object> actualMap2 = new Map<String, Object>();
            actualMap2.put('commentsPSS2', (String) retMap2.get('comments'));
            actualMap2.put('userPSS2', retMap2.get('user'));
            actualMap2.put('datePSS2', String.valueOf(retMap2.get('date')).split(' ')[0]);
            System.assertEquals(expectedMap2, actualMap2, 'Err at CucoProfitabilitySheetCIB_Test - getDiscardDetailsTest1');
        Test.stopTest();
    }
    @IsTest
    static void setModificationPSDataTest1() {
        Test.startTest();
            final cuco.ProfitabilitySheet_Selector psSelector3 = new cuco.ProfitabilitySheet_Selector(true);
            final List<cuco__profitability_sheet__c> lstPSS3 = psSelector3.selectByName(new Set<String>{PROFSHEETTEST0});
            final CucoProfitabilitySheetCIB pss3 = new CucoProfitabilitySheetCIB();

            final Map<String,Object> mapPfInfo = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(lstPSS3[0].Id);
            final cuco.ProfitabilitySheet_Wrapper wrapper = (cuco.ProfitabilitySheet_Wrapper) mapPfInfo.get('profSheetDetails');

            final Map<String, Object> dataMap3 = new Map<String, Object>();
            dataMap3.put('needCallService', true);
            dataMap3.put('needDoDML', true);

            final Map<String, Object> retMap3 = pss3.setModificationPSData(wrapper, 'New Name', (Id)UserInfo.getUserId(), dataMap3);
            System.assert((Boolean) retMap3.get('success'), 'Err at CucoProfitabilitySheetCIB_Test - setModificationPSDataTest1');
        Test.stopTest();
    }
    @IsTest
    static void setModificationPSDataTest2() {
        Test.startTest();
            final cuco.ProfitabilitySheet_Selector psSelector4 = new cuco.ProfitabilitySheet_Selector(true);
            final List<cuco__profitability_sheet__c> lstPSS4 = psSelector4.selectByName(new Set<String>{PROFSHEETTEST0});
            final CucoProfitabilitySheetCIB pss4 = new CucoProfitabilitySheetCIB();

            final Map<String,Object> mapPfInfo = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(lstPSS4[0].Id);
            final cuco.ProfitabilitySheet_Wrapper wrapper = (cuco.ProfitabilitySheet_Wrapper) mapPfInfo.get('profSheetDetails');

            final Map<String, Object> dataMap4 = new Map<String, Object>();
            dataMap4.put('needCallService', true);
            dataMap4.put('needDoDML', true);

            final Map<String, Object> retMap4 = pss4.setModificationPSData(wrapper, NEWNAMEERROR, (Id)UserInfo.getUserId(), dataMap4);
            System.assertEquals(BOOLEAN_FALSE, retMap4.get('success'), 'Err at CucoProfitabilitySheetCIB_Test - setModificationPSDataTest2');
        Test.stopTest();
    }
}