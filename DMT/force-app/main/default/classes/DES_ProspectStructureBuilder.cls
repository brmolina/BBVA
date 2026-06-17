/*----------------------------------------------------------------------------------------------------------------------------
* @Name     DES_ProspectStructureBuilder
* @Date     Created: 2026-03-17
* @Author   
* ----------------------------------------------------------------------------------------------------------------------------
* @Description Class to build the structure sent to HPGR request 'DES_PostCreateProspect' and DES_PutEditProspect services.
* These methods should run after insert and after update the Accounts: Prospects Subsidiary and Prospect Groups
* to send HPGR the information or the Prospect and that Deal Management load correctly
* @Test class: this class is covered by the trigger handler: AccountTriggerHandlerTest 
* ----------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class DES_ProspectStructureBuilder {
    
    private static final Integer MAX_RETRIES = 3;
    private static final String RT_GROUP = 'Prospect_Group';
    private static final String RT_SUBSIDIARY = 'Prospect_Subsidiary';

    private static final String TYPE_GROUP = 'Group';
    private static final String TYPE_SUBGROUP = 'Subgroup';
    private static final String TYPE_SUPRAGROUP = 'Supragroup';    
    private static final String KEY_GROUP_CODE = 'groupCode';
    private static final String KEY_GROUP_NAME = 'groupName';
    private static final String KEY_SUBGROUP_CODE = 'subgroupId';
    private static final String KEY_SUBGROUP_NAME = 'subgroupName';
    private static final String KEY_SUPRAGROUP_CODE = 'supragroupId';
    private static final String KEY_SUPRAGROUP_NAME = 'supragroupName';

    public static void  handleProspectIntegration(DES_ProspectStructurePayload payload) {
        if (payload == null || String.isBlank(payload.serviceName)) {
            System.debug(LoggingLevel.ERROR, 'Payload or serviceName invalids');
            return;
        }
        switch on payload.serviceName {
            when 'DES_PostCreateProspect' {
                postCreateProspect(payload);
            }
            when 'DES_PutEditProspect' {
                putEditProspect(payload);
            }
            when else {
                System.debug(LoggingLevel.WARN, 'Service unknown: ' + payload.serviceName);
            }
        }
    }
    
    public static void postCreateProspect(DES_ProspectStructurePayload payloadWrapper) {  
        PostCreateProspectWrapper res = new PostCreateProspectWrapper();     
        //get structure info
        ProspectStructureResult s = buildProspectStructure(payloadWrapper, false);
        
        // Dont call service if no groupId, because it will not be returned in Global Position service
        if (String.isBlank(s.groupCode)) {
            System.debug(LoggingLevel.WARN, 'No se llama al servicio: postCreateProspect, porque groupId es null o vacío');
            return;
        }
        
        Map<String,Object> payload = new Map<String,Object>{
            'customerId'               => safeString(payloadWrapper.account.g_customer_id__c),
            'customerName'             => safeCustomerName(payloadWrapper.account),
            'goldenCustomerId'         => safeString(payloadWrapper.account.g_golden_customer_id__c),
            'countryId'                => (safeString(payloadWrapper.account.g_customer_id__c).length() >= 2 ? safeString(payloadWrapper.account.g_customer_id__c).substring(0, 2) : ''),
            'countryIfoId'             => safeString(payloadWrapper.account.DES_Country_Client__c),
            'residenceCountryId'       => '',
            'groupId'                  => safeString(s.groupCode),
            'groupName'                => safeString(s.groupName),
            'groupProspectInd'         => safeString(s.groupProspectInd),
            'subGroupId'               => safeString(s.subgroupCode),
            'subGroupName'             => safeString(s.subgroupName),
            'subGroupProspectInd'      => safeString(s.subGroupProspectInd),
            'level3groupId'            => safeString(s.level3Code),
            'level3groupName'          => safeString(s.level3Name),
            'level3GroupProspectInd'   => safeString(s.level3GroupProspectInd)
        };

        System.debug('payload: ' + JSON.serialize(payload));
        
        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('payload', JSON.serialize(payload));
        
        HttpResponse response = DMT_HPG_Utils.callService(payloadWrapper.serviceName, requestMap);
        System.debug('Response: ' + response);
        switch  on response.getStatusCode(){
            when 200, 201{
                System.debug('Response ok: ' + response.getBody());
                res.success = true;
                // Mark Prospect as synced with HPG
                update new Account(Id = payloadWrapper.account.Id, DMT_Prospect_HPG_Sync__c = true);
            }
            when else{
                System.debug('Response: ' + response.getBody());
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());

                if (payloadWrapper.retryCount < MAX_RETRIES && !Test.isRunningTest()) {
                    System.debug('Encolando reintento ' + (payloadWrapper.retryCount + 1) + ' de ' + MAX_RETRIES);
                    DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(payloadWrapper.account, payloadWrapper.serviceName, payloadWrapper.retryCount + 1));
                }
            }
        }
    }

    public static void putEditProspect(DES_ProspectStructurePayload payloadWrapper) {
        //get structure info
        ProspectStructureResult s = buildProspectStructure(payloadWrapper, true);
        PutEditProspectWrapper res = new PutEditProspectWrapper();
        
        // Dont call service if no groupId, because it will not be returned in Global Position service
        if (String.isBlank(s.groupCode)) {
            System.debug(LoggingLevel.WARN, 'No se llama al servicio: putEditProspect, porque groupId es null o vacío');
            return;
        }
        
        Map<String,Object> payload = new Map<String,Object>{
            'customerId'               => safeString(payloadWrapper.account.g_customer_id__c),
            'customerName'             => safeCustomerName(payloadWrapper.account),
            'goldenCustomerId'         => safeString(payloadWrapper.account.g_golden_customer_id__c),
            'countryId'                => (safeString(payloadWrapper.account.g_customer_id__c).length() >= 2 ? safeString(payloadWrapper.account.g_customer_id__c).substring(0, 2) : ''),
            'countryIfoId'             => safeString(payloadWrapper.account.DES_Country_Client__c),
            'residenceCountryId'       => '',
            'groupId'                  => safeString(s.groupCode),
            'groupName'                => safeString(s.groupName),
            'groupProspectInd'         => safeString(s.groupProspectInd),
            'subGroupId'               => safeString(s.subgroupCode),
            'subGroupName'             => safeString(s.subgroupName),
            'subGroupProspectInd'      => safeString(s.subGroupProspectInd),
            'level3groupId'            => safeString(s.level3Code),
            'level3groupName'          => safeString(s.level3Name),
            'level3GroupProspectInd'   => safeString(s.level3GroupProspectInd)
        };

        System.debug('payload: ' + JSON.serialize(payload));
        
        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('payload', JSON.serialize(payload));
        
        HttpResponse response = DMT_HPG_Utils.callService(payloadWrapper.serviceName, requestMap);
        System.debug('Response: ' + response);
        switch  on response.getStatusCode(){
            when 200, 201, 204{
                System.debug('Response ok: ' + response.getBody());
                res.success = true;
            }
            when else{
                System.debug('Response: ' + response.getBody());
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
                if (payloadWrapper.retryCount < MAX_RETRIES && !Test.isRunningTest()) {
                    System.debug('Encolando reintento ' + (payloadWrapper.retryCount + 1) + ' de ' + MAX_RETRIES);
                    DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(payloadWrapper.account, payloadWrapper.serviceName, payloadWrapper.retryCount + 1));
                }
            }
        }
    }

    private static ProspectStructureResult buildProspectStructure(DES_ProspectStructurePayload payloadWrapper, Boolean isEdit) {
        ProspectStructureResult result = new ProspectStructureResult();
        String groupCode, subgroupCode, level3Code;
        String groupName, subgroupName, level3Name;
        String groupProspectInd, subGroupProspectInd, level3GroupProspectInd;
        Map<String,Object> prospectGroupStructure = new Map<String,Object>();
        Account parentGroup;

        Id groupRtId      = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_SUBSIDIARY).getRecordTypeId();

        // Prospect Subsidiary
        if (payloadWrapper.account.RecordTypeId == subsidiaryRtId) {
            parentGroup = DMT_Client_Selector.getAccountById(payloadWrapper.account.participant_id__c);
            // Parent is a Prospect Group
            if (parentGroup.RecordTypeId == groupRtId) {
                groupCode = parentGroup.DES_Group_Code__c;
                groupName = parentGroup.Name;
                groupProspectInd = 'Y';
            } else {
                // Parent is not a Prospect
                prospectGroupStructure = DMT_HPG_Utils.buildClientGroupStructure(parentGroup.Id);
                if (!prospectGroupStructure.isEmpty()) {
                    groupProspectInd = 'N';
                    if (parentGroup.DES_Structure_Type__c == TYPE_SUBGROUP) {
                        subGroupProspectInd = 'N';
                        if (prospectGroupStructure.get(KEY_SUPRAGROUP_CODE) != null) {
                            level3GroupProspectInd = 'N';
                            groupCode    = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_CODE);
                            groupName    = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_NAME);
                            subgroupCode = (String) prospectGroupStructure.get(KEY_GROUP_CODE);
                            subgroupName = (String) prospectGroupStructure.get(KEY_GROUP_NAME);
                            level3Code   = (String) prospectGroupStructure.get(KEY_SUBGROUP_CODE);
                            level3Name   = (String) prospectGroupStructure.get(KEY_SUBGROUP_NAME);
                        } else {
                            groupCode    = (String) prospectGroupStructure.get(KEY_GROUP_CODE);
                            groupName    = (String) prospectGroupStructure.get(KEY_GROUP_NAME);
                            subgroupCode = (String) prospectGroupStructure.get(KEY_SUBGROUP_CODE);
                            subgroupName = (String) prospectGroupStructure.get(KEY_SUBGROUP_NAME);
                        }
                    } else if (parentGroup.DES_Structure_Type__c == TYPE_GROUP) {
                        if (prospectGroupStructure.get(KEY_SUPRAGROUP_CODE) != null) {
                            subGroupProspectInd = 'N';
                            groupCode    = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_CODE);
                            groupName    = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_NAME);
                            subgroupCode = (String) prospectGroupStructure.get(KEY_GROUP_CODE);
                            subgroupName = (String) prospectGroupStructure.get(KEY_GROUP_NAME);
                        } else {
                            groupCode = (String) prospectGroupStructure.get(KEY_GROUP_CODE);
                            groupName = (String) prospectGroupStructure.get(KEY_GROUP_NAME);
                        }
                    } else if (parentGroup.DES_Structure_Type__c == TYPE_SUPRAGROUP) {
                        groupCode = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_CODE);
                        groupName = (String) prospectGroupStructure.get(KEY_SUPRAGROUP_NAME);
                    }
                }
            }
        // Prospect Group
        } else {
            groupCode = payloadWrapper.account.DES_Group_Code__c;
            groupName = payloadWrapper.account.Name;
            groupProspectInd = 'Y';
        }
        //Set result values
        result.groupCode              = groupCode;
        result.groupName              = groupName;
        result.subgroupCode           = subgroupCode;
        result.subgroupName           = subgroupName;
        result.level3Code             = level3Code;
        result.level3Name             = level3Name;
        result.groupProspectInd       = groupProspectInd;
        result.subGroupProspectInd    = subGroupProspectInd;
        result.level3GroupProspectInd = level3GroupProspectInd;

        return result;
    }
    
    private static String safeString(Object value) {
        return value != null ? String.valueOf(value) : '';
    }

    private static String safeCustomerName(Account acc) {
        return (acc.Name != null && acc.g_customer_id__c != null)
            ? acc.Name
            : '';
    }
    
    /**
     * @Description: Class ProspectStructureResult
    */
    public class ProspectStructureResult {
        public String groupCode;
        public String groupName;
        public String subgroupCode;
        public String subgroupName;
        public String level3Code;
        public String level3Name;

        public String groupProspectInd;
        public String subGroupProspectInd;
        public String level3GroupProspectInd;
    }

    /**
     * @Description: Class PutEditProspectWrapper
    */
    public class PutEditProspectWrapper {
        public List<Data> data { get; set; }
        
        public boolean success{ get; set; }

        public String errorMessage{ get; set; }
    }

    /**
     * @Description: Class PostCreateProspectWrapper
    */
    public class PostCreateProspectWrapper {
        public List<Data> data { get; set; }
        
        public boolean success{ get; set; }

        public String errorMessage{ get; set; }
    }

    public class Data {
        public String AUX { get; set; }
    }

}