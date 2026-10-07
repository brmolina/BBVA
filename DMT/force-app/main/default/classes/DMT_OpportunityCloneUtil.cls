public without sharing class DMT_OpportunityCloneUtil {
    public class CloneInput {
        @InvocableVariable
        public Opportunity originalOpportunity;
        
        @InvocableVariable
        public DMT_Opportunity_Client__c opportunityClient;
        
        @InvocableVariable
        public List<OpportunityLineItem> opportunityLineItems;
        
        @InvocableVariable
        public List<DMT_Opportunity_Tenor__c> tenors;
        
        @InvocableVariable
        public List<DMT_Opportunity_Mitigant__c> mitigants;
        
        @InvocableVariable
        public Account localClient;
        
        @InvocableVariable
        public List<DMT_TeamMember__c> participants;
        
    }
    
    
    public class CloneResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
        @InvocableVariable public Id newOpportunityId;
    }
    
    private class MainHolderSelection {
        public Id accountId;
        public String customerId;
        public String groupId;
        public String countryIfoId;
        public DMT_HPG_GlobalPosition.Data clientData;
    }
    
    @InvocableMethod(label='Clonar oportunidad y datos relacionados desde Flow')
    public static List<CloneResult> clone(List<CloneInput> inputs) {
        
        Savepoint cloneSavepoint = null;
        List<CloneResult> results = new List<CloneResult>();
        CloneResult result = new CloneResult();
        OppWrapper ow = new OppWrapper();
        DMT_CreateOpportunityService.ClientValues clientValues = new DMT_CreateOpportunityService.ClientValues();
        Map<String, Object> leveragedLendingOutput = new Map<String, Object>();
        Opportunity oppCloned = new Opportunity();
        
        try {
            for (CloneInput input : inputs) {
                ow.oppOriginal= input?.originalOpportunity;
                //ow.oppMainHolder;
                ow.oppLocalClient = input?.localClient;
                ow.oppCloneClient =input?.opportunityClient;
                ow.OLIs  =input?.opportunityLineItems;
                ow.tenors =input?.tenors;
                ow.mitigants =input?.mitigants;
                ow.oppParticipants = input?.participants;
                ow.oppOriginalEntific= input?.originalOpportunity.Entific__c;
                System.debug('WRAPPER RELLENO OW=>'+ow);
            }//FOR
            Boolean isSameAccount = ow.oppOriginal.AccountId == ow.oppLocalClient.Id;
            Boolean isSubsidiaryTarget = ow.oppLocalClient.DES_Client_Type__c == 'Subsidiary';
            Date lastDate;
            String lastDatetxt;
            MainHolderSelection mainHolderSelection;
            DMT_HPG_GlobalPosition.Wrapper subsidiaryWrapper;

            // Same-account clones preserve the original data snapshot. For a different target,
            // all destination-data service calls must complete before the first DML operation.
            if (!isSameAccount) {
                lastDatetxt = DMT_HPG_Utils.lastDate();
                lastDate = Date.valueOf(lastDatetxt);

                if (isSubsidiaryTarget) {
                    System.debug('Clonamos hacia un cliente subsidiaria');
                    subsidiaryWrapper = DMT_HPG_MainTableCustomController.fetchClientDataFromServiceLine(
                        null,
                        '1',
                        '5000',
                        new List<String>(),
                        lastDate,
                        'Y',
                        ow.oppLocalClient.Id
                    );

                    System.debug('Account subsidiaria DATA SERVICIO =>'+subsidiaryWrapper);
                    System.debug('ID CUENTA EN LA QUE VAMOS A CLONAR =>'+ow.oppLocalClient.Id );
                    Map<String, Object> comparisonResult = DMT_Opportunity_Utils.getComparisonAccount(
                        new Map<String, Object>{ 'oppAccountId' => ow.oppLocalClient.Id },
                        new Map<String, Object>(),
                        null
                    );
                    Id comparisonAccountId = (Id) comparisonResult.get('comparisonAccountId');
                    System.debug('***** COMPARISON ACCOUNT ID clonada (La cuenta "padre" de la que saca data)=>'+comparisonAccountId);

                    clientValues = DMT_CreateOpportunityService.getClientValues(ow.oppLocalClient.Id, comparisonAccountId);
                    System.debug('***** clientValues ID clonada=>'+clientValues);

                    leveragedLendingOutput = DMT_Callout_LeveragedLending.callLeveragedLendingService(
                        clientValues.groupCode, lastDatetxt, new Map<String, Object>()
                    );
                } else {
                    mainHolderSelection = resolveMainHolderSelection(
                        ow.oppLocalClient.Id,
                        ow.oppOriginal.Entific__c,
                        lastDate
                    );
                    System.debug('MAIN HOLDER SELECTION =>'+mainHolderSelection);

                    Map<String, Object> comparisonResult = DMT_Opportunity_Utils.getComparisonAccount(
                        new Map<String, Object>{ 'oppAccountId' => mainHolderSelection.accountId },
                        new Map<String, Object>(),
                        null
                    );
                    Id comparisonAccountId = (Id) comparisonResult.get('comparisonAccountId');
                    clientValues = DMT_CreateOpportunityService.getClientValues(
                        mainHolderSelection.accountId,
                        comparisonAccountId
                    );
                    leveragedLendingOutput = DMT_Callout_LeveragedLending.callLeveragedLendingService(
                        clientValues.groupCode, lastDatetxt, new Map<String, Object>()
                    );
                }
            }
            
            //OPP clonada
            oppCloned = ow.oppOriginal.clone(false, false, false, false);

            //vaciar campo documentos clonados
            oppCloned.CoreDocsTaxonomyValues__c  ='';
            oppCloned.AccountId = ow.oppLocalClient.Id;
            //Servicio para obtener external id
            oppCloned.DMT_Opp_Id__c = getOppIdExternal(ow.oppOriginalEntific);
            cloneSavepoint = Database.setSavepoint();
            oppCloned.StageName = system.Label.Draft_Status;
            oppCloned.OwnerId = UserInfo.getUserId();
            oppCloned.DMT_Sanction__c = null;
            oppCloned.DMT_Parent_Opportunity__c = null;
            oppCloned.DMT_Opp_User_Lock__c = null;
            
            insert oppCloned;
            
            result.newOpportunityId = oppCloned.Id;
            ow.oppCloned = oppCloned;
            
            //--------------------------------------------------------------------------------------------------------------------------------
            //MISMO ACC
            System.debug('Account relacionado a la opp original=>'+ow.oppOriginal.AccountID);
            System.debug('Account elegido por el usuario al que se va a clonar =>'+ow.oppLocalClient.Id);
            
            if(isSameAccount){
                System.debug('Clonamos EN MISMO ACC');
                
                //OPPCLIENT
                if(ow.oppCloneClient != null) {
                    System.debug('EN CLIENT CLONE');
                    DMT_Opportunity_Client__c oppClientClone = ow.oppCloneClient.clone(false, false, false, false);
                    oppClientClone.Id = null;
                    oppClientClone.DMT_MDE_Opportunity__c = ow.oppCloned.Id;
                    insert oppClientClone;
                }

                //RELATED
                cloneRelatedRecords(oppCloned, ow);

                //ASSO
                List<Custom_Association_Opportunity__c> customAssoOpp = [SELECT Id, Name,CreatedDate, Opportunity__c, Group__c, g_customer_id__c, g_group_id__c, gf_customer_group_id__c, gf_cutoff_date__c, gf_origin_application_type__c, g_entific_id__c 
                                                                     FROM Custom_Association_Opportunity__c 
                                                                     WHERE Opportunity__c =:ow.oppOriginal.Id LIMIT 1];
                System.debug('ASSO OP =>'+customAssoOpp);
                List<DMT_Custom_Association_ClientOpportunity__c> lCustomAssoClientOppOriginal=[SELECT Id, Name, DMT_Custom_Association_Opportunity__c,
                                                                                DMT_g_customer_id__c,DMT_gf_customer_group_id__c 
                                                                                    FROM DMT_Custom_Association_ClientOpportunity__c
                                                                                        WHERE DMT_Custom_Association_Opportunity__r.Opportunity__c =: ow.oppOriginal.Id];
                
                System.debug('ASSO CLI OP =>'+lCustomAssoClientOppOriginal);
                //Objeto para opp multiholder, relacionado con opp y indica el mainholder ( cliente principal)
                Custom_Association_Opportunity__c customAssoOppClone=new Custom_Association_Opportunity__c();
                
                if(customAssoOpp != null && !customAssoOpp.isEmpty()){
                    customAssoOppClone.Opportunity__c = ow.oppCloned.Id;
                    customAssoOppClone.Group__c = customAssoOpp[0].Group__c;
                    customAssoOppClone.g_customer_id__c = customAssoOpp[0].g_customer_id__c;
                    customAssoOppClone.g_group_id__c = customAssoOpp[0].g_group_id__c;
                    customAssoOppClone.gf_customer_group_id__c = ow.oppCloned.DMT_Opp_Id__c;
                    customAssoOppClone.gf_origin_application_type__c = customAssoOpp[0].gf_origin_application_type__c;
                    
                    insert customAssoOppClone;
                }
                
                
                if(!lCustomAssoClientOppOriginal.isEmpty()){
                    //Relaciones de la opp con cada cliente ( caso opp multiholder)
                    List<DMT_Custom_Association_ClientOpportunity__c> lCustomAssoClientOppOriginalAux=new List<DMT_Custom_Association_ClientOpportunity__c>();
                    
                    for(DMT_Custom_Association_ClientOpportunity__c cAssOpp : lCustomAssoClientOppOriginal){
                        
                        DMT_Custom_Association_ClientOpportunity__c cAssOppAux=new DMT_Custom_Association_ClientOpportunity__c();
                        cAssOppAux.DMT_Custom_Association_Opportunity__c = customAssoOppClone.Id;
                        cAssOppAux.DMT_g_customer_id__c =  cAssOpp.DMT_g_customer_id__c;
                        cAssOppAux.DMT_gf_customer_group_id__c = ow.oppCloned.DMT_Opp_Id__c;
                        cAssOppAux.DMT_g_entific_id__c = ow.oppOriginal.Entific__c;
                        
                        lCustomAssoClientOppOriginalAux.add(cAssOppAux);
                    }
                    
                    if(!lCustomAssoClientOppOriginalAux.isEmpty()){
                        insert lCustomAssoClientOppOriginalAux;
                    }
                }
                
                result.success = true;
                results.add(result);

                System.debug('END IF MISMA CUENTA');
            }else{
                System.debug('Diferente cuenta');
                //SUBSIDIARY
                if(isSubsidiaryTarget){
                    System.debug('Diferente a subsidiary');
                    if(ow.oppLocalClient != null) {

                        //Servicio leveraged lending
                        String leveragedLendingIndType = (leveragedLendingOutput != null) ? (String) leveragedLendingOutput.get('leveragedLendingIndType') : null;
                        if (subsidiaryWrapper == null || !subsidiaryWrapper.success || subsidiaryWrapper.data == null || subsidiaryWrapper.data.isEmpty()) {
                            throw new CloneException('The service did not return client data.');
                        }

                        DMT_Opportunity_Client__c dmtClient = DMT_CreateOpportunityService.buildOpportunityClient(
                        oppCloned.Id,
                        clientValues,
                        subsidiaryWrapper.data[0],
                        leveragedLendingIndType,
                        null);

                        System.debug('···················Opportunity client clonado =>'+dmtClient);
                        insert dmtClient;
                    }

                    cloneRelatedRecords(oppCloned, ow);
                    
                    result.success = true;
                    results.add(result);
                    
                }else{
                     System.debug('Diferente a un grupo');
                    if (ow.oppLocalClient.DES_Client_Type__c != 'Subsidiary') {
                        String leveragedLendingIndType = leveragedLendingOutput != null
                            ? (String) leveragedLendingOutput.get('leveragedLendingIndType')
                            : null;
                        createMainHolderAssociations(
                            oppCloned,
                            mainHolderSelection,
                            clientValues,
                            leveragedLendingIndType
                        );
                    }
                    
                    if(oppCloned != null) {
                        cloneRelatedRecords(oppCloned, ow);
                        result.success = true;
                        results.add(result);
                    }
                }
            }
        } catch (Exception ex) {
            if (cloneSavepoint != null) {
                Database.rollback(cloneSavepoint);
            }
            result.success = false;
            result.newOpportunityId = null;
            result.errorMessage = ex.getMessage();
            results.add(result);
        }
        
        System.debug('RESULTS =>>'+results);
        return results;
    }
    
    private static MainHolderSelection resolveMainHolderSelection(Id localClientId, String sourceEntific, Date lastDate) {
        System.debug('Resolving main holder selection for local client ' + localClientId + ' and source Entific ' + sourceEntific);
        if (localClientId == null || String.isBlank(sourceEntific)) {
            throw new CloneException('Cannot resolve the main holder without a local client and source Entific.');
        }
        
        DMT_HPG_GlobalPosition.Wrapper serviceResponse =
            DMT_HPG_MainTableCustomController.fetchClientDataFromService(
            localClientId,
        '1',
        '5000',
        new List<String>(),
        lastDate,
        'Y',
        ''
            );
        
        System.debug('Service response: ' + JSON.serialize(serviceResponse));
        
        if (serviceResponse == null || !serviceResponse.success || serviceResponse.data == null || serviceResponse.data.isEmpty()) {
            throw new CloneException('The main holder service did not return client data.');
        }
        
        String normalizedEntific = sourceEntific.trim().toUpperCase();
        List<DMT_HPG_GlobalPosition.Data> candidates = new List<DMT_HPG_GlobalPosition.Data>();
        Set<String> customerIds = new Set<String>();
        
        for (DMT_HPG_GlobalPosition.Data client : serviceResponse.data) {
            if (client != null
                && String.isNotBlank(client.customerId)
                && String.isNotBlank(client.countryIfoId)
            && client.countryIfoId.trim().toUpperCase() == normalizedEntific) {
                candidates.add(client);
                customerIds.add(client.customerId);
            }
        }
        
        if (candidates.isEmpty()) {
            throw new CloneException('The main holder service did not return a client for Entific ' + normalizedEntific + '.');
        }
        
        Map<String, Id> accountIdsByCustomerId =
            DMT_HPG_MainTableCustomController.getSalesforceAccountIdsByCustomerIds(
            new List<String>(customerIds)
            );
        
        for (DMT_HPG_GlobalPosition.Data candidate : candidates) {
            Id accountId = accountIdsByCustomerId.get(candidate.customerId);
            if (accountId != null) {
                MainHolderSelection selection = new MainHolderSelection();
                selection.accountId = accountId;
                selection.customerId = candidate.customerId;
                selection.groupId = candidate.groupId;
                selection.countryIfoId = candidate.countryIfoId;
                selection.clientData = candidate;
                return selection;
            }
        }
        
        throw new CloneException('No Salesforce Account was found for Entific ' + normalizedEntific + '.');
    }
    
    private static void createMainHolderAssociations(
        Opportunity oppCloned,
        MainHolderSelection selection,
        DMT_CreateOpportunityService.ClientValues clientValues,
        String leveragedLendingIndType
    ) {
        if (oppCloned == null || selection == null || selection.accountId == null) {
            throw new CloneException('Cannot create associations without a resolved main holder.');
        }
        
        System.debug('Creating main holder associations for cloned opportunity ' + oppCloned.Id + ' and main holder account ' + selection.accountId);
        Custom_Association_Opportunity__c association = new Custom_Association_Opportunity__c(
            Opportunity__c = oppCloned.Id,
        Group__c = selection.accountId,
        g_customer_id__c = selection.customerId,
        g_group_id__c = selection.groupId,
        gf_customer_group_id__c = oppCloned.DMT_Opp_Id__c);
        insert association;
        
        DMT_Opportunity_Client__c opportunityClient = DMT_CreateOpportunityService.buildOpportunityClient(
            oppCloned.Id,
            clientValues,
            selection.clientData,
            leveragedLendingIndType,
            null
        );
        opportunityClient.Custom_Association__c = association.Id;
        opportunityClient.Alpha_Code_Client__c = selection.customerId;
        insert opportunityClient;
        
        insert new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = association.Id,
        DMT_g_customer_id__c = selection.customerId,
        DMT_gf_customer_group_id__c = oppCloned.DMT_Opp_Id__c,
        DMT_g_entific_id__c = selection.countryIfoId);
    }
    
    private class CloneException extends Exception {}
    
    
    private static void cloneRelatedRecords(Opportunity newOpp, OppWrapper ow) {
        Map<Id, Id> oldOLItoNewOLI = new Map<Id, Id>();
        List<SObject> recordsToInsert = new List<SObject>();
        if(ow.OLIs != null) {
            Map<Id, OpportunityLineItem> clonedOLIsByOriginalId = new Map<Id, OpportunityLineItem>();
            for (OpportunityLineItem originalOli : ow.OLIs) {
                if (originalOli != null) {
                    OpportunityLineItem clone = originalOli.clone(false, false, false, false);
                    clone.Id = null;
                    clone.OpportunityId = newOpp.Id;
                    
                    // Explicit mapping for Line fields that may not be populated by clone() in this flow context.
                    clone.DMT_Line_Amount__c = originalOli.DMT_Line_Amount__c;
                    clone.DMT_Commitment_Line_Amount__c = originalOli.DMT_Commitment_Line_Amount__c;
                    clone.DMT_NewMoney_BBVA__c = originalOli.DMT_NewMoney_BBVA__c;
                    clone.DMT_OldMoney_BBVA__c = originalOli.DMT_OldMoney_BBVA__c;
                    clone.DMT_ExpectedFinal_Take__c = originalOli.DMT_ExpectedFinal_Take__c;
                    clone.DMT_Expected_Drawn__c = originalOli.DMT_Expected_Drawn__c;
                    clone.DMT_Liquidity_Fee__c = originalOli.DMT_Liquidity_Fee__c;
                    clone.DES_Commitment_Fees__c = originalOli.DES_Commitment_Fees__c;
                    clone.DMT_Extension_Duration_Fees__c = originalOli.DMT_Extension_Duration_Fees__c;
                    clone.DES_Other_Fees__c = originalOli.DES_Other_Fees__c;
                    clone.DMT_Reference_Upfront_Fees__c = originalOli.DMT_Reference_Upfront_Fees__c;
                    clone.DMT_Line_Currency__c = originalOli.DMT_Line_Currency__c;
                    clone.entity_role_type__c = originalOli.entity_role_type__c;
                    clone.DMT_Sub_Limit__c = originalOli.DMT_Sub_Limit__c;
                    clone.bbva_prtcp_tranche_amount__c = originalOli.bbva_prtcp_tranche_amount__c;
                    clone.syndicated_loan_drawn_amount__c = originalOli.syndicated_loan_drawn_amount__c;
                    clone.DMT_Deal_amount__c = originalOli.DMT_Deal_amount__c;
                    clone.g_currency_id__c = originalOli.g_currency_id__c;
                    clone.DMT_TXT_Commitment_Fees__c = !String.isBlank(originalOli.DMT_TXT_Commitment_Fees__c)
                        ? originalOli.DMT_TXT_Commitment_Fees__c
                        : (originalOli.DES_Commitment_Fees__c != null ? String.valueOf(originalOli.DES_Commitment_Fees__c) : null);
                    clone.DMT_TXT_Extension_Duration_Fees__c = !String.isBlank(originalOli.DMT_TXT_Extension_Duration_Fees__c)
                        ? originalOli.DMT_TXT_Extension_Duration_Fees__c
                        : (originalOli.DMT_Extension_Duration_Fees__c != null ? String.valueOf(originalOli.DMT_Extension_Duration_Fees__c) : null);
                    clone.DMT_TXT_Other_Fees_Accrual__c = !String.isBlank(originalOli.DMT_TXT_Other_Fees_Accrual__c)
                        ? originalOli.DMT_TXT_Other_Fees_Accrual__c
                        : (originalOli.DES_Other_Fees__c != null ? String.valueOf(originalOli.DES_Other_Fees__c) : null);
                    clone.DMT_TXT_Other_Fees_NonAccrual__c = originalOli.DMT_TXT_Other_Fees_NonAccrual__c;
                    
                    //Added the if to avoid the exception: only one of unit price or total price may be specified
                    if(clone.UnitPrice != null && clone.TotalPrice != null) {
                        clone.UnitPrice = null;
                    }
                    clonedOLIsByOriginalId.put(originalOli.Id, clone);
                }
            }
            System.debug('***Productos clonados a insertar: ' + clonedOLIsByOriginalId);
            insert clonedOLIsByOriginalId.values();
            for (Id originalId : clonedOLIsByOriginalId.keySet()) {
                oldOLItoNewOLI.put(originalId, clonedOLIsByOriginalId.get(originalId).Id);
            }
            if(ow.tenors != null) {
                for (DMT_Opportunity_Tenor__c tenor : ow.tenors) {
                    if (tenor != null) {
                        DMT_Opportunity_Tenor__c clone = tenor.clone(false, false, false, false);
                        clone.Id = null;
                        clone.OwnerId = UserInfo.getUserId();
                        clone.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(tenor.DMT_Opportunity_Product__c);
                        recordsToInsert.add(clone);
                    }
                }
            }
            if(ow.mitigants != null) {
                for (DMT_Opportunity_Mitigant__c mit : ow.mitigants) {
                    if (mit != null) {
                        DMT_Opportunity_Mitigant__c clone = mit.clone(false, false, false, false);
                        clone.Id = null;
                        clone.OwnerId = UserInfo.getUserId();
                        clone.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(mit.DMT_Opportunity_Product__c);
                        recordsToInsert.add(clone);
                    }
                }
            }
            // Clonar Underlyings asociados a los OLIs
            Set<Id> oliIds = new Set<Id>();
            for (OpportunityLineItem oli : ow.OLIs) {
                oliIds.add(oli.Id);
            }
            List<DMT_Underlying__c> sourceUnderlyings = [
                SELECT Name, DMT_Underlying_Type__c,
                       DMT_Max_Amount__c, DMT_Max_Term__c,
                       DMT_Other_restrictions__c,
                       DMT_Drawn_Reference_Amount__c,
                       DMT_Undrawn_Reference_Amount__c,
                       DMT_Term__c,
                       DMT_Drawn_Speed__c,
                       DMT_Undrawn_Spread__c,
                       DMT_Upfront_Fees__c,
                       DMT_Upfront_Fees_amount__c,
                       DMT_Amortization_Type__c,
                       DMT_Interest_Payment_Frequency__c,
                       DMT_Currency__c,
                       DMT_Opportunity_Product__c
                FROM DMT_Underlying__c
                WHERE DMT_Opportunity_Product__c IN :oliIds
            ];
            if (!sourceUnderlyings.isEmpty()) {
                for (DMT_Underlying__c underlying : sourceUnderlyings) {
                    if (underlying != null) {
                        DMT_Underlying__c clone = underlying.clone(false, false, false, false);
                        clone.Id = null;
                        clone.OwnerId = UserInfo.getUserId();
                        clone.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(underlying.DMT_Opportunity_Product__c);
                        recordsToInsert.add(clone);
                    }
                }
            }
        }
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        cloneParticipants(newOpp, ow.oppParticipants, ow.oppOriginal.AccountId);
    }
    
    public static void cloneParticipants(Opportunity newOpp, List<DMT_TeamMember__c> participants, Id originalAccountId) {
        List<DMT_TeamMember__c> existingParticipants = DMT_cloneParticipantForLine_Selector.getTeamMember(newOpp.Id);
        List<SObject> participantsToInsert = new List<SObject>();
        
        if (newOpp.AccountId == originalAccountId) {
            if (!existingParticipants.isEmpty()) {
                delete existingParticipants;
            }
            if (participants != null) {
                for (DMT_TeamMember__c participant : participants) {
                    if (participant != null) {
                        DMT_TeamMember__c clone = participant.clone(false, false, false, false);
                        clone.Id = null;
                        clone.OwnerId = UserInfo.getUserId();
                        clone.Opportunity__c = newOpp.Id;
                        participantsToInsert.add(clone);
                    }
                }
            }
        }
        if (!participantsToInsert.isEmpty()) {
            insert participantsToInsert;
        }
    }
    
    public static String getOppIdExternal(String entific) {
        Map<String, Object> inputMap = new Map<String, Object>{
            'linOropp' => 'OPP',
            'DMT_Client_Entific__c' => entific
        };
        
        Map<String, Object> wrapperMap = new Map<String, Object>{
            'input' => inputMap,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<String, Object> response = (Map<String, Object>)handler.call('getLineId', wrapperMap);
        
        String lineId = (String)response.get('lineId');
        System.debug('Resultado lineId: ' + lineId);
        return lineId;
    }
    
    public class OppWrapper{
        
        @AuraEnabled
        public Opportunity oppCloned;
        
        @AuraEnabled
        public Opportunity oppOriginal;
        
        @AuraEnabled
        public String oppOriginalEntific;
        
        @AuraEnabled
        public Account oppMainHolder;
        
        
        @AuraEnabled
        public Account oppLocalClient;
        
        @AuraEnabled
        public DMT_Opportunity_Client__c oppCloneClient;
        
        @AuraEnabled
        public Custom_Association_Opportunity__c oppGrupoClonada;
        
        @AuraEnabled
        public List<OpportunityLineItem> OLIs;
        
        @AuraEnabled
        public List<DMT_Opportunity_Tenor__c> tenors;
        
        @AuraEnabled
        public List<DMT_Opportunity_Mitigant__c> mitigants;
        
        @AuraEnabled
        public List<DMT_TeamMember__c> oppParticipants ;
        
        
    }
    
}