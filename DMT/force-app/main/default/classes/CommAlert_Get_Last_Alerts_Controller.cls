/**********************************************************************************
* @author       Global Desktop
* @date         13/02/2020
* @description  Controller del componente de CommAlert_Get_Last_Alerts
**********************************************************************************/
public with sharing class CommAlert_Get_Last_Alerts_Controller {
  /**
  * @author Global Desktop
  * @description URL de la list view Last uploaded Alerts
  */
  public String listViewURL {get; set;}

  /**
  * @author Global Desktop
  * @description Constructor
  */
  public CommAlert_Get_Last_Alerts_Controller() {
    final List<ListView> listListView = [SELECT Id,
                                          Name,
                                          SobjectType
                                        FROM ListView WHERE Name = 'Last uploaded Alerts'];
    listViewURL = System.URL.getOrgDomainUrl().toExternalForm() + '/lightning/o/altm__Commercial_Alert__c/list?filterName=' + listListView[0].Id;
  }
}