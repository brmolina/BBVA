/**********************************************************************************************************
 * @name            CUCO_Utils
 * @author          David Díaz
 * @created         05/08/2025
 * @description     Clase utilitaria que proporciona métodos de ayuda para operaciones comunes en Apex.
 **********************************************************************************************************/
public with sharing class CUCO_Utils {

    /**********************************************************************************************************
    * @name            Constructor
    * @author          David Díaz
    * @created         05/08/2025
    * @description     Método Constructor de la clase para evitar errores de SONAR
    **********************************************************************************************************/

    public CUCO_Utils() {

    }
    
    /**********************************************************************************************************
    * @name            getPicklistLabel
    * @author          David Díaz
    * @created         05/08/2025
    * @description     Método que obtiene la etiqueta asociada a un valor de un campo picklist de un objeto dado.
    * @param           String targetSObjetc - Nombre del objeto SObject.
    * @param           String targetPicklistField - Nombre del campo picklist.
    * @param           String value - Valor del picklist para el cual se desea obtener la etiqueta.
    * @return          String - Etiqueta correspondiente al valor del picklist.
    **********************************************************************************************************/

    public static String getPicklistLabel (String targetSObjetc, String targetPicklistField, String value){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = globalDescribe.get(targetSObjetc);
        Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fieldsMap.get(targetPicklistField).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        String labelValue = '';
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.getValue() == value) {
                labelValue = entry.getLabel();
                break;
            }
        }
        return labelValue;
    }
}