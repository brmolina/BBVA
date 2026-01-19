/**
  * @File Name : Arc_Gen_ArceDataModel_Interface.cls
  * @Description : Arce data model interface
  * @Author :   ARCE TEAM
  * @Group : ARCE - BBVA
  * @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Last Modified On : 02-03-2024
  *==============================================================================
  * Ver    Date       Author          Modification
  *==============================================================================
  * 1.0 22/03/2022   juanignacio.hita.contractor@bbva.com   Creation file
  **/
public with sharing class Arc_Gen_ArceDataModel_Locator {
  /**
  * @Description : configuration
  */
  static final String CONFIG = 'empPersistenceQualitativeIRP';
  /**
  * @Description : fields read only
  */
  static final List<String> FIELD_READ = new List<String>{'Name'};
  /**
    * @Description Private constructor to avoid sonar warnings.
  */
  private Arc_Gen_ArceDataModel_Locator() {}

  /**
    *-------------------------------------------------------------------------------
    * @description Method that get full fields aha ARCE DATA MODEL + Local Fields returned by interface
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    22/03/2022
    * @param   Id accHasId
    * @return  arce.Arc_Gen_Account_Has_Analysis_Wrapper wrapper
    * @example arce.Arc_Gen_Account_Has_Analysis_Wrapper aha = getFullFieldsAha(accHasId);
  **/
  public static arce.Arc_Gen_Account_Has_Analysis_Wrapper getFullFieldsAha(Id accHasId) {
    arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaFullObject = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String> { accHasId })[0];
    final Map<String, arce__Service_persistence__mdt> configsMap = Arc_Gen_Persistence_Utils.getConfigurationInfo(new List<String>{CONFIG});
    final Map<String, Object> ret = (Map<String, Object>) JSON.deserializeUntyped(configsMap.get(CONFIG).arce__JSON_input__c);
    final List<String> lstKeys = new List<String>();
    for (String key : ret.keySet()) {
        lstKeys.add(key.replace('ahaObj.', ''));
    }
    final String queryString = 'SELECT ' + String.join(lstKeys, ',') + ' FROM arce__Account_has_Analysis__c LIMIT 1';
    final List<arce__Account_has_Analysis__c> resultLocal = Database.query(String.escapeSingleQuotes(queryString));
    final arce__Account_has_Analysis__c ahaPost = ahaFullObject.ahaObj; // ARCE DATA MODEL FIELDS
    for (String field : lstKeys) {
      if (!FIELD_READ.contains(field) && field.contains('__c')) {
        ahaPost.put(field, resultLocal[0].get(field));
      }
    }
    ahaFullObject.ahaObj = ahaPost;
    return ahaFullObject;
  }
}