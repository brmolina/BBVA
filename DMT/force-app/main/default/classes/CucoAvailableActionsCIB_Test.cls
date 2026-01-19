/**
* ────────────────────────────────────────────────────────────────────────────────────
* CucoAvailableActionsCIB_Test
* Test class for AvailableActionsCIB apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-05-21
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:TooManyMethods')
@IsTest
public class CucoAvailableActionsCIB_Test {

    @TestSetup
    static void makeDataAvailableActions() {

        final List<Account> lstAvailableActionsAcc = cuco.Test_Utils.createAccounts(1);
        insert lstAvailableActionsAcc;

        final List<cuco__profitability_sheet__c> lstAvailableActionsPS = cuco.Test_Utils.createProfSheet(1, lstAvailableActionsAcc[0]);
        insert lstAvailableActionsPS;

        final List<cuco__profitability_analysis__c> lstAvailableActionsPA = cuco.Test_Utils.createProfAnalysis(14, lstAvailableActionsAcc[0]);
        for (cuco__profitability_analysis__c profAn : lstAvailableActionsPA) {
            profAn.cuco__gf_profitability_sheet_id__c = lstAvailableActionsPS[0].Id;
        }
        // PA_Dismiss_Sample
        lstAvailableActionsPA[0].cuco__gf_pa_management_type_name__c = 'Cancellation';
        lstAvailableActionsPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[1].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[1].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[1].cuco__gf_pa_mgmt_status_type_name__c = 'Restudy';
        lstAvailableActionsPA[2].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[2].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[2].cuco__gf_pa_mgmt_status_type_name__c = 'Restudy';
        lstAvailableActionsPA[2].cuco__gf_auto_formalization_req_id__c = 'Test';

        // PA_Price_Approval_Sample
        lstAvailableActionsPA[3].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[3].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[3].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[4].cuco__gf_pa_management_type_name__c = 'Cancellation';
        lstAvailableActionsPA[4].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[4].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';

        // PA_Restudy_Sample
        lstAvailableActionsPA[7].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[7].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        lstAvailableActionsPA[7].cuco__gf_pa_mgmt_status_type_name__c = 'Formalization Returned';
        lstAvailableActionsPA[8].cuco__gf_pa_management_type_name__c = 'Cancellation';
        lstAvailableActionsPA[8].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        lstAvailableActionsPA[8].cuco__gf_pa_mgmt_status_type_name__c = 'Formalization Returned';

        // PA_Notification_Sample
        lstAvailableActionsPA[11].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[11].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        lstAvailableActionsPA[11].cuco__gf_pa_mgmt_status_type_name__c = 'Sent for Formalization';
        lstAvailableActionsPA[13].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalized';
        lstAvailableActionsPA[13].cuco__gf_pa_mgmt_status_type_name__c = 'Formalized';
        lstAvailableActionsPA[13].cuco__gf_pa_management_type_name__c = 'Cancellation';

        // No use
        lstAvailableActionsPA[5].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[5].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[5].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[6].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[6].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[6].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[9].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[9].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[9].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[10].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[10].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[10].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstAvailableActionsPA[12].cuco__gf_pa_management_type_name__c = 'Novation';
        lstAvailableActionsPA[12].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstAvailableActionsPA[12].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';

        insert lstAvailableActionsPA;
    }

    // PA_Dismiss_Sample test 1
    @IsTest
    static void cucoAvailableActionsCIBTest1() {

        final cuco.ProfitabilityAnalysis_Selector paSelector1 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames1 = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> profAnalysis1 = paSelector1.selectByName(paNames1);

        Test.startTest();
            final Map<String,Object> actualMap1 = CucoAvailableActionsCIB.checkAvailableAction('PA_Dismiss', profAnalysis1[0].Id);
            final Map<String, Object> expectedMap1 = new Map<String, Object>();
            expectedMap1.put('success', true);
            System.assertEquals(expectedMap1, actualMap1, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest1');
        Test.stopTest();
    }

    // PA_Dismiss_Sample test 2
    @IsTest
    static void cucoAvailableActionsCIBTest2() {

        final cuco.ProfitabilityAnalysis_Selector paSelector2 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames2 = new Set<String>{'Prof Analysis Test 1'};
        final List<cuco__profitability_analysis__c> profAnalysis2 = paSelector2.selectByName(paNames2);

        Test.startTest();
            final Map<String,Object> actualMap2 = CucoAvailableActionsCIB.checkAvailableAction('PA_Dismiss', profAnalysis2[0].Id);
            final Map<String, Object> expectedMap2 = new Map<String, Object>();
            expectedMap2.put('success', true);
            System.assertEquals(expectedMap2, actualMap2, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest2');
        Test.stopTest();
    }

    // PA_Dismiss_Sample test 3
    @IsTest
    static void cucoAvailableActionsCIBTest3() {

        final cuco.ProfitabilityAnalysis_Selector paSelector3 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames3 = new Set<String>{'Prof Analysis Test 2'};
        final List<cuco__profitability_analysis__c> profAnalysis3 = paSelector3.selectByName(paNames3);

        Test.startTest();
            final Map<String,Object> actualMap3 = CucoAvailableActionsCIB.checkAvailableAction('PA_Dismiss', profAnalysis3[0].Id);
            final Map<String, Object> expectedMap3 = new Map<String, Object>();
            expectedMap3.put('success', false);
            expectedMap3.put('message', Label.cuco.action_not_available_sample);
            System.assertEquals(expectedMap3, actualMap3, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest3');
        Test.stopTest();
    }

    // PA_Restudy_Sample test 1
    @IsTest
    static void cucoAvailableActionsCIBTest8() {

        final cuco.ProfitabilityAnalysis_Selector paSelector8 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames8 = new Set<String>{'Prof Analysis Test 7'};
        final List<cuco__profitability_analysis__c> profAnalysis8 = paSelector8.selectByName(paNames8);

        Test.startTest();
            final Map<String,Object> actualMap8 = CucoAvailableActionsCIB.checkAvailableAction('PA_Restudy', profAnalysis8[0].Id);
            final Map<String, Object> expectedMap8 = new Map<String, Object>();
            expectedMap8.put('success', true);
            System.assertEquals(expectedMap8, actualMap8, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest8');
        Test.stopTest();
    }

    // PA_Restudy_Sample test 2
    @IsTest
    static void cucoAvailableActionsCIBTest9() {

        final cuco.ProfitabilityAnalysis_Selector paSelector9 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames9 = new Set<String>{'Prof Analysis Test 8'};
        final List<cuco__profitability_analysis__c> profAnalysis9 = paSelector9.selectByName(paNames9);

        Test.startTest();
            final Map<String,Object> actualMap9 = CucoAvailableActionsCIB.checkAvailableAction('PA_Restudy', profAnalysis9[0].Id);
            final Map<String, Object> expectedMap9 = new Map<String, Object>();
            expectedMap9.put('success', false);
            expectedMap9.put('message', Label.cuco.action_not_available_sample);
            System.assertEquals(expectedMap9, actualMap9, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest9');
        Test.stopTest();
    }

    // PA_Formalization_Sample test 2
    @IsTest
    static void cucoAvailableActionsCIBTest11() {

        final cuco.ProfitabilityAnalysis_Selector paSelector11 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames11 = new Set<String>{'Prof Analysis Test 10'};
        final List<cuco__profitability_analysis__c> profAnalysis11 = paSelector11.selectByName(paNames11);

        Test.startTest();
            final Map<String,Object> actualMap11 = CucoAvailableActionsCIB.checkAvailableAction('PA_Formalization', profAnalysis11[0].Id);
            final Map<String, Object> expectedMap11 = new Map<String, Object>();
            expectedMap11.put('success', true);
            System.assertEquals(expectedMap11, actualMap11, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest11');
        Test.stopTest();
    }

    // PA_Notification_Sample test 1
    @IsTest
    static void cucoAvailableActionsCIBTest12() {

        final cuco.ProfitabilityAnalysis_Selector paSelector12 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames12 = new Set<String>{'Prof Analysis Test 11'};
        final List<cuco__profitability_analysis__c> profAnalysis12 = paSelector12.selectByName(paNames12);

        Test.startTest();
            final Map<String,Object> actualMap12 = CucoAvailableActionsCIB.checkAvailableAction('PA_Notification', profAnalysis12[0].Id);
            final Map<String, Object> expectedMap12 = new Map<String, Object>();
            expectedMap12.put('success', true);
            System.assertEquals(expectedMap12, actualMap12, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest12');
        Test.stopTest();
    }

    // PA_Notification_Sample test 2
    @IsTest
    static void cucoAvailableActionsCIBTest13() {

        final cuco.ProfitabilityAnalysis_Selector paSelector13 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames13 = new Set<String>{'Prof Analysis Test 12'};
        final List<cuco__profitability_analysis__c> profAnalysis13 = paSelector13.selectByName(paNames13);

        Test.startTest();
            final Map<String,Object> actualMap13 = CucoAvailableActionsCIB.checkAvailableAction('PA_Notification', profAnalysis13[0].Id);
            final Map<String, Object> expectedMap13 = new Map<String, Object>();
            expectedMap13.put('success', false);
            expectedMap13.put('message', Label.cuco.action_not_available_sample);
            System.assertEquals(expectedMap13, actualMap13, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest13');
        Test.stopTest();
    }

    // PA_Formalization_Sample test 21
    @IsTest
    static void cucoAvailableActionsCIBTest14() {

        final cuco.ProfitabilityAnalysis_Selector paSelector14 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames14 = new Set<String>{'Prof Analysis Test 13'};
        final List<cuco__profitability_analysis__c> profAnalysis14 = paSelector14.selectByName(paNames14);

        Test.startTest();
            final Map<String,Object> actualMap14 = CucoAvailableActionsCIB.checkAvailableAction('PA_Formalization', profAnalysis14[0].Id);
            final Map<String, Object> expectedMap14 = new Map<String, Object>();
            expectedMap14.put('success', false);
            expectedMap14.put('message', Label.cuco.action_not_available_sample);
            System.assertEquals(expectedMap14, actualMap14, 'Error at CucoAvailableActionsCIB_Test - cucoAvailableActionsCIBTest14');
        Test.stopTest();
    }

    @isTest
    static void getDynamicButtonStatusTest() {

        final cuco.ProfitabilityAnalysis_Selector paSelector2 = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> paNames2 = new Set<String>{'Prof Analysis Test 1'};
        final List<cuco__profitability_analysis__c> profAnalysis2 = paSelector2.selectByName(paNames2);

        Test.startTest();
            final PAActionsStatus actions = new PAActionsStatus();
            final Set<String> res = actions.getDynamicButtonStatus(profAnalysis2[0].Id, 'cuco__profitability_analysis__c');
            System.assert(res.isEmpty(), 'Error at CucoAvailableActionsCIB_Test - getDynamicButtonStatusTest');
        Test.stopTest();
    }
}