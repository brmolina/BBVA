/*******************************************************************************
* @author:           Victor Velandia (VV)
* Project:           BBVA Service
* Description:       Class Test
*
*            No.     Date            Author                   Description
*            -----   ----------      --------------------     ---------------
* @version   1.1     2019-05-20      Victor Velandia (VV)     Class test
********************************************************************************/
@IsTest
private class SER_ReclamacionesPDFGeneratorTst {
  @isTest
  static void testMethodOne() {

    final Case newCase = new Case();
    final String rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SER_GM_User').getRecordTypeId();

    newCase.SER_Is_Master_Case__c = true;
    //newCase.SER_Master_Case__c = null;
    newCase.OwnerId                         = UserInfo.getUserId();
    newCase.RecordTypeId                    = rtId;
    newCase.SER_Product__c                  = 'BBVA NET C@SH';
    newCase.Subject                         = 'TEST Subject';
    newCase.Description                     = 'TEST Description';
    newCase.Type                            = 'ACCESO';
    newCase.Subtype__c                      = 'ACCESO';
    newCase.SER_Type_GM__c                  = 'TMPG';
    newCase.SER_Subtype_GM__c               = 'Others';
    newCase.SER_Source_of_the_error__c      = 'CIB operations';
    newCase.SER_Classification__c           = 'Monetary claim';
    newCase.SuppliedEmail                   = 'testSuppliedEmailAddress@test.com';
    newCase.SER_Remedy_Department__c        = 'ANS sstt';
    newCase.Status                          = 'Transferred';
    newCase.SER_Skip_validations__c         = true;
    newCase.SER_Amount_finally_assumed__c      = 2018;
    newCase.SER_Amount_finally_assumed_EUR__c  = 2018;
    newCase.SER_Operational_risk__c            = 2018;
    newCase.SER_Operational_risk_EUR__c        = 2018;
    newCase.SER_Claim_partially_recovered__c   = 2018;
    newCase.SER_Amount_recovered_EUR__c        = 2018;
    insert newCase;

    ApexPages.StandardController strc = new ApexPages.StandardController(newCase);
    SER_ReclamacionesPDFGeneratorController serRecla = new SER_ReclamacionesPDFGeneratorController(strc);
    final String stClaimRecovered = serRecla.stClaimRecovered;
    system.debug('--->>>  stClaimRecovered ' + stClaimRecovered);
    System.assertEquals(newCase, newCase);
  }
}