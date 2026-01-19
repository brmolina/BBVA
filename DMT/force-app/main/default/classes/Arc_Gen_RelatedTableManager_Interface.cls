/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_RelatedTableManager_Interface
  * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-11-10
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Interface class of RelatedTableManager classes
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  **/
public interface Arc_Gen_RelatedTableManager_Interface {
    /**
    *
    * @Description : saveCombos Method
    */
    arce.Arc_Gen_ServiceAndSaveResponse saveCombos(String recordId, String value, String combo);
}