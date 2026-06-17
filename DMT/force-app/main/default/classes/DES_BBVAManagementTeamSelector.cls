/**
 * @description Selector class for DES_BBVA_Management_team__c queries.
 *              Centralises all SOQL access to the DES_BBVA_Management_team__c object,
 *              keeping query logic out of service and handler classes.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-22
 */
public with sharing class DES_BBVAManagementTeamSelector {

    // ──────────────────────────────────────────────────────────────────────────
    // Query methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Returns all DES_BBVA_Management_team__c records linked to the given
     *              client Accounts that match the specified member role.
     *
     * @param clientIds  Set of Account Ids (DES_Client__c) to filter by.
     * @param role       DES_Member_Role__c value to filter by.
     * @return           List of matching DES_BBVA_Management_team__c records (Id only).
     */
    public static List<DES_BBVA_Management_team__c> getByClientIdsAndRole(Set<Id> clientIds, String role) {
        return [
            SELECT Id
            FROM DES_BBVA_Management_team__c
            WHERE DES_Client__c IN :clientIds
              AND DES_Member_Role__c = :role
        ];
    }
}