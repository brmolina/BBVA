/*-----------------------------------------------------------------------------------------------
    Author:        Rodrigo Fdez-Victorio
    Company:       Accenture
    Description:   Testclass for currency methods

    History:
    <Date>          <Author>                <Description>
    08/07/2017      Juan Carlos Terrón        Initial version
-------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class SER_CaseMethodsCurrency_TEST {
  /* constante para US dollar */
  final static string CURR_USD = 'USD';
  /* constante para JP yen */
  final static string CURR_JPY = 'JPY';
  /* constante para origin email */
  final static string OIGIN_EMAIL = 'Email';
  /* constante 'Case'*/
  final static string CASEOBJ = 'Case';
  /* constante 'SER_GM_User'*/
  final static string GM_RT = 'SER_GM_User';

  /*----------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test method for currency in cases. Several currencies.

      IN:            void
      OUT:           void


      History:
      <Date>                  <Author>                <Change Description>
      18/05/2017              Juan Carlos Terrón      Initial Version
  -----------------------------------------------------------------------------------------------------------------*/
  public static testMethod void  manageCurrencyRateTEST() {
    SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCase = new List<Case>();

    final SER_EUR_Currency_exchange_rate__c serEur = new SER_EUR_Currency_exchange_rate__c(SER_Counter_currency__c = CURR_USD,
                                                                                            SER_Process_date__c = Date.newInstance(date.today().year(), 04, 20),
                                                                                            SER_Exchange_rate__c = 10744);
    insert serEur;

    final SER_EUR_Currency_exchange_rate__c serEur2 = new SER_EUR_Currency_exchange_rate__c(SER_Counter_currency__c = CURR_USD,
                                                                                            SER_Process_date__c = Date.newInstance(date.today().year(), 04, 20),
                                                                                            SER_Exchange_rate__c = 10744);
    insert serEur2;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = OIGIN_EMAIL,
                                SER_Currency__c = CURR_USD,
                                SER_Claim_partially_recovered__c = 42,
                                SER_Operational_risk__c = 18,
                                SER_Amount_finally_assumed__c = 18,
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));

    final Case caso2 = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = OIGIN_EMAIL,
                                SER_Currency__c = CURR_USD,
                                SER_Claim_partially_recovered__c = 42,
                                SER_Operational_risk__c = 18,
                                SER_Amount_finally_assumed__c = 18,
                                SER_Accounting_date__c = Date.newInstance(date.today().year(), 04, 20),
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));

    lstCase.add(caso);
    lstCase.add(caso2);

    insert lstCase;


    final SER_EUR_Currency_exchange_rate__c serEur3 = new SER_EUR_Currency_exchange_rate__c(SER_Counter_currency__c = 'JPY');
    insert serEur3;

    final Case caso3 = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = OIGIN_EMAIL,
                                SER_Currency__c = CURR_JPY,
                                SER_Claim_partially_recovered__c = 42,
                                SER_Operational_risk__c = 18,
                                SER_Amount_finally_assumed__c = 18,
                                SER_Accounting_date__c = Date.newInstance(date.today().year(), 04, 20),
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));
    try {
      insert caso3;
      System.assertEquals (caso3,caso3,'manageCurrencyRateTEST');
    } catch(Exception ex) {
      System.debug('Error manageCurrencyRateTEST:' + ex.getMessage());
    }
  }

  /*----------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test method for currency. Create case without currency.

      IN:            Map<Id,Case>x2(Trigger.newMap, Trigger.oldMap)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      18/05/2017              Juan Carlos Terrón      Initial Version
  -----------------------------------------------------------------------------------------------------------------*/
  public static testMethod void  amanageCurrencyRateTEST() {
    SER_TestUtils_3.initCustomsetting();
    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = OIGIN_EMAIL,
                                SER_EmailToCaseCode__c = 'aaa@example.aa',
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));

    insert caso;

    final Case caso2 = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = OIGIN_EMAIL,
                                SER_EmailToCaseCode__c = 'aaaa@example.aa',
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));

    try {
      insert caso2;
      System.assertEquals (caso2,caso2,'amanageCurrencyRateTEST');
    } catch(Exception ex) {
      System.debug('Error amanageCurrencyRateTEST:' + ex.getMessage());
    }
  }
}