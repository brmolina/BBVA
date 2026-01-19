/**
* ------------------------------------------------------------------------------------------------
* @Name     CGMT_page_Local_Portfolio_Controller
* @Author   Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
* @Date     2025-04-25
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase controller para el LWC local porfolio
* -----------------------------------------------------------------------------------------------
* @Changes
* 
* -----------------------------------------------------------------------------------------------
*/
public with sharing class CGMT_page_Local_Portfolio_Controller {
             
    @AuraEnabled(cacheable=true)
    public static String getClient(Id accountId){
        /**
    *-------------------------------------------------------------------------------------------------------
    * @Description funcion que invoca al service para obtener DES_Group_Code__c
    *-------------------------------------------------------------------------------------------------------
    * @Author      Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
    * @Date        2025-04-25
    * @param       Id accountId - Id del Account donde se hara la consulta
    * @return      CGMT_page_Local_Portfolio_Service.getGroupCode(accountId) - Retorna el valor de DES_Group_Code__c
    * @example     getClient(accountId)
    **/
        return CGMT_page_Local_Portfolio_Service.getGroupCode(accountId);
    }
}