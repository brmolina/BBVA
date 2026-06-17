/**
 * @description Utility class for DML operations that must run in system context,
 *              bypassing the running user's record-level sharing rules.
 *
 *              This class intentionally declares 'without sharing' so that
 *              record ownership and sharing rules do not block legitimate
 *              system-driven operations (e.g., deleting AccountTeamMember
 *              records owned by a different user's Account).
 *
 *              Important: object-level and field-level permissions are NOT
 *              bypassed. Only call this class from reviewed, trusted code paths
 *              where the business requirement justifies system-level access.
 *
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-21
 */
public without sharing class DES_SystemDMLService {

    // ──────────────────────────────────────────────────────────────────────────
    // DML operations
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Deletes the given list of records in system context, bypassing
     *              record-level sharing rules. No-op when the list is null or empty.
     * @param records  Records to delete.
     */
    public static void deleteRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        delete records;
    }

    /**
     * @description Inserts the given list of records in system context, bypassing
     *              record-level sharing rules. No-op when the list is null or empty.
     * @param records  Records to insert.
     */
    public static void insertRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        insert records;
    }

    /**
     * @description Updates the given list of records in system context, bypassing
     *              record-level sharing rules. No-op when the list is null or empty.
     * @param records  Records to update.
     */
    public static void updateRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        update records;
    }
}