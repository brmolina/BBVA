/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ButtonsCMP_service
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-03-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description this class is the controller for the table.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-03-30  juanignacio.hita.contractor@bbva.com
*              Class creation.
* |2020-05-11  juanmanuel.perez.ortiz.contractor@bbva.com
*              Add subprocess modificacion in logic in getNameBtnCollection method
* |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
*             Update getArceAnalysisData method for Hu Renovation
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ButtonsCMP_service {
  /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		31/03/2020
    * @author	juanignacio.hita.contractor@bbva.com
  */
  @TestVisible
  private Arc_Gen_ButtonsCMP_service() {

  }
  /**
    *-------------------------------------------------------------------------------
    * @description Return the button collection for the type of analysis that has the aha
    *--------------------------------------------------------------------------------
    * @date 30/03/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param Id recordId
    * @return String
  */
  public static String getNameBtnCollection(Id recordId) {
    String buttonCollection = '';
    final List<arce__Analysis__c> lstAnlys = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id> {recordId});
    if (!lstAnlys.isEmpty()) {
      final String subProcess = lstAnlys[0].arce__anlys_wkfl_sub_process_type__c;
      if (subProcess == arce.Arc_Gen_Constants.SUBPROCESS_NEW || subProcess == arce.Arc_Gen_Constants.SUBPROCESS_MODIFICATION || subProcess == arce.Arc_Gen_Constants.SUBPROCESS_RENOVATION) {
        buttonCollection = 'Arc_Gen_ButtonPanel';
      } else if (subProcess == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
        buttonCollection = 'Arc_Gen_RAIPPanel';
      }
    }
    return buttonCollection;
  }
}