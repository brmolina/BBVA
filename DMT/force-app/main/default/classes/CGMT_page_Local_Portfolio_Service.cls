/**
* ------------------------------------------------------------------------------------------------
* @Name     CGMT_page_Local_Portfolio_Service
* @Author   Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
* @Date     2025-04-25
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase Service para consultar el valor de DES_Group_Code__c de account
* -----------------------------------------------------------------------------------------------
* @Changes
* 
* -----------------------------------------------------------------------------------------------
*/
public with sharing class CGMT_page_Local_Portfolio_Service {
    /**
    @Description Cadena con el mensaje de error si el id es null
    @Author      Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
    **/
    final static String AccountError = 'El accountId no puede ser nulo';
    
    public static String getGroupCode(Id accountId) {
         /**
    *-------------------------------------------------------------------------------------------------------
    * @Description funcion que hace la consulta para obtener DES_Group_Code__c 
    *-------------------------------------------------------------------------------------------------------
    * @Author      Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
    * @Date        2025-04-25
    * @param       Id accountId - Id del Account donde se hara la consulta
    * @return      acc.DES_Group_Code__c - Retorna el valor de DES_Group_Code__c
    * @example     getGroupCode(accountId)
    **/
        if (accountId == null) {
            throw new AuraHandledException(AccountError);
        }

        Account acc = [SELECT Id, DES_Group_Code__c FROM Account WHERE Id = :accountId LIMIT 1];

        return acc.DES_Group_Code__c;
    }
}