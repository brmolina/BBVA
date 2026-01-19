/*-----------------------------------------------------------------------------------------------
    Author:        Rodrigo Fdez-Victorio
    Company:       Accenture
    Description:   Subclass to handle currency methods called when the triggers over Case object are fired

    History:
    <Date>          <Author>                <Description>
    08/07/2017      Juan Carlos Terrón        Initial version
    -------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethodsCurrency {
  /*Constante texto identificador de test*/
  final static string LOG_TEST = 'Catch testing';

  private SER_CaseMethodsCurrency() {
  }

  /*----------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to transform claim cases currency field values from EUR currency to another defined
      currency.

      IN:            Map<Id,Case>x2(Trigger.newMap, Trigger.oldMap)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      18/05/2017              Juan Carlos Terrón      Initial Version
      -----------------------------------------------------------------------------------------------------------------*/
  public static void manageCurrencyRate(List<Case> news,List<Case> olds,Map<Id,Case> newMap,Map<Id,Case> oldMap) {
    try {
      if (news == null) {
        //update event
        manageCurrencyRateUpdate (newMap, oldMap);
      } else {
        //insert event
        manageCurrencyRateInsert (news);
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }      //Catch testing for code coverage.
    } catch (Exception ex) {
      CIB_LogUtils.create_Log('SER_CaseMethods.manageCurrencyRate()', ex.getStackTraceString()+'\n'+ ex.getMessage());
    }
  }

  private static void manageCurrencyRateInsert (List<Case> news) {
    List<Case> listCaseToProcess;
    listCaseToProcess = new List<Case>();
    Set<String> setCurrencies;
    setCurrencies = new Set<String>();
    Map<String,Double> mpUnlistedstCurr;
    Map<String,List<Case> > mapCasesToProcess;
    mapCasesToProcess = new Map<String,List<Case> >();
    Map<String,Map<Date,Double> > mpCurrExchange;
    Map<String,Date> mapMostRecentCEX;

    for(Case casoItem : news) {    //Iterate over trigger list
      if( casoItem.SER_Currency__c != null
          && (casoItem.SER_Operational_risk__c != null || casoItem.SER_Amount_finally_assumed__c != null
              || casoItem.SER_Claim_partially_recovered__c != null)) {
        //The case has a currency and its financial field values aren't null.
        if(mapCasesToProcess.containsKey(casoItem.SER_Currency__c)) {
          mapCasesToProcess.get(casoItem.SER_Currency__c).add(casoItem);
          listCaseToProcess.add(casoItem);
          setCurrencies.add(casoItem.SER_Currency__c);
        } else {
          mapCasesToProcess.put(casoItem.SER_Currency__c,new List<Case> {casoItem});
          listCaseToProcess.add(casoItem);
          setCurrencies.add(casoItem.SER_Currency__c);
        }
      }
    }
    if(!mapCasesToProcess.isEmpty()) {
      mpUnlistedstCurr = new Map<String,Double>();
      mpCurrExchange = new Map<String,Map<Date,Double> >();
      mapMostRecentCEX = new Map<String,Date>();

      //Methods call to manage the transformation of the financial values --> see methods description/comments.
      Set<String> setDupUnlstdCrr = new Set<String>();
      setDupUnlstdCrr = SER_CaseMethods_HELPER.generateCEXMaps (setCurrencies,mpUnlistedstCurr,mapMostRecentCEX,mpCurrExchange);
      SER_CaseMethods_HELPER.assignCurrencyFields(setDupUnlstdCrr,listCaseToProcess,setCurrencies,mpUnlistedstCurr,mapMostRecentCEX,mpCurrExchange);
    }
  }

  private static void manageCurrencyRateUpdate (Map<Id,Case> newMap,Map<Id,Case> oldMap) {
    List<Case> listCaseToProcess;
    listCaseToProcess = new List<Case>();
    Set<String> setCurrencies;
    setCurrencies = new Set<String>();
    Map<String,Double> mpUnlistedstCurr;
    Map<String,List<Case> > mapCasesToProcess;
    mapCasesToProcess = new Map<String,List<Case> >();
    Map<String,Map<Date,Double> > mpCurrExchange;
    Map<String,Date> mapMostRecentCEX;

    for(Case casoItem : newMap.values()) {
      Case oldCase;
      oldCase = oldMap.get(casoItem.ID);
      boolean cambiosFinan;
      cambiosFinan = false;
      boolean financBorrados;
      financBorrados = false;
      //Financial values are changed.
      cambiosFinan = casoItem.SER_Currency__c != oldCase.SER_Currency__c
                      || casoItem.SER_Operational_risk__c != oldCase.SER_Operational_risk__c
                      || casoItem.SER_Amount_finally_assumed__c != oldCase.SER_Amount_finally_assumed__c
                      || casoItem.SER_Claim_partially_recovered__c != oldCase.SER_Claim_partially_recovered__c
                      || casoItem.SER_Accounting_date__c != oldCase.SER_Accounting_date__c
                      /** Begin: validation for GTB currency -- (vv) */
                      || casoItem.return_amount__c != oldCase.return_amount__c;
      /** End: */
      //Fianncial values are not being deleted.
      financBorrados = casoItem.SER_Operational_risk__c == null
                        && casoItem.SER_Amount_finally_assumed__c == null
                        && casoItem.SER_Claim_partially_recovered__c == null
                        && oldCase.SER_Operational_risk__c == null
                        && oldCase.SER_Amount_finally_assumed__c == null
                        && oldCase.SER_Claim_partially_recovered__c == null
                        /** Begin: validation for GTB currency -- (vv) */
                        && casoItem.return_amount__c == null
                        && oldCase.return_amount__c == null;
      /** End: */
      boolean tratarCaso;
      tratarCaso = casoItem.SER_Currency__c != null && cambiosFinan && !financBorrados;
      if(tratarCaso) {
        boolean vacioAmnts;
        vacioAmnts = casoItem.SER_Operational_risk__c == null && oldCase.SER_Operational_risk__c != null
                      || casoItem.SER_Amount_finally_assumed__c == null && oldCase.SER_Amount_finally_assumed__c != null
                      /** Begin: validation for GTB currency -- (vv) */
                      || casoItem.return_amount__c == null && oldCase.return_amount__c != null;
        /** End: */
        if(vacioAmnts) {
          vaciarAmntCaso (casoItem,oldcase);
        }         /*FIN DEL IF*/
        if(mapCasesToProcess.containsKey(casoItem.SER_Currency__c)) {
          mapCasesToProcess.get(casoItem.SER_Currency__c).add(casoItem);
          listCaseToProcess.add(casoItem);
          setCurrencies.add(casoItem.SER_Currency__c);
        } else {
          mapCasesToProcess.put(casoItem.SER_Currency__c,new List<Case> {casoItem});
          listCaseToProcess.add(casoItem);
          setCurrencies.add(casoItem.SER_Currency__c);
        }
      }
    }
    if(!mapCasesToProcess.isEmpty()) {
      mapMostRecentCEX = new Map<String,Date>();
      mpCurrExchange = new Map<String,Map<Date,Double> >();
      mpUnlistedstCurr = new Map<String,Double>();

      //Methods call to manage the transformation of the financial values --> see methods description/comments.
      Set<String> setDupUnlstdCrr = new Set<String>();
      setDupUnlstdCrr = SER_CaseMethods_HELPER.generateCEXMaps(setCurrencies,mpUnlistedstCurr,mapMostRecentCEX,mpCurrExchange);
      SER_CaseMethods_HELPER.assignCurrencyFields(setDupUnlstdCrr,listCaseToProcess,setCurrencies,mpUnlistedstCurr,mapMostRecentCEX,mpCurrExchange);
    }
  }
  private static void vaciarAmntCaso (Case pCasoItem, Case pOldCase) {
    boolean vaciarOpRisk;
    vaciarOpRisk = pCasoItem.SER_Operational_risk__c == null && pOldCase.SER_Operational_risk__c != null;
    boolean vaciarAmntEU;
    vaciarAmntEU = pCasoItem.SER_Amount_finally_assumed__c == null && pOldCase.SER_Amount_finally_assumed__c != null;
    boolean vaciarAmntRec;
    vaciarAmntRec = pCasoItem.SER_Claim_partially_recovered__c == null && pOldCase.SER_Claim_partially_recovered__c != null;
    Decimal nullDecimal;

    if(vaciarOpRisk) {
      pCasoItem.SER_Operational_risk_EUR__c = nullDecimal;
    }
    if(vaciarAmntEU) {
      pCasoItem.SER_Amount_finally_assumed_EUR__c = nullDecimal;
    }
    if(vaciarAmntRec) {
      pCasoItem.SER_Amount_recovered_EUR__c = nullDecimal;
    }
  }

  private static boolean runTest() {
    return Test.isRunningTest();
  }
}