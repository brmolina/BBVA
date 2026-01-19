/*-----------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   This class contains helper and auxiliar methods
                    to not overload the main casemethods class.

    History:
    <Date>          <Author>                <Description>
    04/07/2017      Juan Carlos Terrón      Initial Version.
-------------------------------------------------------------------*/
public without sharing class SER_CaseMethods_HELPER {
  /*Constante que almacena el entero 10*/
  final static integer MY_INT = 10;

  private SER_CaseMethods_HELPER() {
  }
  /*------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to generate Currency Exchange rate maps used in
                      manageCurrencyRate method.

      IN:            Map<String,Map<Date,Double>>,Map<String,Date>
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      04/07/2017              Juan Carlos Terrón      Initial Version
  --------------------------------------------------------------------------*/
  public static Set<String> generateCEXMaps(
    Set<String>                     setCurrencies,
    Map<String,Double>              mapUnlistedCurr,
    Map<String,Date>                mapMostRecentCEX,
    Map<String,Map<Date,Double> >    mapCEX
    ) {
    Set<String> setDuplUnlistCurr;     //Set to store the duplicated currencies.
    setDuplUnlistCurr = new Set<String>();
    for(SER_EUR_Currency_exchange_rate__c cexItem :
        [
          SELECT Id,
          SER_Counter_currency__c,
          SER_Exchange_rate__c,
          SER_Process_date__c,
          SER_Unlisted__c
          FROM SER_EUR_Currency_exchange_rate__c
          WHERE SER_Counter_currency__c IN :setCurrencies
          ORDER BY SER_Process_date__c DESC
        ]) {     //Query over the currency rate records in the bbdd with the same currency as the ones in setCurrencies
      if(cexItem.SER_Unlisted__c) {       //Unlisted Currencies Process
        if(mapUnlistedCurr.containskey(cexItem.SER_Counter_currency__c)) {         //Map doesn't contains the currency --> put it into the map
          setDuplUnlistCurr.add(cexItem.SER_Counter_currency__c);
        } else {         //Map contains the currency --> overwrite(unlisted currencies may be unique)
          mapUnlistedCurr.put(cexItem.SER_Counter_currency__c,cexItem.SER_Exchange_rate__c);
        }
      } else if(mapCEX.containsKey(cexItem.SER_Counter_currency__c)) {       //Not unlisted currency & contained into the map
        if(mapCEX.get(cexItem.SER_Counter_currency__c).containskey(cexItem.SER_Process_date__c)) {         //2nd level map conatins the process date --> overwrite the date
          mapCEX.get(cexItem.SER_Counter_currency__c).put(cexItem.SER_Process_date__c,cexItem.SER_Exchange_rate__c);
        } else {         //2nd level map conatins the process date --> set it
          mapCEX.get(cexItem.SER_Counter_currency__c).put(cexItem.SER_Process_date__c,cexItem.SER_Exchange_rate__c);
        }
        if(mapMostRecentCEX.containsKey(cexItem.SER_Counter_currency__c)) {         //the date is the most recent attending the fact that there's no record for that date
          if(cexItem.SER_Process_date__c >= mapMostRecentCEX.get(cexItem.SER_Counter_currency__c)) {           //The current process date is later to one stored in the map --> overwrite map
            mapMostRecentCEX.put(cexItem.SER_Counter_currency__c, cexItem.SER_Process_date__c);
          }
        } else {         //Set that date in the map.
          mapMostRecentCEX.put(cexItem.SER_Counter_currency__c, cexItem.SER_Process_date__c);
        }
      } else {       //That currency is no in the mapCEX.
        //Generate new map record.
        generateNewMapRecord(mapCEX,cexItem,mapMostRecentCEX);
      }
    }
    return setDuplUnlistCurr;     //We return the duplicated unlisted currencies set .
  }
  private static void generateNewMapRecord(Map<String,Map<Date,Double> > mapCEX, SER_EUR_Currency_exchange_rate__c cexItem, Map<String,Date> mapMostRecentCEX) {
    mapCEX.put(cexItem.SER_Counter_currency__c, new Map<Date,Double>());
    mapCEX.get(cexItem.SER_Counter_currency__c).put(cexItem.SER_Process_date__c, cexItem.SER_Exchange_rate__c);
    if(mapMostRecentCEX.containsKey(cexItem.SER_Counter_currency__c)) {
      if(cexItem.SER_Process_date__c >= mapMostRecentCEX.get(cexItem.SER_Counter_currency__c)) {
        mapMostRecentCEX.put(cexItem.SER_Counter_currency__c, cexItem.SER_Process_date__c);
      }
    } else {
      mapMostRecentCEX.put(cexItem.SER_Counter_currency__c, cexItem.SER_Process_date__c);
    }
  }

  /*-------------------------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that converts case currency fields depending on a currency exchange ratio given under certain casuistry.

      IN:
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      04/07/2017              Juan Carlos Terrón      Initial version
      07/04/2019              Victor Velandia         Validation return_euro_amount__c for GTB and New field for GTB
  ---------------------------------------------------------------------------------------------------------------------------------*/
  public static void assignCurrencyFields(
    Set<String> setDuplUnlistCurr,
    List<Case> listCases,
    Set<String> setCurrencies,
    Map<String, Double> mapUnlistedCurr,
    Map<String, Date> mapMostRecentCEX,
    Map<String, Map<Date, Double> > mapCEX
    ) {
    for (Case casoitem : listCases) {
      Double cex;
      boolean isValRecAccDatGM;
      isValRecAccDatGM = casoitem.SER_Accounting_date__c == null && mapMostRecentCEX.containsKey(casoitem.SER_Currency__c);
      boolean isValRecAccDatGTB;
      isValRecAccDatGTB = casoitem.SER_Business_Case_Type__c == Label.SER_Business_Case_Type_GTB && mapMostRecentCEX.containsKey(casoitem.SER_Currency__c);
      boolean isInvalAccDateGM;
      isInvalAccDateGM = isInvalidAccountingDateGM (casoitem, mapCEX) && casoitem.SER_Business_Case_Type__c == Label.SER_Business_Case_Type_GM;
      boolean isRecAccDatGTBEUR;
      isRecAccDatGTBEUR = casoitem.SER_Business_Case_Type__c == Label.SER_Business_Case_Type_GTB && casoitem.return_amount__c != null && casoitem.SER_Currency__c == Label.SER_Claim_Currency_EUR;
      //If the currency is in the duplicated currencies set an error is given.
      if ( setDuplUnlistCurr.contains(casoitem.SER_Currency__c) ) {
        casoitem.AddError(label.SER_Duplicated_Currency);
      }
      if ( isUnlistedCurrency(casoitem, mapUnlistedCurr) ) {       //There's a concrete  unlisted currency for that case
        system.debug('---->>>> isUnlistedCurrency ');
        cex = mapUnlistedCurr.get(casoitem.SER_Currency__c);
        SER_CaseMethods_HELPER.assignCurrencyFields(casoitem, cex);
      } else if ( isValueForCurrencyDateGM(casoitem, mapCEX) ) {       //There's a concrete value for that currency and date
        system.debug('---->>>> isValueForCurrencyDateGM ');
        cex = mapCEX.get(casoitem.SER_Currency__c).get(casoitem.SER_Accounting_date__c);
        SER_CaseMethods_HELPER.assignCurrencyFields(casoitem, cex);
      } else if ( isValRecAccDatGM ) {       //There's no accounting date --> we search for the most recent date for that currency, if it exist we set it.
        system.debug('---->>>> isValRecAccDatGM ');
        cex = mapCEX.get(casoitem.SER_Currency__c).get(mapMostRecentCEX.get(casoitem.SER_Currency__c));
        SER_CaseMethods_HELPER.assignCurrencyFields(casoitem, cex);
        /** Begin: validation for GTB currency -- (vv) */
      } else if ( isValRecAccDatGTB ) {       //There's no accounting date --> we search for the most recent date for that currency, if it exist we set it.
        system.debug('---->>>> isValRecAccDatGTB ');
        cex = mapCEX.get(casoitem.SER_Currency__c).get(mapMostRecentCEX.get(casoitem.SER_Currency__c));
        SER_CaseMethods_HELPER.assignCurrencyFields(casoitem, cex);
      } else if ( isRecAccDatGTBEUR ) {       //There's no accounting date --> we search for currency same EUR
        system.debug('---->>>> isRecAccDatGTBEUR ');
        casoitem.return_euro_amount__c = casoitem.return_amount__c;
        /** End: */
      } else if ( isInvalAccDateGM ) {
        //There's no record for the accounting date at all.
        system.debug('---->>>> isInvalAccDateGM ');
        casoitem.AddError(label.SER_Accounting_date_invalid);
      }
    }
  }
  private static boolean isUnlistedCurrency (Case casoitem, Map<String,Double> mapUnlistedCurr) {
    return mapUnlistedCurr != null
            && !mapUnlistedCurr.isEmpty()
            && mapUnlistedCurr.containskey(casoitem.SER_Currency__c);
  }
  private static boolean isValueForCurrencyDateGM (Case casoitem, Map<String,Map<Date,Double> > mapCEX) {
    return casoitem.SER_Accounting_date__c != null
            && mapCEX.containsKey(casoitem.SER_Currency__c)
            && mapCEX.get(casoitem.SER_Currency__c).containskey(casoitem.SER_Accounting_date__c);
  }
  private static boolean isInvalidAccountingDateGM (Case casoitem,Map<String,Map<Date,Double> > mapCEX) {
    return (casoitem.SER_Accounting_date__c != null
            && mapCEX.containsKey(casoitem.SER_Currency__c)
            && mapCEX.get(casoitem.SER_Currency__c).containskey(casoitem.SER_Accounting_date__c))
            ||
            (casoitem.SER_Accounting_date__c != null
            && mapCEX.containsKey(casoitem.SER_Currency__c)
            && !mapCEX.get(casoitem.SER_Currency__c).containskey(casoitem.SER_Accounting_date__c));

  }

  /*--------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to asign currency field values for a case depending on the emptyness of the case.

      IN:            Case,Double
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      04/07/2017              Juan Carlos Terrón      Initial Version
      03/18/2019              Victor Velandia         Validation BuSER_Amount_GTB_EUR__csiness for GM and GTB. and New field for GTB
  ----------------------------------------------------------------------------------------------------------*/
  public static void assignCurrencyFields(Case caso, Double cex) {   //This method asigns currency fields for a Case with de currency exchange rate provided.
    if( caso.SER_Business_Case_Type__c == Label.SER_Business_Case_Type_GM ) {
      if( caso.SER_Operational_risk__c != null ) {
        caso.SER_Operational_risk_EUR__c = caso.SER_Operational_risk__c/CEX;
      }
      if( caso.SER_Amount_finally_assumed__c != null ) {
        caso.SER_Amount_finally_assumed_EUR__c = caso.SER_Amount_finally_assumed__c/CEX;
      }
      if( caso.SER_Claim_partially_recovered__c != null ) {
        caso.SER_Amount_recovered_EUR__c = caso.SER_Claim_partially_recovered__c/CEX;
      }
      /** Begin: validation for GTB currency -- (vv) */
    } else if ( caso.SER_Business_Case_Type__c == Label.SER_Business_Case_Type_GTB && caso.return_amount__c != null ) {
      caso.return_euro_amount__c = caso.return_amount__c/CEX;
    }
    /** End: */
  }
  /*----------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:

      IN:
      OUT:

      History:
      <Date>                  <Author>                <Change Description>
      02/11/2017                Juan Carlos Terrón        Initial version
  ------------------------------------------------------------------------*/

  public static List<Messaging.SingleEmailMessage> generateMasterCaseNotifications(Case caso,Map<String,String> templates, Set<SER_Master_Case_User_Notification__c> addresses,Map<String,Id> etemplates) {
    System.debug('generateMasterCaseNotifications');

    String templateId = '';
    Map<String,String> mapTemplates;
    mapTemplates = new Map<String,String>(templates);
    Map<String,Id> mapEmailTemplates;
    mapEmailTemplates = new Map<String,Id>(etemplates);
    Set<SER_Master_Case_User_Notification__c> setAddresses;
    setAddresses = new Set<SER_Master_Case_User_Notification__c>(addresses);
    List<Messaging.SingleEmailMessage> messagestosend;
    messagestosend = new List<Messaging.SingleEmailMessage>();

    System.debug('setAddresses : '+setAddresses);
    if(mapTemplates.containsKey(caso.Status)) {     //If the map contains the status of the case we use the related tempalte.
      templateId = mapEmailTemplates.get(mapTemplates.get(caso.Status));
    } else {     //If not we use de default.
      templateId = mapEmailTemplates.get(mapTemplates.get(Label.SER_DefaultCaseStatus_TemplateAssignment));
    }
    createMessagesToSend (messagestosend, setAddresses, caso, templateId);
    System.debug('messagestosend : '+messagestosend);
    return messagestosend;
  }

  private static void createMessagesToSend (List<Messaging.SingleEmailMessage> messagestosend,
                                            Set<SER_Master_Case_User_Notification__c> setAddresses,
                                          case caso,
                                            String templateId) {
    while(!setAddresses.isEmpty()) {
      List<String> listCcAddresses;
      listCcAddresses = new List<String>();
      List<String> listToAddresses;
      listToAddresses = new List<String>();
      Set<SER_Master_Case_User_Notification__c> setCcAddresDELETE;
      setCcAddresDELETE = new Set<SER_Master_Case_User_Notification__c>();
      Set<SER_Master_Case_User_Notification__c> setToAddresDELETE;
      setToAddresDELETE = new Set<SER_Master_Case_User_Notification__c>();
      Messaging.SingleEmailMessage message;
      message = new Messaging.SingleEmailMessage();

      System.debug('SET ADDRESSES SIZE : '+setAddresses.size());
      for(SER_Master_Case_User_Notification__c addressItem: setAddresses) {
        if(listToAddresses.isEmpty()) {
          message.setTargetObjectId(addressItem.SER_Contact__c);
          listToAddresses.add(addressItem.SER_Contact_email__c);
          setToAddresDELETE.add(addressItem);
          System.debug('listToAddresses : '+listToAddresses);
          //setAddresses.remove(addressItem);
        } else {
          System.debug('LCAS : '+listCcAddresses.size());
          if(listCcAddresses.size() <= MY_INT) {
            listCcAddresses.add(addressItem.SER_Contact_email__c);
            setCcAddresDELETE.add(addressItem);
            //setAddresses.remove(addressItem);
          } else {
            System.debug('cierre');
            break;
          }
        }
      }

      message.setWhatId(CASO.Id);
      message.setTemplateId(templateId);
      message.setToAddresses(listToAddresses);
      message.setCcAddresses(listCcAddresses);
      message.setOrgWideEmailAddressId(Label.SER_MasterCaseInternalNotificationSender);
      messagestosend.add(message);
      for(SER_Master_Case_User_Notification__c itemAdd : setCcAddresDELETE) {
        setAddresses.remove(itemAdd);
      }
      for(SER_Master_Case_User_Notification__c itemAdd : setToAddresDELETE) {
        setAddresses.remove(itemAdd);
      }
    }
  }
}