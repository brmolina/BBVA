/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Servicio responsable de aplicar la lógica funcional de Ambits
 *               sobre el objeto User.
 *
 *               FUNCIONALIDAD:
 *               • Obtiene la configuración de Ambits desde DES_cls_UserAmbitProvider.
 *               • Evalúa el ambit asignado al usuario.
 *               • Actualiza los flags funcionales en el registro User:
 *                   - DES_ARCE_Can_Propose__c
 *                   - DES_ARCE_Can_Validate__c
 *                   - DES_ARCE_Can_Edit__c
 *
 * ARQUITECTURA 2026:
 *  • Extraído desde User_Helper bajo patrón Facade + Service.
 *  • Separa la lógica de negocio de la carga de metadata.
 *  • Bulk-safe (opera sobre listas de usuarios).
 *
 * DEPENDENCIAS:
 *  • DES_cls_UserAmbitProvider
 *  • Arce_ambit_hierarchy__mdt
 *
 * CONSIDERACIONES:
 *  • No realiza DML.
 *  • Diseñado para ejecutarse en contexto before insert / before update.
 *  • Si el usuario no tiene Ambit válido, los flags se establecen a FALSE.
 *
 ***************************************************************************************/
public with sharing class DES_cls_UserAmbitService{
    /***************************************************************************************
     * @description  Aplica la lógica de permisos en base al Ambit configurado
     *               en el usuario.
     *
     *               Lógica:
     *               1. Obtiene el mapa de Ambits desde el Provider.
     *               2. Recupera el metadata correspondiente al valor
     *                  gf_user_operation_ambit_name__c.
     *               3. Establece los flags funcionales en el User.
     *
     * @param        users  Lista de usuarios a procesar (bulk-safe).
     ***************************************************************************************/
    public static void apply(List<User> users){

        if (users == null || users.isEmpty())
            return;
        Map<String, Arce_ambit_hierarchy__mdt> mapAmbit = DES_cls_UserAmbitProvider.getMap();

        for (User usr : users){

            Arce_ambit_hierarchy__mdt ambit = mapAmbit.get(usr.gf_user_operation_ambit_name__c);

            usr.DES_ARCE_Can_Propose__c = ambit != null && ambit.canPropose__c;
            usr.DES_ARCE_Can_Validate__c = ambit != null && ambit.canValidate__c;
            usr.DES_ARCE_Can_Edit__c = ambit != null && ambit.canEdit__c;
        }
    }

}