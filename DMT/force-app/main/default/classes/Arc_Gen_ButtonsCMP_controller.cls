/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ButtonsCMP_controller
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
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ButtonsCMP_controller {
  /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		31/03/2020
    * @author	juanignacio.hita.contractor@bbva.com
  */
  @TestVisible
  private Arc_Gen_ButtonsCMP_controller() {

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
  @AuraEnabled
  public static String getBtnCollection(Id recordId) {
    try {
      return Arc_Gen_ButtonsCMP_service.getNameBtnCollection(recordId);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e.getMessage()); //NOSONAR
    }
  }
}