global with sharing class NONC_SelectorPageNonClient_ctlr {

  /**
  * @description Get recordtypes Prospect
  * @return JSON for the radio button
  **/
  @AuraEnabled
  global static string getJSONRecordType() {

    List<String> lRecordTypes = new List<String>();
    for(RecordTypeInfo info: Account.SObjectType.getDescribe().getRecordTypeInfos()) {
      if(info.isAvailable()) {
          lRecordTypes.add(info.developerName);
      }
    }

    String resultJSON = 'oneRecordType';
    List<WrapperField> lresult = new List<WrapperField>();
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    final String recordType = nonClientCS.Non_Client_RecordType__c;
    final String addRecordType = nonClientCS.Additional_Non_Client_RecordType__c;

    List<RecordType> lRType = [SELECT id, DeveloperName, Name FROM RecordType WHERE (DeveloperName = :recordType OR DeveloperName = :addRecordType) AND DeveloperName IN :lRecordTypes LIMIT 2];
    if(lRType != null && !lRType.isEmpty()) {
      for(RecordType rtype : lRType){
        lresult.add(new WrapperField(rtype.name, rtype.DeveloperName == addRecordType?'true':'false'));
      }
    }

    resultJSON = getResultJSON(lresult, lRType, addRecordType, recordType);

    return resultJSON;
  }

  private static string getResultJSON(List<WrapperField> lresult, List<RecordType> lRType, String addRecordType, String recordType) {
    String resultJSON = 'oneRecordType';
    if(lRType == null || lRType.size() == 0) {
      resultJSON = 'emptyRecordType';
    }
    else {
      resultJSON = lRType.size()>1 ? JSON.serialize(lresult) : lRType.size() == 1 && lRType.get(0).DeveloperName == addRecordType?'oneRecordType||'+lRType.get(0).Name+'||true':'oneRecordType||'+lRType.get(0).Name+'||false';
    }
    return resultJSON;
  }

  /**
  * @description Wrapper with the Recordtypes
  **/
  public class WrapperField {
    private String label;
    private String value;

    public WrapperField () {
      System.debug('Empty constructor');
    }
    public WrapperField (String label, String value) {
      this.label = label;
      this.value = value;
    }
  }
}