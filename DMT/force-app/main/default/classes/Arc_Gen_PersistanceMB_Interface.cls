/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceMB_Interface
* @Author   berthaelena.tellez.contractor@bbva.com
* @Date     Created: 19/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Interface "Arc_Gen_PersistanceMB_Interface"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-19 berthaelena.tellez.contractor@bbva.com
*             Interface creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_PersistanceMB_Interface {
    /**
    *
    * @Description : get buro table Json string
    */
    String createBureauTable (String idArce);
    /**
    *
    * @Description : get financial system Json string
    */
    String createfinacialSystem(String idArce,List<sObject>listObject);
}