/**
  * @File Name          :   public with sharing class Arc_Gen_Remove_Controller.cls
  * @Description        : Controller class for the remove functionality
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : juanignacio.hita.contractor@bbva.com
  * @Last Modified On   : 15/9/2020 10:00:00
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    5/7/2019 12:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
  * 1.1    6/21/2019 12:50:32  ismaelyovani.obregon.contractor@bbva.com     Sanction 1.0 Q3 Added Method that gets value of picklist.
  * 1.2    13/7/2020 16:30:00  joseluis.garcia4.contractor@bbva.com         Add check for edit permissions.
  * 1.3    18/8/2020 10:00:00  joseluis.garcia4.contractor@bbva.com         Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
  * 1.4    15/9/2020 10:00:00  juanignacio.hita.contractor@bbva.com         Remove try/catch block of getDiscardList method
  * 1.5    23/9/2020     saimassimilianno.jordana.contractor@bbva.com      Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.6    30/4/2021     otiliaramona.veres.contractor@bbva.com            Added an empty constructor method.
  * 1.7    04/5/2021     otiliaramona.veres.contractor@bbva.com            Added annotation '@testVisible' to the empty constructor method.
  **/
public with sharing class Arc_Gen_Remove_Controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_Remove_Controller() { }
    /**
    *-------------------------------------------------------------------------------
    * @description set new values for arce
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com
    * @date 20/05/2019
    * @param String recordId of the arce to update status
    * @param String reason for the update
    * @return List < arce__Account_has_Analysis__c >
    * @example public static void updateStatusController(String recordId)
    **/
  @AuraEnabled
  public static void updateRemoveInfo(Id recordId,String reasonPick, String reasonDesc, String reasonPickLabel) {
    if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Remove')) {
      throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
    }

    try {
        Arc_Gen_Remove_Service.updateRemoveInfo(recordId, reasonPick, reasonDesc, reasonPickLabel);
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
  }
    /**
    *-------------------------------------------------------------------------------
    * @description get discard reasons picklist values.
    --------------------------------------------------------------------------------
    * @author ismaelyovani.obregon.contractor@bbva.com
    * @date 21/06/2019
    * @param void
    * @return List<map<String,String>> of pick list values and labels
    * @example List<map<String,String>> getDiscardList()
    **/
  @AuraEnabled
  public static List<map<String,String>> getDiscardList(String varObject,String varField) {
      List<map<String,String>> listReasons = Arc_Gen_Remove_service.getDiscardReasons();
      return listReasons;
  }
}