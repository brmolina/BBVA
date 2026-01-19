/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Extension for DiscardAlertLocal Visualforce
**********************************************************************************/
public class DiscardAlertsExtensionLocal { //NOSONAR
  /*
  * StandardControler
  */
  ApexPages.StandardSetController setCon;
  /*
  * alertsIds
  */
  public String alertsIds {get; set;}

  /**
  * @author Global Desktop
  * @description Constructor
  */
  public DiscardAlertsExtensionLocal(ApexPages.StandardSetController controller) {
    setCon = controller;
    final List<Id> setAlerts = new List<Id>();
    for(altm__Commercial_Alert__c ale : (altm__Commercial_Alert__c[])setCon.getSelected()) {
      setAlerts.add(ale.Id);
    }
    alertsIds = JSON.serialize(setAlerts);
  }
}