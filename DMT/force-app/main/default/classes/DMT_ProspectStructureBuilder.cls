/*----------------------------------------------------------------------------------------------------------------------------
* @Name     DMT_ProspectStructureBuilder
* @Date     Created: 2026-03-17
* @Author   DMT
* ----------------------------------------------------------------------------------------------------------------------------
* @Description Class to build the structure sent to HPGR request 'DMT_PostCreateProspect' and DMT_PutEditProspect services.
* These methods should run after insert and after update the Accounts: Prospects Subsidiary and Prospect Groups
* to send HPGR the information or the Prospect and that Deal Management load correctly
* @Test class: this class is covered by the trigger handler: AccountTriggerHandlerTest 
* ----------------------------------------------------------------------------------------------------------------------------
*/
public  class DMT_ProspectStructureBuilder {

    public static void  handleProspectIntegration(DES_ProspectStructurePayload payload) {
        if(payload.serviceName == 'DES_PostCreateProspect') {
            postCreateProspect(payload);
        } else if(payload.serviceName == 'DES_PutEditProspect') {
            putEditProspect(payload);
        }
    }

    public static void postCreateProspect(DES_ProspectStructurePayload payloadWrapper) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Map<String, Object> prospectGroupStructure = new Map<String, Object>();
        PostCreateProspectWrapper res = new PostCreateProspectWrapper();
        String groupCode;
        Account parentGroup;
        String subgroupCode;
        String subgroupName;
        String level3Code;
        String level3Name;
        String groupName;

        if(payloadWrapper.account.RecordTypeId == subsidiaryRtId) {
            parentGroup = DMT_Client_Selector.getAccountById(payloadWrapper.account.DES_Main_Parent__c);
            if(parentGroup.RecordTypeId == groupRtId || parentGroup.RecordType.Id == subsidiaryRtId) {
                groupCode = parentGroup.DES_Group_Code__c;
                groupName = parentGroup.Name;
            } else {
                prospectGroupStructure = DMT_HPG_Utils.buildClientGroupStructure(parentGroup.Id);
                groupCode = (String)prospectGroupStructure.get('groupCode');
                groupName = (String)prospectGroupStructure.get('groupName');
                subgroupCode = (String)prospectGroupStructure.get('subgroupId');
                subgroupName = (String)prospectGroupStructure.get('subgroupName');
                level3Code = (String)prospectGroupStructure.get('supragroupId');
                level3Name = (String)prospectGroupStructure.get('supragroupName');
            }
        } else {
            groupCode = payloadWrapper.account.DES_Group_Code__c;
            groupName = payloadWrapper.account.Name;
        }

        Map<String, Object> payload = new Map<String, Object> {
            'g_customer_id' => ((String)payloadWrapper.account.g_customer_id__c != null ? (String)payloadWrapper.account.g_customer_id__c : ''),
            'gf_customer_complete_name' => (((String)payloadWrapper.account.Name != null && (String)payloadWrapper.account.g_customer_id__c != null) ? (String)payloadWrapper.account.Name : ''),
            'g_golden_customer_id' => ((String)payloadWrapper.account.g_golden_customer_id__c != null ? (String)payloadWrapper.account.g_golden_customer_id__c : ''),
            'g_country_id' => ((String)payloadWrapper.account.DES_Country_Client__c != null ? (String)payloadWrapper.account.DES_Country_Client__c : ''),
            'gf_group_id' => (groupCode != null ? groupCode : ''),
            'gf_group_name' => (groupName != null ? groupName : ''),
            'gf_subgroup_id' => (subgroupCode != null ? subgroupCode : ''),
            'gf_subgroup_name' => (subgroupName != null ? subgroupName : ''),
            'gf_level_3_group_id' => (level3Code != null ? level3Code : ''),
            'gf_level_3_group_name' => (level3Name != null ? level3Name : '')
        };

        System.debug('payload: ' + payload);
        
        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('payload', JSON.serialize(payload));
        
        HttpResponse response = DMT_HPG_Utils.callService(payloadWrapper.serviceName, requestMap);
        System.debug('Response: ' + response);
        switch  on response.getStatusCode(){
            when 200, 201{
                System.debug('Response: ' + response.getBody());
                res.success = true;
            }
            when else{
                System.debug('Response: ' + response.getBody());
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
    }

    public static void putEditProspect(DES_ProspectStructurePayload payloadWrapper) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Map<String, Object> prospectGroupStructure = new Map<String, Object>();
        PutEditProspectWrapper res = new PutEditProspectWrapper();
        String groupCode;
        Account parentGroup;
        String subgroupCode;
        String subgroupName;
        String level3Code;
        String level3Name;
        String groupName;

        if(payloadWrapper.account.RecordTypeId == subsidiaryRtId) {
            parentGroup = DMT_Client_Selector.getAccountById(payloadWrapper.account.DES_Main_Parent__c);
            if(parentGroup.RecordTypeId == groupRtId || parentGroup.RecordType.Id == subsidiaryRtId) {
                groupCode = parentGroup.DES_Group_Code__c;
                groupName = parentGroup.Name;
            } else {
                prospectGroupStructure = DMT_HPG_Utils.buildClientGroupStructure(parentGroup.Id);
                groupCode = (String)prospectGroupStructure.get('groupCode');
                groupName = (String)prospectGroupStructure.get('groupName');
                subgroupCode = (String)prospectGroupStructure.get('subgroupId');
                subgroupName = (String)prospectGroupStructure.get('subgroupName');
                level3Code = (String)prospectGroupStructure.get('supragroupId');
                level3Name = (String)prospectGroupStructure.get('supragroupName');
            }
        } else {
            groupCode = payloadWrapper.account.DES_Group_Code__c;
            groupName = payloadWrapper.account.Name;
        }

        Map<String, Object> payload = new Map<String, Object> {
            'g_customer_id' => ((String)payloadWrapper.account.g_customer_id__c != null ? (String)payloadWrapper.account.g_customer_id__c : ''),
            'gf_customer_complete_name' => (((String)payloadWrapper.account.Name != null && (String)payloadWrapper.account.g_customer_id__c != null) ? (String)payloadWrapper.account.Name : ''),
            'g_golden_customer_id' => ((String)payloadWrapper.account.g_golden_customer_id__c != null ? (String)payloadWrapper.account.g_golden_customer_id__c : ''),
            'g_country_id' => ((String)payloadWrapper.account.DES_Country_Client__c != null ? (String)payloadWrapper.account.DES_Country_Client__c : ''),
            'gf_group_id' => (groupCode != null ? groupCode : ''),
            'gf_group_name' => (groupName != null ? groupName : ''),
            'gf_subgroup_id' => (subgroupCode != null ? subgroupCode : ''),
            'gf_subgroup_name' => (subgroupName != null ? subgroupName : ''),
            'gf_level_3_group_id' => (level3Code != null ? level3Code : ''),
            'gf_level_3_group_name' => (level3Name != null ? level3Name : '')
        };

        System.debug('payload: ' + JSON.serialize(payload));

        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('payload', JSON.serialize(payload));

        HttpResponse response = DMT_HPG_Utils.callService(payloadWrapper.serviceName, requestMap);
        System.debug('Response: ' + response);
        switch  on response.getStatusCode(){
            when 200, 201{
                System.debug('Response: ' + response.getBody());
                res.success = true;
            }
            when else{
                System.debug('Response: ' + response.getBody());
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
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