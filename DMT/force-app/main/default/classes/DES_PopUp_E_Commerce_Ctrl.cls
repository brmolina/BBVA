/*
*Author: ADESSO
*
*/
@SuppressWarnings('sf:CyclomaticComplexity, sf:NPathComplexity')
public with sharing class DES_PopUp_E_Commerce_Ctrl {

  /*
  * String
  */
  static final String PRODALERT = 'E_Commerce_prod_alert';
  /*
  * String
  */
  static final String MUREXALERT = 'E_Commerce_murex_alert';
  /*
  * String
  */
  static final String NONE = 'none';
  /*
  * String
  */
  static final String DDFFALERT = 'E_Commerce_ddff_alert';
  /*
  * String
  */
  static final String DESIGALERT = 'E_Commerce_designation';

  private DES_PopUp_E_Commerce_Ctrl() {}

  /*
  * Recoge el posible mensaje de alerta
  */
  @AuraEnabled
  public static String checkError(String assetID, String errorType) {
    try {
      final List<String> lErrors = errorType.split('::');
      Boolean flagThen = false;
      String errorText;
      errorText = '';
      String sNone;
      sNone = NONE;
      String getText;
      if(lErrors.contains(PRODALERT)) {
        getText = getProdError(assetID);
        errorText += (getText == sNone?'':getText + '\n\n');
      }
      //IRS and Do_we_have_Markitwire_permissions__c != Yes
      if(lErrors.contains(DDFFALERT)) {
        getText = getDDFF(assetID);
        errorText += (getText == sNone?'':getText + '\n\n');
        flagThen = getText == sNone?false:true;
      }
      //IRS and Is_the_STP_Markitwire_Murex_in_place__c != Yes
      if(lErrors.contains(MUREXALERT)) {
        getText = getMurex(assetID);
        errorText += (getText == sNone?'': (flagThen?'Then ':'') + getText);
      }
      //FX and Is_client_using_a_Prime_Broker_PB__c != Yes
      if(lErrors.contains(DESIGALERT)) {
        getText = getDesignationAlert(assetID);
        errorText += (getText == sNone?'': (flagThen?'Then ':'') + getText);
      }
      System.debug('flagThen---->'+flagThen+' -> ' + sNone);
      return errorText==''?NONE:errorText;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  private static String getProdError(String assetID) {
    Boolean flagMbono = false;
    Boolean flagMXN = false;
    Boolean flagStatus = false;
    String mxn;
    mxn = 'MXN Credit';
    String mbn;
    mbn = 'Mbono';
    String newString;
    newString = 'New';
    for(Asset_Product__c prod : [SELECT id, Product__c, Asset_Template__r.Status__c FROM Asset_Product__c WHERE Asset_Template__c = :assetID AND (Product__c = :mxn OR Product__c = :mbn) ORDER BY CreatedDate ASC]) {
      if(prod.Product__c == mbn) {
        flagMbono = true;
      } else {
        flagMXN = true;
      }
      if(prod.Asset_Template__r.Status__c == newString) {
        flagStatus = true;
      }
    }
    String errorText = NONE;

    if(flagStatus && ((flagMbono && !flagMXN) || (!flagMbono && flagMXN))) {
      errorText = Label.E_Commerce_prod_alert;
    }

    return errorText;
  }

  private static String getDDFF(String assetID) {
    String irs;
    irs = 'IRS';
    final List<Asset_Product__c> lProds = [SELECT id, Product__c, Asset_Template__r.Status__c FROM Asset_Product__c WHERE Asset_Template__c = :assetID AND Asset_Template__r.Asset_Class__c = :irs AND Do_we_have_Markitwire_permissions__c != null AND Do_we_have_Markitwire_permissions__c != 'Yes' ORDER BY CreatedDate ASC];//NOSONAR

    String errorText = NONE;
    if(lProds != null && !lProds.isEmpty()) {
      errorText = Label.E_Commerce_ddff_alert;
    }
    return errorText;
  }

  private static String getMurex(String assetID) {
    String irs;
    irs = 'IRS';
    final List<Asset_Product__c> lProds = [SELECT id, Product__c, Asset_Template__r.Status__c FROM Asset_Product__c WHERE Asset_Template__c = :assetID AND Asset_Template__r.Asset_Class__c = :irs AND Is_the_STP_Markitwire_Murex_in_place__c != null AND Is_the_STP_Markitwire_Murex_in_place__c != 'Yes' ORDER BY CreatedDate ASC]; //NOSONAR

    String errorText = NONE;
    if(lProds != null && !lProds.isEmpty()) {
      errorText = Label.E_Commerce_murex_alert;
    }
    return errorText;
  }

  private static String getDesignationAlert(String assetID) {
    String fxS;
    fxS = 'FX';
    final List<Asset_Product__c> lProds = [SELECT id, Is_client_using_a_Prime_Broker_PB__c, Asset_Template__r.Status__c FROM Asset_Product__c WHERE Asset_Template__c = :assetID AND Asset_Template__r.Asset_Class__c = :fxS AND Is_client_using_a_Prime_Broker_PB__c = 'Yes' AND (Asset_Template__r.Status__c = 'Review' OR Asset_Template__r.Status__c = 'New') ORDER BY CreatedDate ASC];

    String errorText = NONE;
    if(lProds != null && !lProds.isEmpty()) {
      errorText = Label.E_Commerce_designation;
    }
    return errorText;
  }
}