/**-------------------------------------------------------------------------------------------
* @Name     DMT DealManagement_Handler
* @Author   Diego Perán <diego.perán.tech@bbva.com>
* @Date     Created: 2024-07-02
* --------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio
* --------------------------------------------------------------------------------------------
*/
global with sharing class DMT_DealManagement_Handler implements Callable {
    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try{
            Map<String, Object> result;
            if(methodName == 'lastDate'){
                outMap.put('returnedDate' ,  DMT_HPG_Utils.lastDate());
                                        }
            else if(methodName == 'getGroup'){
                outMap.put('groupCode' ,  DMT_HPG_Utils.getGroupId((String)inputMap.get('originId')));
            }
            else if(methodName == 'getGroupName'){
                List<Object> args = (List<Object>) inputMap.get('arguments');
                System.debug('getGroupName args: '+args);
                System.debug('(String) args[0]: '+(String) args[0]);
                String groupName = DMT_HPG_Utils.getGroupName((String) args[0]);
                System.debug('groupName: '+groupName);
                result = new Map<String, Object>{ 'result' => groupName };
                outMap.putAll(result);
            }
            else if(methodName == 'getLineId'){
                Map<String, Object> request = new Map<String, Object>();
                request.put('origin', 'ESCD');
                request.put('operationType', (String)inputMap.get('linOropp') != null ? (String)inputMap.get('linOropp') : 'LIN');

                request.put('entific', (String)inputMap.get('DMT_Client_Entific__c') != null ? (String)inputMap.get('DMT_Client_Entific__c') : 'HO');



                DMT_OpportunityCodes.Wrapper oppCode = DMT_OpportunityCodes.getOpportunityCode(request);
                outMap.put('lineId' , oppCode.data.opportunityId);
        	}
            else if (methodName == 'renewButton'){
                List<Object> arguments = (List<Object>)inputMap.get('arguments');
                outMap.put('result', renew(arguments));
            }
            else if (methodName == 'warrantyCurrency'){
                outMap.put('result', insertWarrantyCurrency(inputMap));
            }
            else if (methodName == 'reorderRisk'){
                outMap.put('result', reorderpriorityRisk(inputMap));
            }
            else if (methodName == 'singularTreasury'){
                outMap.put('result', singularTreasuryConsumption(inputMap));
            }

        }catch(exception e){
            system.debug('Exception --> '+e.getMessage());
            //DES_Exception_Utils.logException(e,'DMT_DealManagement_Handler', 'invokeMethod', 'DMT', '');
        }
        return outMap;
    }

    public List<Boolean> renew(List<Object> arguments)
    {
        List<Boolean> result = new List<Boolean>();
        List<Id> listIds =new List<Id>();
        try{
            for (Object id : arguments) {
                listIds.add((Id)id);
            }

            for (DMT_Line__c line : [SELECT Id, DMT_Parent_Line__c, Status__c,(select id from Lines__r), DMT_Cancel__c, DMT_Deleted__c FROM DMT_Line__c WHERE Id IN :listIds WITH USER_MODE]) {
                if(line.Status__c != 'Closed' || line.DMT_Cancel__c || line.DMT_Deleted__c){
                    result.add(true);
                }else{
                    if(!listIds.contains(line.DMT_Parent_Line__c)){
                        result.add(false);
                    }else{
                        result.add(true);
                    }
                }
            }
            System.debug(result);
        }catch(Exception e) {
            System.debug('Exception ' + e);
            //DES_Exception_Utils.logException(e,'DMT_DealManagement_Handler', 'renew', 'DMT', '');
        }
        return result;
    }

    public Integer insertWarrantyCurrency(Map<String, Object> inputMap)
    {
        List<Boolean> result = new List<Boolean>();
        List<Object> warrantyList = (List<Object>)inputMap.get('warranty') ;
        List<Object> currencyList = (List<Object>)inputMap.get('currency') ;
        List<SObject> recordList = new List<SObject> ();
        try{
            List<DMT_Warranty__c> prevWar = [SELECT Id FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__c =: (Id)inputMap.get('riskId') ];
            List<DMT_Currency_Provision__c> prevCur = [SELECT Id FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__c =: (Id)inputMap.get('riskId') ];
            DMT_Risk_Line_Term__c riskRecord = [SELECT Id, gf_group_priority_line_id__c FROM DMT_Risk_Line_Term__c WHERE Id =: (Id)inputMap.get('riskId') LIMIT 1];


            if(!prevWar.isEmpty()){
                delete prevWar;
            }
            if(!prevCur.isEmpty()){
                delete prevCur;
            }
            for (Object war : warrantyList) {
            if(war != ''){
                DMT_Warranty__c warrantyrecord = new DMT_Warranty__c ();
                warrantyrecord.g_entific_id__c = 'HO';
                //warrantyrecord.gf_group_line_id__c = (String)inputMap.get('lineId');
                warrantyrecord.gf_origin_application_type__c = (String)inputMap.get('origin') == 'MENTOR' ? '09' : ((String)inputMap.get('origin') == 'AMIWEB' ? '05' : '04');
                warrantyrecord.DMT_Risk_Line_Term__c = (String)inputMap.get('riskId');
                warrantyrecord.g_limits_grid_guarantee_type__c = String.valueOf(war).trim();
                warrantyrecord.Name = String.valueOf(war);
                warrantyrecord.gf_group_priority_line_id__c = riskRecord.gf_group_priority_line_id__c;
                recordList.add(warrantyrecord);
            }
                
            }
            for (Object cur : currencyList) {
            if(cur != ''){
                DMT_Currency_Provision__c currencyrecord = new DMT_Currency_Provision__c ();
                currencyrecord.g_entific_id__c = 'HO';
                //currencyrecord.gf_group_line_id__c = (String)inputMap.get('lineId');
                currencyrecord.gf_origin_application_type__c = (String)inputMap.get('origin') == 'MENTOR' ? '09' : ((String)inputMap.get('origin') == 'AMIWEB' ? '05' : '04');
                currencyrecord.DMT_Risk_Line_Term__c = (String)inputMap.get('riskId');
                currencyrecord.g_currency_id__c = String.valueOf(cur).trim();
                currencyrecord.Name = String.valueOf(cur);
                currencyrecord.gf_group_priority_line_id__c = riskRecord.gf_group_priority_line_id__c;
                recordList.add(currencyrecord);
            }

            }
            insert recordList;

            System.debug(result);
        }catch(Exception e) {
            System.debug('Exception ' + e.getMessage());
            //DES_Exception_Utils.logException(e,'DMT_DealManagement_Handler', 'insertWarrantyCurrency', 'DMT', '');
        }
        return recordList.size();
    }

    public Integer reorderpriorityRisk(Map<String, Object> arguments)
    {   
        List<DMT_Risk_Line_Term__c> relatedRisks = new List<DMT_Risk_Line_Term__c> ();
        List<DMT_Warranty__c> relatedWar = new List<DMT_Warranty__c> ();
        List<DMT_Currency_Provision__c> relatedCur = new List<DMT_Currency_Provision__c> ();
        Id lineId = (Id)arguments.get('recordId');
        try{
            relatedRisks = [SELECT Id,gf_group_priority_line_id__c, DMT_Line__r.Line_Id__c FROM DMT_Risk_Line_Term__c where DMT_Line__c =:lineId order by CreatedDate asc];
            Set<Id> resultIds = (new Map<Id,SObject>(relatedRisks)).keySet();
            relatedWar = [SELECT Id,gf_group_priority_line_id__c, DMT_Risk_Line_Term__r.gf_group_priority_line_id__c FROM DMT_Warranty__c where DMT_Risk_Line_Term__c IN :resultIds order by CreatedDate asc];
            relatedCur = [SELECT Id,gf_group_priority_line_id__c, DMT_Risk_Line_Term__r.gf_group_priority_line_id__c FROM DMT_Currency_Provision__c where DMT_Risk_Line_Term__c IN :resultIds order by CreatedDate asc];
            Integer iterator = 1;
            for (DMT_Risk_Line_Term__c risk : relatedRisks) {
                risk.gf_group_priority_line_id__c = String.valueOf('0' + iterator).right(2);
                risk.DMT_RiskLineTermId__c = risk.DMT_Line__r.Line_Id__c + '_' + String.valueOf('0' + iterator).right(2);
                iterator ++;
            }
            update relatedRisks;
            for (DMT_Warranty__c war : relatedWar) {
                war.gf_group_priority_line_id__c = war.DMT_Risk_Line_Term__r.gf_group_priority_line_id__c;
            }
            update relatedWar;
            for (DMT_Currency_Provision__c cur : relatedCur) {
                cur.gf_group_priority_line_id__c = cur.DMT_Risk_Line_Term__r.gf_group_priority_line_id__c;
            }
            update relatedCur;
            System.debug(relatedRisks.size());
        }catch(Exception e) {
            System.debug('Exception ' + e);
            //DES_Exception_Utils.logException(e,'DMT_DealManagement_Handler', 'reorderpriorityRisk', 'DMT', '');
        }
        return relatedRisks.size();
    }


    public Integer singularTreasuryConsumption(Map<String,Object> relatedRisks)
    {   
        List<DMT_Risk_Line_Term__c> riskSingularList = new List<DMT_Risk_Line_Term__c>() ;
        
        List<List<DMT_Risk_Line_Term__c>> defRisk = new List<List<DMT_Risk_Line_Term__c>>();
        try{
            List<Object> inputRiskSingular = (List<Object>)relatedRisks.get('riskSingularList');
            String currencyRisk = (String)relatedRisks.get('currency');
            for (Object obj : inputRiskSingular) {
                DMT_Risk_Line_Term__c risk = new DMT_Risk_Line_Term__c();
                Map<String, Object> o = (Map<String, Object>) obj;
                if((String)o.get('tabletype') == DMT_Constants.RSK_DERIVATIVES){
                    if (o.containsKey('amount')) {
                        risk.DMT_Amount__c = Decimal.valueOf(String.valueOf(o.get('amount')));
                    }
                    if (o.containsKey('line')) {
                        risk.DMT_Line__c = (Id)o.get('line'); 
                    }
                    if (o.containsKey('initTerm')) {
                        risk.DMT_Init_Term__c = String.valueOf(o.get('initTerm')); 
                    } 
                    if (o.containsKey('endTerm')) {
                        risk.DMT_End_Term__c = String.valueOf(o.get('endTerm')); 
                    } 
                    if (o.containsKey('maxDate')) {
                        risk.DMT_Max_Date__c = Date.valueOf((String)o.get('maxDate'));
                    }
                    if (o.containsKey('DMT_Singular_Operation__c')) {
                        risk.DMT_Singular_Operation__c = (String)o.get('DMT_Singular_Operation__c'); 
                    } 
                    if (o.containsKey('DMT_Singular__c')) {
                        risk.DMT_Singular__c = Boolean.valueOf(o.get('DMT_Singular__c'));
                    }
                     if (currencyRisk != null) {
                         risk.CurrencyIsoCode = currencyRisk; 
                     }   
                    if (o.containsKey('tabletype')) {
                        risk.DMT_Risk_Type__c = (String)o.get('tabletype'); 
                    } 
                    riskSingularList.add(risk);
                } 
            }
            List<List<DMT_Risk_Line_Term__c>> riskSingularListofList = new List<List<DMT_Risk_Line_Term__c>> {riskSingularList};
            defRisk = DMT_Line_Helper.singularTreasuryConsumption(riskSingularListofList);
            insert defRisk[0];
        }catch(Exception e){
            System.debug('Exception ' + e);
        }
        
        return defRisk[0].size();
    }
}