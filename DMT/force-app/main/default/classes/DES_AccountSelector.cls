/**
 * @description Selector class for Account queries.
 *              Centralises all SOQL access to the Account object,
 *              keeping query logic out of service and handler classes.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-21
 */
public with sharing class DES_AccountSelector {

    // ──────────────────────────────────────────────────────────────────────────
    // Query methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Returns Account records for the given list of Ids.
     *
     * @param ids  List of Account Ids to retrieve.
     * @return     List of matching Account records.
     */
    public static List<Account> getByIds(List<Id> ids) {
        return [
            SELECT Id, Name, DES_ID_Fiscal__c, gf_customer_prospect_id__c, DES_Prospect_status__c
            FROM Account
            WHERE Id IN :ids
            WITH SYSTEM_MODE
        ];
    }
}