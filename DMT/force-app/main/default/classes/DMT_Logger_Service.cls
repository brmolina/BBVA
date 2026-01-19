global class DMT_Logger_Service implements Queueable {

    public static Boolean useQueueableMethod = false;

    /*
     * @description List of items to log
     */
    private List<iaso__GBL_Application_Log__c> logList {get;set;}

    /*
     * @description Class Constructor with list items to insert
     */
    public DMT_Logger_Service(List<iaso__GBL_Application_Log__c> logs) {
        logList = logs;
    }

    /*
     * @description Method to execute on queueable context
     */
    public void execute(QueueableContext context) {
        insertLogList(logList);
    }

    /**
     * insertFutureLog description
     * @param  jsList JSON with list items to insert
     */
    @future
    public static void insertFutureLog(String jsList) {
        List<iaso__GBL_Application_Log__c> logList = (List<iaso__GBL_Application_Log__c>) JSON.deserialize(jsList, List<iaso__GBL_Application_Log__c>.class);
        insertLogList(logList);
    }

    /**
     * @param  logList description
     */
    public static void flushLogList(List<iaso__GBL_Application_Log__c> logList) {
        if (useQueueableMethod) {
            DMT_Logger_Service logger = new DMT_Logger_Service(logList);
            System.enqueueJob(logger);
        } else {
            insertFutureLog(JSON.serialize(logList));
        }
    }

    /**
     * @return UUID string
     */
    private static String getUuid() {
        String s = Datetime.now().getTime().format();
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(s));
        return EncodingUtil.convertToHex(hash);
    }

    public static void insertLogList(List<iaso__GBL_Application_Log__c> logList) {
        final String uuid = getUuid();
        List<iaso__GBL_Application_Log__c> logListToInsert = new List<iaso__GBL_Application_Log__c>();
        for (Integer i = 0; i < logList.size(); i++) {
            iaso__GBL_Application_Log__c tmp = logList.get(i);
            tmp.iaso__Elapsed_Time__c = tmp.iaso__End_Time__c.getTime() - tmp.iaso__Start_Time__c.getTime();
            if (tmp.iaso__Message_LTA__c.length() > 131000) {
                tmp.iaso__Message_LTA__c = tmp.iaso__Message_LTA__c.substring(0, 131000) + ' ... (' + (tmp.iaso__Message_LTA__c.length() - 131000).format() + ' chars more)';
            }
            tmp.iaso__Transaction_Id__c = uuid;
            tmp.Name = tmp.Name.left(80); // Truncate if needed for Name field (Text 80)
            tmp.iaso__Type__c = 'Integration'; // Set a default or derive from tmp
            tmp.OwnerId = UserInfo.getUserId(); // Set to current user
            tmp.iaso__User__c = UserInfo.getUserId(); // Set to current user

            logList.set(i, tmp);
            logListToInsert.add(tmp);
        }

        if (!logListToInsert.isEmpty()) {
            insert logListToInsert;
        }
    }
}