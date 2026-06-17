global with sharing class NONC_NonClientTabPage_ctlr {
  @AuraEnabled
    global static String getApiName() {
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      String returnValue = '';
      List <ListView> listviews = new List<ListView>();
      if(nonClientCS.List_View_Name__c != null && nonClientCS.List_View_Name__c.trim().length() > 0) {
        listviews = [SELECT Id, DeveloperName from ListView WHERE DeveloperName = :nonClientCS.List_View_Name__c];
      }else {
        throw new AuraHandledException(Label.Error + Label.NClient_lbl_NoListView);
      }
      if(listviews.size() > 0) {
        returnValue = listviews.get(0).DeveloperName;
      }
      return returnValue;
    }
}