/**
*Name:            ManagerFranchise_TriggerHandler
*Description:     Class with ManagerFranchise_Trigger custom methods
*Test Class:      -
*
*Version        Date            Author            Summary of changes
*--------------------------------------------------------------------------------------------------------------------------------
*0.1            19/02/2019      JSS        		 Class creation
*0.2            2019/01/31      JSS            Cuando se crea el ManagerFranchise se añaden los campos de Global Markets (Area, Business Line, Country)
*0.3            2019/02/28      JSS            Cuando se crea el ManagerFranchise se añade un nuevo campo de Global Markets (Product)
*/
public with sharing class ManagerFranchise_TriggerHandler {

  /*
  * @author Global Desktop
  * @Description Método que copia el valor de los campos de GM del usuario a los campos GM del ManagerFranchise
  */
  public void setVisitGMFields(List<Manager_Franchise__c> triggerNew) {
    final set<String> idUserList = new set<String>();
  	for(Manager_Franchise__c mf : triggerNew) {
      idUserList.add(mf.Account_Manager_Code__c);
    }
    final List<User> userList = new List<User>([Select Id, ID_User__c, Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, solution_name_path_desc__c FROM User Where ID_User__c IN :idUserList]);
    final Map<String,User> userMap = new Map<String,User>();
    for(User currentUser : userList) {
      	userMap.put(currentUser.ID_User__c,currentUser);
    }
    for(Manager_Franchise__c mf : triggerNew) {
      mf.Business_area_desc__c = ( userMap.containsKey(mf.Account_Manager_Code__c) ? userMap.get(mf.Account_Manager_Code__c).Business_area_desc__c : Label.DES_SCOPE_GLOBAL );
      mf.Business_line_desc__c = ( userMap.containsKey(mf.Account_Manager_Code__c) ? userMap.get(mf.Account_Manager_Code__c).Business_line_desc__c : Label.DES_SCOPE_GLOBAL );
      mf.coverage_country_name__c = ( userMap.containsKey(mf.Account_Manager_Code__c) ? userMap.get(mf.Account_Manager_Code__c).coverage_country_name__c : Label.DES_SCOPE_GLOBAL );
      mf.solution_name_path_desc__c = ( userMap.containsKey(mf.Account_Manager_Code__c) ? userMap.get(mf.Account_Manager_Code__c).solution_name_path_desc__c : Label.DES_SCOPE_GLOBAL );
    }

  }//Fin setVisitGMFields
}