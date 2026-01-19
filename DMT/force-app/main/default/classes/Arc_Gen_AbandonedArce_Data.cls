/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_AbandonedArce_Data
* @author      marcos.gimeno.tech@bbva.com
* @date        2024-06-25
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Class that provides the data for the abandoned analysis batch.
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.tech@bbva.com
* |2024-06-25  Class creation
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:UseSingleton')
public with sharing class Arc_Gen_AbandonedArce_Data { 
    /** 
    * -----------------------------------------------------------------------------------------------
    * @description Gets the metadata records for the abandoned analysis
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @return      List of metadata records for the abandoned analysis
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:AvoidGetSetMethods, sf:AvoidUsingTestIsRunningTest')
    public static List<arce__AbandonedArce__mdt> getAbandonedArceMeta() {
        List<arce__AbandonedArce__mdt> arceMetas = new List<arce__AbandonedArce__mdt>();

        // If the code is running in a test context, return a list of mock metadata records
        if (Test.isRunningTest()) {
            arceMetas = new List<arce__AbandonedArce__mdt>{
                new arce__AbandonedArce__mdt(
                    arce__DaysSinceCreation__c = 105,
                    arce__Stage__c = '1',
                    arce__Action__c = Arc_Gen_AbandonedArce_Service.CANCEL
                ),
                new arce__AbandonedArce__mdt(
                    arce__DaysSinceCreation__c = 105,
                    arce__Stage__c = '2',
                    arce__Action__c = Arc_Gen_AbandonedArce_Service.CANCEL
                ),
                new arce__AbandonedArce__mdt(
                    arce__DaysSinceCreation__c = 91,
                    arce__Stage__c = '2',
                    arce__Action__c = Arc_Gen_AbandonedArce_Service.NOTIFY
                )
            };
        } else {
            arceMetas = arce__AbandonedArce__mdt.getAll().values();
        }

        return arceMetas;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Constructs the query locator for the abandoned analysis batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       arceMetas List of metadata records with conditions configuration
    * @return      The query locator for the abandoned analysis batch
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:AvoidFinalLocalVariable')
    public static Database.QueryLocator queryLocatorAbandonedBatch(List<arce__AbandonedArce__mdt> arceMetas) {
        final List<String> fields = new List<String>{
            'Id',
            'Name',
            'CreatedDate',
            'ownerId',
            'CreatedById',
            'arce__parent_analysis_id__c',
            'arce__anlys_wkfl_prev_user_name__c',
            'arce__anlys_wkfl_sanction_rslt_type__c',
            'arce__anlys_wkfl_sub_process_type__c',
            'arce__Stage__c',
            'arce__wf_status_id__c',
            'arce__bbva_committees_type__c',
            'arce__Is_Notified__c',
            'arce__anlys_wkfl_edit_br_level_type__c',
            'arce__rating_prerating_type__c',
            'arce__proposeUser__c',
            'arce__anlys_wkfl_discard_reason_id__c',
            'arce__analysis_customer_relation_type__c',
            'arce__anlys_wkfl_snctn_br_level_type__c',
            'arce__anlys_wkfl_stage_type__c',
            'arce__anlys_wkfl_status_stage_type__c',
            'arce__gf_destination_path_id__c',
            'arce__territory_name__c',
            'arce__num_committes_sanction__c',
            'arce__num_users_sanction__c',
            'arce__anlys_arce_type__c',
            'arce__Is_RAIP_Renewal__c',
            'arce__reload_connected_clients__c',
            'arce__connected_clients_answer__c',
            'Owner.Name',
            'CreatedBy.Name',
            'CreatedBy.email',
            'arce__Group__r.Name',
            'arce__proposeUser__r.Id',
            'arce__proposeUser__r.Name',
            'arce__proposeUser__r.email',
            'arce__proposeUser__r.IsActive',
            'arce__anlys_wkfl_prev_user_name__r.email',
            'arce__gf_committee_user_id__r.email',
            'arce__anlys_wkfl_edit_user_name__r.email',
            '(SELECT arce__user_audit_id__r.email FROM arce__Traceability_events_analysis__r)',
            '(SELECT id FROM arce__Account_has_Analysis__r)'
        };

        final List<String> conditions = new List<String>();
        for (arce__AbandonedArce__mdt metadataRecord : arceMetas) {
            conditions.add(
                '(CreatedDate <= N_DAYS_AGO:' +
                Integer.valueOf(metadataRecord.arce__DaysSinceCreation__c) +
                ' AND arce__Stage__c = \'' +
                metadataRecord.arce__Stage__c +
                '\')'
            );
        }

        // Build the query
        String queryResult = 'SELECT ';
        queryResult += String.join(fields, ', ');
        queryResult += ' FROM arce__Analysis__c';
        queryResult += ' WHERE ' + '(arce__wf_status_id__c !=\'13\' AND arce__wf_status_id__c !=\'10\' AND arce__wf_status_id__c !=\'14\')';
        queryResult += ' AND (' + String.join(conditions, ' OR ') + ')';
        queryResult += ' WITH SYSTEM_MODE';

        return Database.getQueryLocator(queryResult);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Gets the sender ID for the specified org-wide email address
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       owdName The org-wide email address name
    * @return      The sender ID
    * -----------------------------------------------------------------------------------------------
    **/
    public static Id getSenderId(String owdName) {
        Id senderId = null;
        final arce__Arce_Config__mdt orgWideAddress = arce__Arce_Config__mdt.getInstance(owdName);
        if (orgWideAddress != null) {
            final List<OrgWideEmailAddress> fromAddress = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :orgWideAddress.arce__Value1__c   
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            if (!fromAddress.isEmpty()) {
                senderId = fromAddress[0].Id;
            }
        }
        return senderId;
    }
}