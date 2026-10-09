/**
 * Small shared DML helpers, extracted from DMT_Massive_Task_Closure_Service (which had its own
 * private copy) so the new single-responsibility services introduced alongside it
 * (DMT_TaskCompletionService, DMT_CaseClosureService, DMT_RelatedTaskFinisherService,
 * DMT_DraftStatusService, DMT_DocumentTransferService) share one implementation instead of five.
 *
 * insertMany/updateMany/deleteMany are deliberately thin: they use the 2-arg
 * Database.X(records, accessLevel) form, which behaves all-or-none and throws Apex's own
 * DmlException immediately on the first failing row - not the 3-arg allOrNone=false form, which
 * would let earlier rows in the same call commit while a later row fails, safe only if every caller
 * then rolled back explicitly (none of them do). The original private copy of this logic in
 * DMT_Massive_Task_Closure_Service wrapped every failure in a "contextual" AuraHandledException -
 * that wrapper was actually unreachable dead code with this call shape (the DmlException always
 * throws first), so it isn't carried forward here.
 */
public with sharing class DMT_DmlUtils {

    public static void insertMany(List<SObject> recordsToInsert, String operation) {
        if (recordsToInsert == null || recordsToInsert.isEmpty()) {
            return;
        }
        System.debug(LoggingLevel.INFO, '[DMT_DmlUtils] insert ' + operation + ': ' + recordsToInsert.size() + ' record(s)');
        Database.insert(recordsToInsert, AccessLevel.SYSTEM_MODE);
    }

    public static void updateMany(List<SObject> recordsToUpdate, String operation) {
        if (recordsToUpdate == null || recordsToUpdate.isEmpty()) {
            return;
        }
        System.debug(LoggingLevel.INFO, '[DMT_DmlUtils] update ' + operation + ': ' + recordsToUpdate.size() + ' record(s)');
        Database.update(recordsToUpdate, AccessLevel.SYSTEM_MODE);
    }

    public static void deleteMany(List<SObject> recordsToDelete, String operation) {
        if (recordsToDelete == null || recordsToDelete.isEmpty()) {
            return;
        }
        System.debug(LoggingLevel.INFO, '[DMT_DmlUtils] delete ' + operation + ': ' + recordsToDelete.size() + ' record(s)');
        Database.delete(recordsToDelete, AccessLevel.SYSTEM_MODE);
    }

    // Drops records without an Id before an update/delete call, to avoid a MISSING_ARGUMENT error
    // on the whole batch because of one caller-supplied record that was never actually saved.
    public static List<SObject> withIdOnly(List<SObject> records) {
        List<SObject> filtered = new List<SObject>();
        for (SObject rec : records) {
            if (rec != null && rec.get('Id') != null) {
                filtered.add(rec);
            }
        }
        return filtered;
    }
}