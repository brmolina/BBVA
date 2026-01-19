/**
 *
 * @author Global Desktop
 */
public with sharing class NPS_GetContactsOwner_Controller {
  /**
   * @author Global Desktop
   * @description URL de la list view My NPS Contacts
   */
  public String listViewURL {get; set;}

  /**
   * @author Global Desktop
   * @description Constructor
   */
  public NPS_GetContactsOwner_Controller() {
    final List<ListView> listListView = [SELECT Id,
                                          Name,
                                          SobjectType
                                        FROM ListView WHERE Name = 'My NPS Contacts'];
    listViewURL = System.URL.getOrgDomainUrl().toExternalForm() + '/lightning/o/Contact/list?filterName=' + listListView[0].Id;
  }
}