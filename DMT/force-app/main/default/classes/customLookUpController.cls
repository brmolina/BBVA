/******************************************************************************
 * @name        customLookUpController
 * @author      Global Desktop
 * @created     2019
 * @description Controlador para búsquedas personalizadas en componentes Lightning.
 * @group       Global Desktop
 * @version     1.0
 ******************************************************************************/
public with sharing class customLookUpController{
     //NOSONAR
    /**********************************************************************************************************
     * @name        fetchLookUpValues
     * @author      Global Desktop
     * @created     2019
     * @description Busca registros de un objeto permitido usando criterios dinámicos y seguros.
     * @param       searchKeyWord   Palabra clave para buscar.
     * @param       ObjectName      Nombre del objeto a consultar (validado).
     * @param       productFamily   Familia de producto (opcional).
     * @param       custom          Si la búsqueda es personalizada.
     * @param       equals          Si la búsqueda es por igualdad exacta.
     * @param       searchField     Campo sobre el que buscar (validado).
     * @param       ipUserFilter    Filtro adicional (opcional).
     * @return      List<sObject>   Lista de registros encontrados.
     **********************************************************************************************************/
    @AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String ObjectName, String productFamily, Boolean custom, Boolean equals, String searchField, String ipUserFilter){
        Set<String> allowedObjects = new Set<String>{ 'User', 'dwp_kitv__Visit__c', 'Opportunity', 'Product2', 'Contact', 'Account', 'pith__Pitch__c' };
        if (!allowedObjects.contains(ObjectName)){
            throw new AuraHandledException('Objeto no permitido');
        }
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();
        if (!fieldsMap.containsKey(searchField)){
            System.debug(LoggingLevel.WARN, 'customLookUpController.fetchLookUpValues - Campo no permitido. ObjectName=' + ObjectName + ', searchField=' + searchField);
            throw new AuraHandledException('Campo no permitido');
        }
        final String searchKey = searchKeyWord + '%';
        final List<sObject> returnList = new List<sObject>();
        try{
            List<String> queryFields = new List<String>{'Id'};
            if (searchField != 'Id') queryFields.add(searchField);

            String baseQuery = 'SELECT ' + String.join(queryFields, ', ') + ' FROM ' + ObjectName + ' WHERE ';
            String whereClause = '';
            Map<String, Object> bindVars = new Map<String, Object>();

            if (custom){
                if (equals){
                    whereClause = searchField + ' = :searchKeyWord';
                    bindVars.put('searchKeyWord', searchKeyWord);
                } else{
                    whereClause = searchField + ' LIKE :searchKey';
                    bindVars.put('searchKey', searchKey);
                }
                // No concatenar ipUserFilter, solo permitir filtros controlados
            } else{
                if (ObjectName == 'Product2'){
                    whereClause = 'Name LIKE :searchKey AND Family LIKE :productFamily';
                    bindVars.put('searchKey', searchKey);
                    bindVars.put('productFamily', productFamily + '%');
                } else if (ObjectName == 'User'){
                    whereClause = 'isActive = true AND Name LIKE :searchKey';
                    bindVars.put('searchKey', searchKey);
                } else{
                    whereClause = 'Name LIKE :searchKey';
                    bindVars.put('searchKey', searchKey);
                }
            }
            String sQuery = baseQuery + whereClause + ' ORDER BY createdDate DESC LIMIT 5';
            List<sObject> lstOfRecords = Database.query(sQuery);
            returnList.addAll(lstOfRecords);
            return returnList;
        } catch (Exception e){
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());
        }
    }

    /**********************************************************************************************************
     * @name        ipUserFilterEmpty
     * @author      Global Desktop
     * @created     2019
     * @description Devuelve el filtro de usuario si no es nulo, o cadena vacía si lo es.
     * @param       ipUserFilter    Filtro de usuario (puede ser nulo).
     * @return      String          Filtro o cadena vacía.
     **********************************************************************************************************/
    private static String ipUserFilterEmpty(String ipUserFilter){
         //NOSONAR
        String ipUserFilterAux = ipUserFilter;
        if (ipUserFilterAux == null){
            ipUserFilterAux = '';
        }
        return ipUserFilterAux;
    }

}