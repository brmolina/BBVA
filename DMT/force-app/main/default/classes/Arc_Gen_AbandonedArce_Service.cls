/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_AbandonedArce_Service
* @author      marcos.gimeno.tech@bbva.com
* @date        2024-06-25
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Service class to handle the abandoned ARCE
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.tech@bbva.com
* |2024-06-25  Class creation
* -----------------------------------------------------------------------------------------------
**/  
@SuppressWarnings('PMD.CognitiveComplexity, sf:TooManyMethods') 
public with sharing class Arc_Gen_AbandonedArce_Service {
    /** @description String with Notify literal **/
    public static final String NOTIFY = 'Notify';
    /** @description String with Cancel literal **/
    public static final String CANCEL = 'Cancel';
    /** @description String with Body literal **/
    private static final String BODY = 'Body';
    /** @description String with Subject literal **/
    private static final String SUBJECT = 'Subject';
    /** @description The org-wide email address to use as the sender **/
    private static final String ORG_WIDE_ADDRESS = 'Abandoned_Arce_Sender';

    /** @description Batch parameters **/
    @TestVisible
    private UpdateInfoParams batchParams;
    /** @description List of emails to send **/
    private final List<EmailWrapper> mailsToSend = new List<EmailWrapper>();
    /** @description Map with email labels **/
    private final Map<String, String> emailLabels = new Map<String, String>{
        NOTIFY + SUBJECT => System.Label.Arc_Gen_AbandonedArce_Notify_Subject,
        NOTIFY + BODY => System.Label.Arc_Gen_AbandonedArce_Notify_Body,
        CANCEL + SUBJECT => System.Label.Arc_Gen_AbandonedArce_Cancel_Subject,
        CANCEL + BODY => System.Label.Arc_Gen_AbandonedArce_Cancel_Body
    };

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to set the batch parameters
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       analyses List of analysis records
    * @param       arceMetas List of metadata records for the abandoned analysis
    * @return      The instance of the Arc_Gen_AbandonedArce_Service class
    * -----------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_AbandonedArce_Service setBatchParams(
        List<arce__Analysis__c> analyses,
        List<arce__AbandonedArce__mdt> arceMetas
    ) {
        this.batchParams = new UpdateInfoParams(analyses, arceMetas);
        return this;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to process the batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @return      The instance of the Arc_Gen_AbandonedArce_Service class
    * -----------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_AbandonedArce_Service processBatch() {
        for (arce__Analysis__c analysis : this.batchParams.analysisMap.values()) {
            this.batchParams.analysis = analysis;
            processSingleAnalysis();
        }
        return this;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to update the records and insert the events
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @return      The instance of the Arc_Gen_AbandonedArce_Service class
    * -----------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_AbandonedArce_Service updateRecordsAndInsertEvents() {
        try {
            if (isValid(this.batchParams.recordsToUpdate)) {
                Arc_Gen_ModificationArce_Data.updateRecords(this.batchParams.recordsToUpdate);
            }

            if (isValid(this.batchParams.actEvtToInsert)) {
                insert this.batchParams.actEvtToInsert;
            }

            if (isValid(this.batchParams.traceabilityEvent)) {
                Arc_Gen_TraceabilityEvents.updateTraceEvents(this.batchParams.traceabilityEvent);
            }

            if (isValid(this.batchParams.taskToInsert)) {
                insert this.batchParams.taskToInsert;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in updateRecordsAndInsertEvents: ' + e.getMessage());
        }
        return this;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to send the emails
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @return      The instance of the Arc_Gen_AbandonedArce_Service class
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    public Arc_Gen_AbandonedArce_Service sendEmails() {
        final List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        final Id senderId = Arc_Gen_AbandonedArce_Data.getSenderId(ORG_WIDE_ADDRESS);

        // Get the email limits
        final Integer emailLimit = Limits.getLimitEmailInvocations();
        Integer emailsSent = Limits.getEmailInvocations();

        for (EmailWrapper emailWrp : this.mailsToSend) {
            // Check email limit before adding to the list
            if (emailsSent < emailLimit) {
                mails.add(emailWrp.toSingleEmailMessage(senderId));
                emailsSent++;
            } else {
                System.debug(
                    LoggingLevel.ERROR,
                    'Limit of emails per transaction reached. You will send ' +
                        emailLimit +
                        ' emails out of a total of ' +
                        this.mailsToSend.size() +
                        ' emails planned.'
                );
                break;
            }
        }

        if (isValid(mails)) {
            final Messaging.SendEmailResult[] messageResults = Messaging.sendEmail(mails, false);
            for (Messaging.SendEmailResult result : messageResults) {
                if (!result.isSuccess()) {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'The email failed to send: ' + error.getMessage());
                    }
                }
            }
        }
        return this;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to process a single analysis
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    private void processSingleAnalysis() {
        this.batchParams.updateAnalysisDetails();
        if (this.batchParams.toCancel()) {
            processCancellation();
        } else if (this.batchParams.toNotify()) {
            processNotification();
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to process the cancellation
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    private void processCancellation() {
        this.batchParams.toUpdateWrapper = Arc_Gen_Remove_Service.updateRemoveInfo(this.batchParams);
        this.batchParams.recordsToUpdate.add(this.batchParams.toUpdateWrapper.arceAnalysis);
        this.batchParams.actEvtToInsert.add(this.batchParams.toUpdateWrapper.actionAuditEvent);
        this.batchParams.taskToInsert.addAll(this.batchParams.toUpdateWrapper.notificationTask);
        this.batchParams.traceabilityEvent = this.batchParams.toUpdateWrapper.traceabilityEvent;

        this.mailsToSend.add(createEmailWrapper(this.batchParams.analysis, this.batchParams.dayOfCancellation, CANCEL));
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to process the notification
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    private void processNotification() {
        this.batchParams.analysis.arce__Is_Notified__c = true;
        this.batchParams.recordsToUpdate.add(this.batchParams.analysis);

        this.mailsToSend.add(createEmailWrapper(this.batchParams.analysis, this.batchParams.dayOfCancellation, NOTIFY));
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to create an email wrapper
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       analysis The analysis record.
    * @param       dayOfCancelation The day of cancelation
    * @param       action The action to perform
    * @return      The email wrapper
    * -----------------------------------------------------------------------------------------------
    **/
    private EmailWrapper createEmailWrapper(arce__Analysis__c analysis, Decimal dayOfCancelation, String action) {
        final EmailWrapper mailToSend = new EmailWrapper();
        mailToSend.toAddresses = new List<String>(getToAddresses(analysis));
        mailToSend.emailSubject = String.format(
            this.emailLabels.get(action + SUBJECT),
            new List<String>{ analysis.arce__Group__r?.Name }
        );
        mailToSend.emailBody = String.format(
            this.emailLabels.get(action + BODY),
            getBodyParams(analysis, dayOfCancelation, action)
        );
        return mailToSend;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to get the body parameters.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       analysis The analysis record.
    * @param       dayOfCancelation The day of cancelation
    * @param       action The action to perform
    * @return      List of body parameters
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<String> getBodyParams(arce__Analysis__c analysis, Decimal dayOfCancelation, String action) {
        final List<String> bodyParams = new List<String>();
        if (action == NOTIFY) {
            bodyParams.addAll(
                new List<String>{
                    analysis.arce__Group__r?.Name,
                    URL.getOrgDomainUrl().toExternalForm() +
                    '/' +
                    analysis.Id,
                    String.valueOf(analysis.CreatedDate.date().daysBetween(Date.today())),
                    String.valueOf(
                        Integer.valueOf(dayOfCancelation - analysis.CreatedDate.date().daysBetween(Date.today()))
                    )
                }
            );
        } else {
            bodyParams.addAll(
                new List<String>{
                    analysis.arce__Group__r?.Name,
                    URL.getOrgDomainUrl().toExternalForm() +  
                    '/' +
                    analysis.Id,
                    String.valueOf(analysis.CreatedDate.date().daysBetween(Date.today()))
                }
            );
        }
        return bodyParams;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to get the email addresses
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       analysis The analysis record
    * @return      Set of email addresses
    * -----------------------------------------------------------------------------------------------
    **/
    private static Set<String> getToAddresses(arce__Analysis__c analysis) {
        final Set<String> toAddresses = new Set<String>{
            analysis.arce__anlys_wkfl_edit_user_name__r?.email,
            analysis.arce__anlys_wkfl_prev_user_name__r?.email,
            analysis.arce__gf_committee_user_id__r?.email,
            analysis.arce__proposeUser__r?.email,
            analysis.CreatedBy.email
        };
        if (isValid(analysis.arce__Traceability_events_analysis__r)) {
            for (arce__Traceability_Event__c trace : analysis.arce__Traceability_events_analysis__r) {
                toAddresses.add(trace.arce__user_audit_id__r?.email);
            }
        }
        toAddresses.remove(null);
        return toAddresses;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to check if an object is valid
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       obj The object to check
    * @return      True if the object is valid, false otherwise
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean isValid(Object obj) {
        return obj != null;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to check if a list is valid
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       objList The list to check
    * @return      True if the list is valid, false otherwise
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean isValid(List<Object> objList) {
        return objList != null && !objList.isEmpty();
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to check if a map is valid
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       objMap The map to check
    * @return      True if the map is valid, false otherwise
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean isValid(Map<Object, Object> objMap) {
        return objMap != null && !objMap.isEmpty();
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Inner class to represent the update info parameters
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    public class UpdateInfoParams {
        /** @description Map with analysis records **/
        public Map<Id, arce__Analysis__c> analysisMap { get; set; }
        /** @description Map with account has analysis records **/
        public Map<Id, arce__Account_has_Analysis__c> accountHasMap { get; set; }
        /** @description Map with traceability events **/
        public Map<Id, List<arce__Traceability_Event__c>> traceabilityMap { get; set; }
        /** @description Wrapper with the update info **/
        public Arc_Gen_Remove_Service.UpdateRemoveInfoReturn toUpdateWrapper { get; set; }
        /** @description List of tasks to insert **/
        public List<Task> taskToInsert { get; set; }
        /** @description List of action events to insert **/
        public List<dwp_cvad__Action_Audit__c> actEvtToInsert { get; set; }
        /** @description List of records to update **/
        public List<sObject> recordsToUpdate { get; set; }
        /** @description Day of notification **/
        public Decimal dayOfNotification { get; set; }
        /** @description Day of cancellation **/
        public Decimal dayOfCancellation { get; set; }
        /** @description Analysis record **/
        public arce__Analysis__c analysis { get; set; }
        /** @description Account has analysis record **/
        public arce__Account_has_Analysis__c currentAha { get; set; }
        /** @description Current analysis record **/
        public arce__Analysis__c currentAnalysis { get; set; }
        /** @description Wrapper with the traceability event **/
        public Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper traceabilityEvent { get; set; }
        /** @description Map with the metadata records **/
        public Map<String, Map<String, Object>> arceMetaMap { get; set; }
        /** @description List of account has analysis IDs **/
        public List<Id> ahaIdList { get; set; }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Constructor for the UpdateInfoParams class
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @param       analyses List of analysis records
        * @param       arceMetas List of metadata records for the abandoned analysis
        * -----------------------------------------------------------------------------------------------
        **/
        public UpdateInfoParams(List<arce__Analysis__c> analyses, List<arce__AbandonedArce__mdt> arceMetas) {
            initFields();
            populateAnalysisAha(analyses);
            populateAccountHasMap();
            populateTraceMap();
            setArceMetaMap(arceMetas);
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to update the analysis details
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * -----------------------------------------------------------------------------------------------
        **/
        public void updateAnalysisDetails() {
            this.currentAnalysis = analysisMap.get(this.analysis?.Id);
            if (isValid(this.currentAnalysis.arce__Account_has_Analysis__r)) {
                this.currentAha = accountHasMap.get(this.currentAnalysis.arce__Account_has_Analysis__r[0].Id);
            }
            this.dayOfNotification = getNotificationDays();
            this.dayOfCancellation = getCancellationDays();
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to check if the analysis should be notified
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @return      True if the analysis should be notified, false otherwise
        * -----------------------------------------------------------------------------------------------
        **/
        public Boolean toNotify() {
            Boolean result = false;
            if (isValid(this.analysis) && isValid(this.dayOfNotification)) {
                result = this.analysis.CreatedDate.date().daysBetween(Date.today()) >= this.dayOfNotification;
            }
            return result;
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to check if the analysis should be cancelled
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @return      True if the analysis should be cancelled, false otherwise
        * -----------------------------------------------------------------------------------------------
        **/
        public Boolean toCancel() {
            Boolean result = false;
            if (isValid(this.analysis) && isValid(this.dayOfCancellation)) {
                result = this.analysis.CreatedDate.date().daysBetween(Date.today()) >= this.dayOfCancellation;
            }
            return result;
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to initialize the fields
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @return      The instance of the UpdateInfoParams class
        * -----------------------------------------------------------------------------------------------
        **/
        private void initFields() {
            this.analysisMap = new Map<Id, arce__Analysis__c>();
            this.accountHasMap = new Map<Id, arce__Account_has_Analysis__c>();
            this.traceabilityMap = new Map<Id, List<arce__Traceability_Event__c>>();
            this.toUpdateWrapper = new Arc_Gen_Remove_Service.UpdateRemoveInfoReturn(null, null, null, null, null);
            this.taskToInsert = new List<Task>();
            this.actEvtToInsert = new List<dwp_cvad__Action_Audit__c>();
            this.recordsToUpdate = new List<SObject>();
            this.dayOfNotification = 0;
            this.dayOfCancellation = 0;
            this.ahaIdList = new List<Id>();
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to populate the analysis and account has analysis maps
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @param       analyses List of analysis records
        * -----------------------------------------------------------------------------------------------
        **/
        private void populateAnalysisAha(List<arce__Analysis__c> analyses) {
            if (isValid(analyses)) {
                for (arce__Analysis__c aToPopulate : analyses) {
                    this.analysisMap.put(aToPopulate.Id, aToPopulate);
                    if (isValid(aToPopulate.arce__Account_has_Analysis__r)) {
                        this.ahaIdList.add(aToPopulate.arce__Account_has_Analysis__r[0].Id);
                    }
                }
            }
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to populate the account has analysis map
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * -----------------------------------------------------------------------------------------------
        **/
        private void populateAccountHasMap() {
            if (isValid(this.ahaIdList)) {
                final List<arce__Account_has_Analysis__c> accHasToMapList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
                    this.ahaIdList
                );
                if (isValid(accHasToMapList)) {
                    for (arce__Account_has_Analysis__c accHas : accHasToMapList) {
                        if (accHas != null) {
                            this.accountHasMap.put(accHas.Id, accHas);
                        }
                    }
                }
            }
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to populate the traceability map
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * -----------------------------------------------------------------------------------------------
        **/
        private void populateTraceMap() {
            if (isValid(this.analysisMap)) {
                this.traceabilityMap = Arc_Gen_TraceabilityEvents_Data.getEvtActiveAnalysis(
                    new List<Id>(this.analysisMap.keySet())
                );
            }
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to set the metadata map
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @param       arceMetas List of metadata records for the abandoned analysis
        * -----------------------------------------------------------------------------------------------
        **/
        @SuppressWarnings('sf:AvoidGetSetMethods')
        private void setArceMetaMap(List<arce__AbandonedArce__mdt> arceMetas) {
            this.arceMetaMap = new Map<String, Map<String, Object>>();
            Map<String, Object> stageMap;
            for (arce__AbandonedArce__mdt arceMeta : arceMetas) {
                stageMap = this.arceMetaMap.containsKey(arceMeta.arce__Stage__c)
                    ? this.arceMetaMap.get(arceMeta.arce__Stage__c)
                    : new Map<String, Object>();
                if (arceMeta.arce__Action__c == NOTIFY) {
                    final Set<Decimal> daysToNotify = stageMap.containsKey(NOTIFY)
                        ? (Set<Decimal>) stageMap.get(NOTIFY)
                        : new Set<Decimal>();
                    daysToNotify.add(arceMeta.arce__DaysSinceCreation__c);
                    stageMap.put(NOTIFY, daysToNotify);
                } else {
                    stageMap.put(arceMeta.arce__Action__c, arceMeta.arce__DaysSinceCreation__c);
                }
                this.arceMetaMap.put(arceMeta.arce__Stage__c, stageMap);
            }
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to get the number of days to notify
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * -----------------------------------------------------------------------------------------------
        **/
        @SuppressWarnings('sf:AvoidGetSetMethods')
        private Decimal getNotificationDays() {
            Decimal result = null;
            if (
                isValid(this.analysis) &&
                isValid(this.arceMetaMap) &&
                isValid(this.analysis.arce__Stage__c) &&
                isValid(this.arceMetaMap.get(this.analysis.arce__Stage__c))
            ) {
                final Set<Decimal> notifyDays = (Set<Decimal>) this.arceMetaMap.get(this.analysis.arce__Stage__c)
                    .get(NOTIFY);
                if (notifyDays != null) {
                    for (Decimal days : notifyDays) {
                        if (this.analysis.CreatedDate.date().daysBetween(Date.today()) >= days) {
                            result = days;
                            break;
                        }
                    }
                }
            }
            return result;
        }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to get the number of days to cancel
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * -----------------------------------------------------------------------------------------------
        **/
        @SuppressWarnings('sf:AvoidGetSetMethods')
        private Decimal getCancellationDays() {
            Decimal result = null;
            if (
                isValid(this.analysis) &&
                isValid(this.arceMetaMap) &&
                isValid(this.analysis.arce__Stage__c) &&
                isValid(this.arceMetaMap.get(this.analysis.arce__Stage__c))
            ) {
                result = (Decimal) arceMetaMap.get(this.analysis.arce__Stage__c).get(CANCEL);
            }
            return result;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Inner class to represent the email wrapper
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    public class EmailWrapper {
        /** @description The email addresses to send the email to **/
        public List<String> toAddresses { get; set; }
        /** @description The body of the email **/
        public String emailBody { get; set; }
        /** @description The subject of the email **/
        public String emailSubject { get; set; }

        /**
        * -----------------------------------------------------------------------------------------------
        * @description Method to convert the email wrapper to a single email message
        * -----------------------------------------------------------------------------------------------
        * @autor       marcos.gimeno.tech@bbva.com
        * @date        2024-06-25
        * @param       senderId The ID of the sender
        * @return      The single email message
        * -----------------------------------------------------------------------------------------------
        **/
        public Messaging.SingleEmailMessage toSingleEmailMessage(Id senderId) {
            final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(emailSubject);
            mail.setHtmlBody(emailBody);
            mail.setOrgWideEmailAddressId(senderId);
            return mail;
        }
    }
}