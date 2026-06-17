/**
 * @description Selector class for AccountTeamMember queries.
 *              Centralises all SOQL access to the AccountTeamMember object,
 *              keeping query logic out of service and handler classes.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-14
 */
public with sharing class DES_AccountTeamMemberSelector {


    // ──────────────────────────────────────────────────────────────────────────
    // Query methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Returns all AccountTeamMember records belonging to the given
     *              Accounts that match the specified team role.
     *
     * @param accountIds  Set of Account Ids to filter by.
     * @param role        TeamMemberRole value to filter by.
     * @return            List of matching AccountTeamMember records (Id only).
     */
    public static List<AccountTeamMember> getByAccountIdsAndRole(Set<Id> accountIds, String role) {
        return [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId IN :accountIds
              AND TeamMemberRole = :role
        ];
    }

    /**
     * @description Returns all AccountTeamMember records belonging to the given Accounts,
     *              including UserId and AccountId for sharing-related processing.
     *
     * @param accountIds  Set of Account Ids to filter by.
     * @return            List of matching AccountTeamMember records (Id, AccountId, UserId).
     */
    public static List<AccountTeamMember> getByAccountIds(Set<Id> accountIds) {
        return [
            SELECT Id, AccountId, UserId
            FROM AccountTeamMember
            WHERE AccountId IN :accountIds
        ];
    }

    /**
     * @description Returns all AccountTeamMember records matching both the given
     *              Accounts and Users, used for existence checks before insert.
     *
     * @param accountIds  Set of Account Ids to filter by.
     * @param userIds     Set of User Ids to filter by.
     * @return            List of matching AccountTeamMember records (Id, AccountId, UserId).
     */
    public static List<AccountTeamMember> getByAccountIdsAndUserIds(Set<Id> accountIds, Set<Id> userIds) {
        return [
            SELECT Id, AccountId, UserId
            FROM AccountTeamMember
            WHERE AccountId IN :accountIds
              AND UserId IN :userIds
        ];
    }
}