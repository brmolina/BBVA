/**********************************************************************************
* @author       Global Desktop
* @date         20/01/2021
* @description  Extension for CompleteAlleSales Visualforce
**********************************************************************************/
public class CompleteAlleSalesExtension {
    /*
    * StandardControler
    */
    ApexPages.StandardSetController setCon;
    /*
    * formsId
    */
    public String formsIds {get; set;}
  
    /**
    * @author Global Desktop
    * @description Constructor
    */
    public CompleteAlleSalesExtension(ApexPages.StandardSetController controller) {
      setCon = controller;
      final List<Id> setForms = new List<Id>();
      for(Asset_Template__c form : (Asset_Template__c[])setCon.getSelected()) {
        setForms.add(form.Id);
      }
      formsIds = JSON.serialize(setForms);
    }
  }