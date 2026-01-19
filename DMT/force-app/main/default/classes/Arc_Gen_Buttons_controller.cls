/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Buttons_controller
* @Author   BBVA Developers
* @Date     Created: 2019-11-04
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description this class is the controller for the table.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-10-04 BBVA Developers.
*              Class creation.
* |2019-08-29 mariohumberto.ramirez.contractor@bbva.com
*              Added new param "apiNameObject" and logic in order to build a generic JSON for all
*              tables in dynamic form
* |2019-11-04 BBVA Developers.
*              Modify logic for Related Record adaption
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*              API names modified with the correct name on Business Glossary
* |2020-01-13 franciscojavier.bueno@bbva.com
*              Shareholding field must not control that it adds up to 100%, or does not exceed 100%
* |2020-03-20 joseluis.garcia4.contractor@bbva.com
*              Adds attribute to hide "Reset" button on RRTM forms.
* |2020-06-18 manuelhugo.castillo.contractor@bbva.com
*              Add logic Bottom Up in case 'Main_affiliates', method 'getButtonsJsonComponent'
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-26 joseluis.garcia4.contractor@bbva.com
*              Handle empty TDBU indicator for historical ARCEs.
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			      Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			      Added annotation '@testVisible' to the empty constructor method.
* |2021-05-11 ronald.pisco.contractor@bbva.com
*             Change rrtm:RelatedRecordTableManager for arce:Arc_Gen_RRTM_Wrapper and add parameters
* |2021-05-19 ronald.pisco.contractor@bbva.com
*             Add Wrapper class and generateButton method
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback 2020-03-12 commit  (PR: 1231)
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_Buttons_controller {
  /**
  *-------------------------------------------------------------------------------
  * @description Empty constructor method
  *-------------------------------------------------------------------------------
  *@author otiliaramona.veres.contractor@bbva.com
  *@date 2021-04-30
  */
  @TestVisible
  private Arc_Gen_Buttons_controller() { }
  /**
  *private constant for arce__anlys_wkfl_cnsld_ffss_type__c value
  **/
  private final static String BOTTOM_UP = '1';
  /**
  *private class Wrapper for only access on outer class
  **/
  private class ButtonsWrapper {
    /**
    *private attribute for only access on outer class
    **/
    private String collectionType {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String recordId {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String apiNameObject {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String relatedField {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String fieldSeeker {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String fieldsApiName {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String modalCss {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String messageBar {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String hrefMsgBar {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String infoMsgBar {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String headerLabels {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String validateClass {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String filterTable {get;set;}
    /**
    *private attribute for only access on outer class
    **/
    private String collectTypeLabel {get;set;}
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description class that contains the config of the table_content_per_analysis.
  * @param collectionType string to configure labels
  * @param recordId of the account
  * @param apiNameObject of the object
  * @return returns a json formated with the configurations of the buttons.
  * @example getButtonsJsonComponent(String collectionType, String recordId, String apiNameObject)
  **/
  public static String getButtonsJsonComponent(String collectionType, String recordId, String apiNameObject) {
    final ButtonsWrapper btnWrapper =  new ButtonsWrapper();
    btnWrapper.filterTable = 'RecordType.Developername=\''+collectionType+'\'';
    btnWrapper.recordId = recordId;
    btnWrapper.infoMsgBar = '';
    btnWrapper.headerLabels = ',';
    final ButtonsWrapper fillWrapper =  switchOnCollectionType(collectionType, btnWrapper);
    return generateButton(fillWrapper, collectionType, apiNameObject);
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns the String json.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a json formated with the configurations of the buttons.
  * @example generateButton(ButtonsWrapper btnWrapper)
  **/
  private static String generateButton(ButtonsWrapper btnWrapper, String collectionType, String apiNameObject) {
    btnWrapper.collectTypeLabel = Schema.getGlobalDescribe().get(apiNameObject).getDescribe().getRecordTypeInfosByDeveloperName().get(collectionType).getName();
    return '{'+
                      '"name": "arce:Arc_Gen_RRTM_Wrapper",'+
                      '"inModalFromButton": {'+
                      '"labelButton": "' + Label.Arc_Gen_ManageRecords + ' ' + btnWrapper.collectTypeLabel + '",'+
                      '"editMode": true,'+
                      '"variantButton": "neutral",'+
                      '"modalCss": "'+btnWrapper.modalCss+'",'+
                      '"iconButton": "",'+
                      '"positionButton": "left",'+
                      '"headerModal": "' + Label.Arc_Gen_ManageRecords + ' ' + btnWrapper.collectTypeLabel + '",'+
                      '"closeButtonModal": true,'+
                      '"closeModalActionEvt":{'+
                      '"name":"cmpw:GBL_ComponentWrapperRefresh_Evt",'+
                      '"attributes": {"uniqueNameEvt":"'+collectionType+'"}'+
                      '}'+
                      '},'+
                      '"attributes": {'+
                      '"fieldsApiName":"'+btnWrapper.fieldsApiName+'",'+
                      '"relatedName":"'+btnWrapper.relatedField+'",'+
                      '"sObjectType":"'+apiNameObject+'",'+
                      '"recordTypeName":"'+collectionType+'",'+
                      '"filterTable":"'+btnWrapper.filterTable+'",'+
                      '"customMetadata":"Arc_Gen_'+collectionType+'",'+
                      '"fieldSeeker":"'+btnWrapper.fieldSeeker+'",'+
                      '"headerLabels":"'+btnWrapper.headerLabels+'",'+
                      '"hideResetButton":true,'+
                      '"readOnly":false,'+
                      '"recordId":"'+btnWrapper.recordId+'",'+
                      '"infoMsgBar":"'+btnWrapper.infoMsgBar+'",'+
                      '"messageBar":"'+btnWrapper.messageBar+'",'+
                      '"hrefMsgBar":"'+btnWrapper.hrefMsgBar+'",'+
                      '"apexClassSave":"'+btnWrapper.validateClass+'"}}';
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @param collectionType contains String to evaluate in switch
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchOnCollectionType(String collectionType, ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchOnCollectionType(String collectionType, ButtonsWrapper btnWrapper) {
    ButtonsWrapper tempWrapper;
    switch on collectionType {
      when 'Geographies', 'Activities' {
        tempWrapper = switchGeographiesActivities(btnWrapper);
        }
      when 'Shareholders' {
        tempWrapper = switchShareholders(btnWrapper);
        }
      when 'Main_clients','Main_suppliers' {
        tempWrapper = switchMainClientsMainSuppliers(btnWrapper);
        }
      when 'Main_affiliates' {
        tempWrapper = switchMainAffiliatess(btnWrapper);
        }
      when 'Main_Banks' {
        tempWrapper = switchMainBanks(btnWrapper);
      }
      when 'Maturity_table' {
        tempWrapper = switchMaturityTable(btnWrapper);
      }
    }
    return tempWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchGeographiesActivities(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchGeographiesActivities(ButtonsWrapper btnWrapper) {
    btnWrapper.relatedField = 'arce__Table_Content_per_Analysis__r';
    btnWrapper.fieldsApiName = 'arce__Data_Collection_Id__c,arce__table_content_year__c,arce__table_content_percentage__c';
    btnWrapper.fieldSeeker = 'arce__Data_Collection_Id__c';
    btnWrapper.validateClass = 'Arc_Gen_ValidateContent_service';
    return btnWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchShareholders(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchShareholders(ButtonsWrapper btnWrapper) {
    btnWrapper.relatedField = 'arce__third_participant_details__r';
    btnWrapper.fieldsApiName = 'arce__Third_Participant_id__c,arce__third_participant_per__c,arce__shrhldr_financial_sponsor_type__c,arce__shareholder_sponsor_year_id__c';
    btnWrapper.fieldSeeker = 'arce__Third_Participant_id__c';
    btnWrapper.modalCss = 'slds-modal_small';
    btnWrapper.validateClass = 'Arc_Gen_ValidateShareholders_service';
    btnWrapper.filterTable += 'ORDER BY arce__third_participant_desc__c ASC';
    btnWrapper.headerLabels = ',Arc_Gen_ColumnHeader_Shareholder_Participation,Arc_Gen_ColumnHeader_Shareholder_FinancialSponsor,';
    return btnWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchMainClientsMainSuppliers(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchMainClientsMainSuppliers(ButtonsWrapper btnWrapper) {
    btnWrapper.relatedField = 'arce__third_participant_details__r';
    btnWrapper.fieldsApiName = 'arce__Third_Participant_id__c,arce__third_participant_per__c,arce__gf_customer_cif_id__c,arce__gf_group_id__c,arce__gf_group_name__c';
    btnWrapper.fieldSeeker = 'arce__Third_Participant_id__c';
    btnWrapper.modalCss = 'slds-modal_large';
    btnWrapper.validateClass = 'Arc_Gen_ValidateThirdParticipant_service';
    btnWrapper.messageBar = Label.Arc_Gen_Connected_Clients_Disclaimer;
    btnWrapper.hrefMsgBar = Label.Arc_Gen_Connected_Clients_Link;
    btnWrapper.infoMsgBar = 'true';
    return btnWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchMainAffiliatess(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchMainAffiliatess(ButtonsWrapper btnWrapper) {
    final List<arce__Account_has_Analysis__c> ahaTDBU = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{btnWrapper.recordId});
    btnWrapper.relatedField = 'arce__third_participant_details__r';
    if(ahaTDBU[0].arce__anlys_wkfl_cnsld_ffss_type__c == BOTTOM_UP || String.isEmpty(ahaTDBU[0].arce__anlys_wkfl_cnsld_ffss_type__c)) {
      btnWrapper.fieldsApiName = 'arce__Third_Participant_id__c,arce__third_participant_per__c,arce__economic_activity_sector_desc__c,arce__non_customer_type__c';
    } else {
      btnWrapper.fieldsApiName = 'arce__Third_Participant_id__c,arce__third_participant_per__c,arce__economic_activity_sector_desc__c,arce__consolidation_method_id__c,arce__non_customer_type__c';
    }
    btnWrapper.fieldSeeker = 'arce__Third_Participant_id__c';
    btnWrapper.modalCss = 'slds-modal_large';
    btnWrapper.validateClass = 'Arc_Gen_ValidateTablePermissions_service';
    btnWrapper.filterTable += 'ORDER BY arce__third_participant_desc__c ASC';
    return btnWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchMainBanks(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchMainBanks(ButtonsWrapper btnWrapper) {
    btnWrapper.relatedField = 'arce__Main_Banks__r';
    btnWrapper.fieldsApiName = 'arce__entity_name__c, arce__entity_quota_share_per__c';
    btnWrapper.fieldSeeker = '';
    btnWrapper.validateClass = 'Arc_Gen_ValidateMainBanks_service';
    return btnWrapper;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @description method that returns ButtonsWrapper from switch statement.
  * @param btnWrapper contains all parameters in one wrapper
  * @return returns a ButtonsWrapper variable with fields fills.
  * @example switchMaturityTable(ButtonsWrapper btnWrapper)
  **/
  private static ButtonsWrapper switchMaturityTable(ButtonsWrapper btnWrapper) {
    btnWrapper.relatedField = 'arce__Table_Content_per_Analysis__r';
    btnWrapper.fieldsApiName = 'arce__Data_Collection_Id__c,arce__table_content_year__c,arce__table_content_value__c';
    btnWrapper.fieldSeeker = 'arce__Data_Collection_Id__c';
    btnWrapper.validateClass = 'Arc_Gen_ValidateContentMaturity_service';
    return btnWrapper;
  }
}