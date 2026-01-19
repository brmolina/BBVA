public class DMT_AsyncDispatcher {

    public static void dispatch(DMT_AsyncPayload payload) {
        if (payload instanceof DMT_SnapshotPayload) {
            handleSnapshotLineVersion((DMT_SnapshotPayload) payload);
        } else if (payload instanceof DMT_LogExceptionPayload) {
            handleLogException((DMT_LogExceptionPayload) payload);
        } else if (payload instanceof DMT_LogApplicationPayload) {
            handleApplicationLogRecords((DMT_LogApplicationPayload) payload);
        } else {
            throw new IllegalArgumentException('Unsupported payload type');
        }
    }

    private static void handleSnapshotLineVersion(DMT_SnapshotPayload payload) {
        String requestStr = JSON.serialize(payload.request);
        String response = DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion(requestStr, payload.recordId, payload.type);
        System.debug('Response from Snapshot Eval API: ' + response);
    }

    private static void handleLogException(DMT_LogExceptionPayload pl) {
        System.enqueueJob(new DMT_LogExceptionQueueable(pl.message, pl.stackTrace, pl.lineNumber, pl.typeName, pl.className, pl.methodName, pl.projectCode, pl.objectName));
    }

    private static void handleApplicationLogRecords(DMT_LogApplicationPayload payload) {
        final String uuid = getUuid();
        List<iaso__GBL_Application_Log__c> logListToInsert = new List<iaso__GBL_Application_Log__c>();
        for (iaso__GBL_Application_Log__c tmp : payload.logs) {
            tmp.iaso__Elapsed_Time__c = tmp.iaso__End_Time__c.getTime() - tmp.iaso__Start_Time__c.getTime();
            if (tmp.iaso__Message_LTA__c.length() > 131000) {
                tmp.iaso__Message_LTA__c = tmp.iaso__Message_LTA__c.substring(0, 131000) + ' ... (' + (tmp.iaso__Message_LTA__c.length() - 131000).format() + ' chars more)';
            }
            tmp.iaso__Transaction_Id__c = uuid;
            tmp.Name = tmp.Name.left(80);
            tmp.iaso__Type__c = 'Integration';
            tmp.OwnerId = UserInfo.getUserId();
            tmp.iaso__User__c = UserInfo.getUserId();
            logListToInsert.add(tmp);
        }
        if (!logListToInsert.isEmpty()) {
            insert logListToInsert;
        }
    }

    private static String getUuid() {
        String s = Datetime.now().getTime().format();
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(s));
        return EncodingUtil.convertToHex(hash);
    }
}