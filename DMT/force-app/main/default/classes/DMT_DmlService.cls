public inherited sharing class DMT_DmlService {

    public class DmlOperationException extends Exception {}

    // INSERT
    public static Database.SaveResult insertOne(SObject recordToInsert, AccessLevel mode) {
        return Database.insert(recordToInsert, mode);
    }

    public static List<Database.SaveResult> insertMany(List<SObject> recordsToInsert, AccessLevel mode) {
        return Database.insert(recordsToInsert, mode);
    }

    // UPDATE
    public static Database.SaveResult updateOne(SObject recordToUpdate, AccessLevel mode) {
        return Database.update(recordToUpdate, mode);
    }

    public static List<Database.SaveResult> updateMany(List<SObject> recordsToUpdate, AccessLevel mode) {
        return Database.update(recordsToUpdate, mode);
    }

    // UPSERT
    public static Database.UpsertResult upsertOne(SObject recordToUpsert, AccessLevel mode) {
        return Database.upsert(recordToUpsert, mode);
    }

    public static List<Database.UpsertResult> upsertMany(List<SObject> recordsToUpsert, AccessLevel mode) {
        return Database.upsert(recordsToUpsert, mode);
    }

    // DELETE
    public static Database.DeleteResult deleteOne(SObject recordToDelete, AccessLevel mode) {
        return Database.delete(recordToDelete, mode);
    }

    public static List<Database.DeleteResult> deleteMany(List<SObject> recordsToDelete, AccessLevel mode) {
        return Database.delete(recordsToDelete, mode);
    }

    // ---- Validaciones de resultado ----
    public static void ensureSuccess(Database.SaveResult sr, String context, String operation) {
        if (!sr.isSuccess()) {
            throw new DmlOperationException(buildErrorMessage(sr.getErrors(), context, operation));
        }
    }

    public static void ensureSuccess(List<Database.SaveResult> results, String context, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            ensureSuccess(results[i], context + ' idx=' + i, operation);
        }
    }

    public static void ensureSuccess(Database.UpsertResult ur, String context, String operation) {
        if (!ur.isSuccess()) {
            throw new DmlOperationException(buildErrorMessage(ur.getErrors(), context, operation));
        }
    }

    public static void ensureSuccess(List<Database.UpsertResult> results, String context, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            ensureSuccess(results[i], context + ' idx=' + i, operation);
        }
    }

    public static void ensureSuccess(Database.DeleteResult dr, String context, String operation) {
        if (!dr.isSuccess()) {
            throw new DmlOperationException(buildErrorMessage(dr.getErrors(), context, operation));
        }
    }

    public static void ensureSuccess(List<Database.DeleteResult> results, String context, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            ensureSuccess(results[i], context + ' idx=' + i, operation);
        }
    }

    private static String buildErrorMessage(Database.Error[] errors, String context, String operation) {
        String msg = operation + ' failed [' + context + ']: ';
        for (Database.Error e : errors) {
            msg += e.getStatusCode() + ' - ' + e.getMessage() + ' ';
        }
        return msg;
    }
}