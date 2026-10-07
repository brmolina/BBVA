global with sharing class DMT_GetCreationParameters implements Callable{

    public Object call(String action, Map<String, Object> args){

        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);

    }


    global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options) {
        if (methodName == 'getCreationParametersList') {
            List<String> roles = new List<String>();system.debug('getcre'+ inputs);           
            for(Object obj : (List<Object>) inputs.get('roles')){
                roles.add((String)obj);                    
            }
            output.put('result', getCreationParametersList(roles, (String)inputs.get('RecordTypeName'), (Boolean)inputs.get('isSubsidiary'), (String)inputs.get('groupId'), (String)inputs.get('ClientId')));
        }if(methodName == 'getEntityValues'){
            String entific = (String)inputs.get('Entific');
            String initialCatalog = (String)inputs.get('initialCatalog');
            output.put('result', getEntityValues(initialCatalog, entific));
        }if(methodName == 'getBranchValuesH007'){
            String initialCatalog = (String)inputs.get('initialCatalog');
            if(inputs.get('Entity') != null){
                String entity =  (String)inputs.get('Entity');
                output.put('result', getBranchValuesH007(initialCatalog, entity));
            }
            
        }
        return true;
    }

     //This method retrieves the values of entity of the taxonomy values
    public String getEntityValues(String initialCatalog, String entific){
         
           
            List<Object> filteredEntityValues = new List<Object>();
            Map<String, Object> EntityValues = new Map<String, Object>();
            List<String> aux = new List<String>();
            //Filter the values based on the latest cutoff date
            String fixEntific = entific+'%';
            String entityResult = '';
            List<DMT_Taxonomy_Values__c>  unfilteredEntityValues = DMT_Passport_Selector.getTaxonomyValuesByValueAndCatalog(fixEntific, initialCatalog);

            Map<Integer, DMT_Taxonomy_Values__c> taxoMap = new Map<Integer, DMT_Taxonomy_Values__c>();

            for (DMT_Taxonomy_Values__c taxo : unfilteredEntityValues) {
                if (taxo.gf_catalog_atrb_val1_name_c__c != null) {
                    taxoMap.put(Integer.valueOf(taxo.gf_catalog_atrb_val1_name_c__c), taxo);
                }
            }

            Set<Integer> taxoKeys = taxoMap.keySet();
            List<Integer> sortedKeys = new List<Integer>(taxoKeys);
            sortedKeys.sort();

            if(!sortedKeys.isEmpty() && taxoMap.get(sortedKeys[0]).DMT_Value__c != null){
                entityResult = String.valueOf(taxoMap.get(sortedKeys[0]).DMT_Value__c);
            }
            return entityResult;
    }

     //This method retrieves the values of branch of the taxonomy catalog H007
    public List<Object> getBranchValuesH007(String initialCatalog, Object entity){

                System.debug('initialCatalog : ' + initialCatalog +' entity : ' + entity );
                List<Object> filteredBranchValues = new List<Object>();
        
                List<DMT_Taxonomy_Values__c>  latestCutOffDate = [SELECT DMT_Cutoff_Date__c from DMT_Taxonomy_Values__c   where DMT_Catalog__c =: initialCatalog  order by DMT_Cutoff_Date__c desc LIMIT 1];
               
                Map<String, Object> branchValues = new Map<String, Object>();
            
                List<String> aux = new List<String>();
                //Filter the values based on the latest cutoff date
                if(latestCutOffDate.size() > 0){
                    String entityFix = (String)entity + '%';
                    List<DMT_Taxonomy_Values__c>  unfilteredBranchValues =  [SELECT DMT_Value__c, DMT_Name_EN__c from DMT_Taxonomy_Values__c where  DMT_Catalog__c =:initialCatalog  and DMT_Value__c  like: entityFix and DMT_Cutoff_Date__c =: latestCutOffDate[0].DMT_Cutoff_Date__c];
                    for(DMT_Taxonomy_Values__c branchValue :unfilteredBranchValues) { 
                        if(!aux.contains((String)branchValue.DMT_Value__c)){
                            branchValues.put('label',(String) branchValue.DMT_Name_EN__c);
                            branchValues.put('value',(String) branchValue.DMT_Value__c);
                            filteredBranchValues.add(branchValues);
                            branchValues = new Map<String, Object>();
                            aux.add((String) branchValue.DMT_Value__c);
                        }
                    }
                    
                }
            
            return filteredBranchValues;
    }

    //This method retrieves the values of taxonomy that the user has access on his role
    public String getCreationParametersList(final list<String> roles, final String RecordTypeName, final Boolean isSubsidiary, final String groupId, final String clientId) {
        final List<DMT_Creation_Line_Parameters__mdt> creationParametersReturn = new List<DMT_Creation_Line_Parameters__mdt>();

        if(!roles.isEmpty()) {
            final Id groupRtId      = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
            final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
            final List<String> creationParameterValues = new List<String> ();
            String clientType;

            if (groupId != null || clientId != null) {
                List<Account> acc = [SELECT Id, RecordType.Id FROM Account WHERE DES_Group_Code__c =: groupId OR g_customer_Id__C =: clientId LIMIT 1];
                if(acc.size() > 0) {
                    //Prospects
                    if(acc[0].RecordType.Id == groupRtId || acc[0].RecordType.Id == subsidiaryRtId) {
                        clientType = isSubsidiary == true || isSubsidiary == null ? 'Prospect Customer' : 'Prospect Group';
                    //Clients
                    } else {
                        clientType = isSubsidiary == true || isSubsidiary == null ? 'Customer' : 'Group';
                    }
                }
            }
            System.debug('log::roles : ' + roles + ' RecordTypeName : ' + RecordTypeName + ' clientType : ' + clientType);
            final List<DMT_Creation_Line_Parameters__mdt> allcreationParameters = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp, DMT_Role__c, DMT_Value__c, DMT_Operation_Type__c FROM DMT_Creation_Line_Parameters__mdt WHERE DMT_Role__c IN: roles AND DMT_Operation_Type__c=: RecordTypeName AND DMT_Client_Type__c=: clientType];
            if(!allcreationParameters.isEmpty() && allcreationParameters != null) {
                for(DMT_Creation_Line_Parameters__mdt aux : allcreationParameters) {
                    if(!creationParameterValues.contains(aux.DMT_Value__c)) {
                        creationParametersReturn.add(aux);
                        creationParameterValues.add(aux.DMT_Value__c);
                    }
                }
            }
        }
        System.debug('log::creationParametersReturn : ' + JSON.serialize(creationParametersReturn));
        return JSON.serialize(creationParametersReturn);
    }
}