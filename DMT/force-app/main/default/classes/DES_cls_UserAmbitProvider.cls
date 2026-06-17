/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Provider encargado de cargar y exponer la configuración
 *               de Ambits desde Custom Metadata (Arce_ambit_hierarchy__mdt).
 *
 *               RESPONSABILIDAD:
 *               • Consultar los registros de Arce_ambit_hierarchy__mdt.
 *               • Construir un Map<String, Arce_ambit_hierarchy__mdt>.
 *               • Cachear el resultado en memoria durante la transacción.
 *
 * ARQUITECTURA 2026:
 *  • Extraído desde User_Helper como parte del refactor a patrón Facade + Services.
 *  • Implementa cache estática para evitar múltiples queries en la misma ejecución.
 *  • Separa acceso a datos (metadata) de la lógica de negocio.
 *
 * CLAVE DEL MAPA:
 *  Region__c + ' - ' + Level__c + ' - ' + Description__c
 *
 * CONSIDERACIONES:
 *  • Si existen duplicados de clave, se conserva el primer registro encontrado.
 *  • No realiza DML.
 *  • Diseñado para ser usado en contexto before trigger.
 *
 ***************************************************************************************/
public with sharing class DES_cls_UserAmbitProvider{
    /*
     * Cache estática en memoria.
     * Se mantiene durante toda la transacción.
     */
    private static Map<String, Arce_ambit_hierarchy__mdt> cache;

    /***************************************************************************************
     * @description  Devuelve el mapa de Ambits.
     *               Si no está inicializado, ejecuta la carga desde metadata.
     *
     * @return       Map<String, Arce_ambit_hierarchy__mdt>
     ***************************************************************************************/
    public static Map<String, Arce_ambit_hierarchy__mdt> getMap(){

        if (cache == null){
            cache = loadMetadata();
        }

        return cache;
    }

    /***************************************************************************************
     * @description  Consulta los registros de Arce_ambit_hierarchy__mdt
     *               y construye el mapa clave → metadata.
     *
     *               La clave se compone de:
     *               Region - Level - Description
     *
     *               Si Description es null o blank:
     *               Region - Level -
     *
     * @return       Map<String, Arce_ambit_hierarchy__mdt>
     ***************************************************************************************/
    private static Map<String, Arce_ambit_hierarchy__mdt> loadMetadata(){

        Map<String, Arce_ambit_hierarchy__mdt> result = new Map<String, Arce_ambit_hierarchy__mdt>();

        for (Arce_ambit_hierarchy__mdt ambit : [SELECT DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
                                                FROM Arce_ambit_hierarchy__mdt]){

            String key = ambit.Region__c + ' - ' + ambit.Level__c + (String.isBlank(ambit.Description__c) ? ' -' : 
                                         ' - ' + ambit.Description__c);

            /*
             * Se evita sobrescribir claves duplicadas.
             * Se conserva el primer registro encontrado.
             */
            if (!result.containsKey(key)){
                result.put(key, ambit);
            }
        }

        return result;
    }

}