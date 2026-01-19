/*********************************************************************************************************
 * @name            DES_BatchUpdatedPrflUsers
 * @author          Capgemini
 * @created         21/05/2025
 * @description     Clase Batchable que actualiza usuarios de Salesforce de forma masiva en base a su FederationIdentifier.
 *                  Permite ejecución selectiva sobre una lista específica de usuarios, o sobre todos los que
 *                  cumplen condiciones predeterminadas. Utiliza DES_SamlJitHandler para actualizar.
 *********************************************************************************************************/
public with sharing class DES_BatchUpdatedPrflUsers implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private Set<Id> userIds;

    /*********************************************************************************************************
     * @name            DES_BatchUpdatedPrflUsers
     * @author          Capgemini
     * @created         21/05/2025
     * @description     Constructor que permite ejecutar el batch sobre una lista concreta de usuarios.
     * @param           List<User> users - Lista de usuarios con ID válidos para filtrar la ejecución.
     *********************************************************************************************************/
    public DES_BatchUpdatedPrflUsers(List<User> users) {
        this.userIds = new Set<Id>();
        if (users != null && !users.isEmpty()) {
            for (User u : users) {
                this.userIds.add(u.Id);
            }
        }
    }

    /*********************************************************************************************************
     * @name            start
     * @author          Capgemini
     * @created         21/05/2025
     * @description     Método que devuelve el conjunto de registros a procesar. Si se ha proporcionado una lista
     *                  de usuarios, se filtran por sus IDs; de lo contrario, se usan condiciones predefinidas.
     * @param           Database.BatchableContext bc - Contexto de ejecución del batch.
     * @return          Database.QueryLocator - Conjunto de usuarios a procesar.
     *********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('### Start DES_BatchUpdatedPrflUsers ###');
        String query;
        if (this.userIds.isEmpty()) {
            query = 'SELECT Id, FederationIdentifier FROM User WHERE IsActive = true AND ID_User__c != null AND FederationIdentifier != null';
        } else {
            query = 'SELECT Id, FederationIdentifier FROM User WHERE IsActive = true AND ID_User__c != null AND FederationIdentifier != null AND Id IN :userIds';
        }
        return Database.getQueryLocator(query);
    }

    /*********************************************************************************************************
     * @name            execute
     * @author          Capgemini
     * @created         21/05/2025
     * @description     Método que se ejecuta por cada lote de registros. Actualiza cada usuario utilizando el
     *                  handler DES_SamlJitHandler con su FederationIdentifier.
     * @param           Database.BatchableContext bc - Contexto del lote actual.
     * @param           List<SObject> scope - Lista de usuarios a procesar en este lote.
     *********************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('### Execute DES_BatchUpdatedPrflUsers ###');
        List<User> users = (List<User>) scope;

        for (User u : users) {
            if (u.FederationIdentifier != null) {
                try {
                    DES_SamlJitHandler handler = new DES_SamlJitHandler();
                    handler.updateUser(u.Id, null, null, null, u.FederationIdentifier, new Map<String, String>(), null);
                } catch (Exception e) {
                    System.debug('Error actualizando usuario ' + u.Id + ': ' + e.getMessage());
                }
            }
        }
    }

    /*********************************************************************************************************
     * @name            finish
     * @author          Capgemini
     * @created         21/05/2025
     * @description     Método final que se ejecuta una vez completado el procesamiento de todos los lotes.
     *                  Puede utilizarse para notificaciones o tareas de cierre.
     * @param           Database.BatchableContext bc - Contexto del batch.
     *********************************************************************************************************/
    public void finish(Database.BatchableContext bc) {
    }
}