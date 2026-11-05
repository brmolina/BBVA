/**
* ____________________________________________________________________________
* Controller class for hpg_main_table lightning web component
* ____________________________________________________________________________
* @author      torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2023-09-08
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class DMT_HPG_MainTableCustomController {

    @AuraEnabled
    public static DMT_HPG_GlobalPosition.Wrapper fetchClientDataFromService(Id clientId, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType, String customerId) {
        DMT_HPG_GlobalPosition.Wrapper clients = new DMT_HPG_GlobalPosition.Wrapper();
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        Boolean isCustomerIdQuery = false;

        if (countries != null && countries.size() > 0 ) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(String.isNotBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            if(!countriesToSend.isEmpty()){
                payload.put('countries', countriesToSend);
            }
        }
        if(clientId != null && String.isNotBlank(String.valueOf(clientId))){
            payload.put('groupId', DMT_HPG_Utils.getGroupId(clientId));
        }
        else if(String.isNotBlank(customerId)){
            isCustomerIdQuery = true;
            String customerIdPayLoad = DMT_HPG_Utils.getAlphaCode(customerId);

            if(customerIdPayLoad == null){
                System.debug('ABS TEST customerId');
                List<Account> acc = [SELECT Id, DES_Group_Code__c, RecordType.DeveloperName, g_customer_id__c FROM Account WHERE Id =:customerId WITH USER_MODE];
                if(!acc.isEmpty() && acc[0].RecordType.DeveloperName == 'Prospect_Subsidiary') {
                    customerIdPayLoad =  acc[0].g_customer_id__c;
                }
                else if(!acc.isEmpty() && acc[0].DES_Group_Code__c =='GXXXXXXXXXXXXXX' ){
                    customerIdPayLoad =  'ES0182XXXXXXXXX' ;
                }
            }
            payload.put('customerId', customerIdPayLoad);
        }

        payload.put('clientDataOption', 'D');
        if (!isCustomerIdQuery) {
            payload.put('paginationKey', page);
            payload.put('pageSize', pageSize);
        }
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType', (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        System.debug('Request Test: ' + request);
        clients = DMT_HPG_GlobalPosition.getGlobalPosition(request);
        System.debug('Response Test: ' + clients);
        return enrichClientData(clients);
    }

    @AuraEnabled
    public static DMT_HPG_GlobalPosition.Wrapper fetchClientDataFromServiceLine(Id clientId, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType, String customerId) {
        DMT_HPG_GlobalPosition.Wrapper clients = new DMT_HPG_GlobalPosition.Wrapper();
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        Boolean isCustomerIdQuery = false;

        if (countries != null && countries.size() > 0 ) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(String.isNotBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            if(!countriesToSend.isEmpty()){
                payload.put('countries', countriesToSend);
            }
        }
        if(clientId != null && String.isNotBlank(String.valueOf(clientId))){
            Map<String, Object> recordCodeResult = DMT_HPG_Utils.getRecordCodeFromAccount(clientId);
            String  recordCode = (String) recordCodeResult.get('recordCode');

            Account acc = [
                    SELECT Id, DES_Group_Code__c, g_customer_id__c, DES_Client_Type__c
                    FROM Account
                    WHERE Id = :clientId
                    WITH USER_MODE
                    LIMIT 1
                ];

            if (acc.DES_Client_Type__c == 'Subsidiary') {
                isCustomerIdQuery = true;
                payload.put('customerId', recordCode);
            } else {
                payload.put('groupId', DMT_HPG_Utils.getGroupId(clientId));
            }
        }
        else if(String.isNotBlank(customerId)){
            isCustomerIdQuery = true;
            String customerIdPayLoad = DMT_HPG_Utils.getAlphaCode(customerId);

            if(customerIdPayLoad == null){
                List<Account> acc = [SELECT Id,DES_Group_Code__c, RecordType.DeveloperName, g_customer_id__c FROM Account WHERE Id =:customerId WITH USER_MODE];
                if(!acc.isEmpty() && acc[0].RecordType.DeveloperName == 'Prospect_Subsidiary') {
                    customerIdPayLoad =  acc[0].g_customer_id__c;
                }
                else if(!acc.isEmpty() && acc[0].DES_Group_Code__c =='GXXXXXXXXXXXXXX' ){
                    customerIdPayLoad =  'ES0182XXXXXXXXX' ;
                }
            }
            payload.put('customerId', customerIdPayLoad);
        }

        payload.put('clientDataOption', 'D');
        if (!isCustomerIdQuery) {
            payload.put('paginationKey', page);
            payload.put('pageSize', pageSize);
        }
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType', (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        clients = DMT_HPG_GlobalPosition.getGlobalPosition(request);
        return enrichClientData(clients);
    }

    private static DMT_HPG_GlobalPosition.Wrapper enrichClientData(DMT_HPG_GlobalPosition.Wrapper clients) {
        if (clients != null && clients.data != null) {
            for (DMT_HPG_GlobalPosition.Data data : clients.data) {
                if (data.ratingGenerationDate != null) {
                    Datetime ratingGenerationDateTime = (DateTime) JSON.deserialize('"' + data.ratingGenerationDate + '"', DateTime.class);
                    Date ratingGenerationDate = date.newinstance(ratingGenerationDateTime.year(), ratingGenerationDateTime.month(), ratingGenerationDateTime.day());
                    data.ratingGenerationDate = String.valueOf(ratingGenerationDate);
                }
                data.sectorAA    = DMT_HPG_Utils.unNullValue(data.assetAllocationSectorType, '') + '/' + DMT_HPG_Utils.unNullValue(data.assetAllcSectorDesc, '');
                data.subSectorAA = DMT_HPG_Utils.unNullValue(data.assetAllocationSubSecType, '') + '/' + DMT_HPG_Utils.unNullValue(data.aaSubSectorDesc, '');
                data.activityAA  = DMT_HPG_Utils.unNullValue(data.assetAllocationActvyType, '') + '/' + DMT_HPG_Utils.unNullValue(data.aaActivityDesc, '');
            }
        }
        return clients;
    }

    @AuraEnabled
    public static String getClientId(String clientId) {
        String res;
        List<Account> acc = [SELECT Name, DES_Structure_Type__c, DES_Group_Code__c, g_customer_id__c FROM Account WHERE Id =:clientId WITH SECURITY_ENFORCED];
        if (acc.size() > 0 && acc[0].DES_Structure_Type__c == 'Group' || acc[0].DES_Structure_Type__c == 'Supragroup') {
            res = acc[0].DES_Group_Code__c;
        } else {
            if (acc.size() > 0 && acc[0].g_customer_id__c != null) {
                res = acc[0].g_customer_id__c;
            }
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static string getRecordCode(String clientId) {
        return DMT_HPG_Utils.getRecordCode(clientId);
    }

    @AuraEnabled
    public static DMT_HPG_UsedTables.Wrapper fetchUsedTablesDataFromService(Date searchDate, String pageSize, String page) {
        Map<String, Object> request = new Map<String, Object>();
        String paginationKey = '1';
        if (page != null) {
            paginationKey = page;
        }
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        request.put('searchDate', searchDate);
        request.put('pageSize', pageSize);
        request.put('paginationKey', paginationKey);
        DMT_HPG_UsedTables.Wrapper usedTables = DMT_HPG_UsedTables.getUsedTables(request);
        return usedTables;
    }

    @AuraEnabled
    public static String userIsAdmin() {
       return String.valueOf(DMT_HPG_Utils.userCanEdit());
    }

    @AuraEnabled
    public static List<String> getAllGroups() {
       return new List<String>();
    }
    
    @AuraEnabled(cacheable = true)
    public static Object fetchInitialData(String selectedTab, Id clientId, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize, String customerId) {
        Object res;
        final Date dateFrom = Date.valueOf(searchDate);
        final List<String> countries = new List<String>();
        res = new DMT_HPG_GlobalPosition.Wrapper();
        res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);

        return res;
    }

    @AuraEnabled(cacheable = true)
    public static Object fetchClientInitialData(String selectedTab, Id clientId, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize, String customerId) {
        Object res;
        final Date dateFrom = Date.valueOf(searchDate);
        final List<String> countries = new List<String>();
        res = new DMT_HPG_GlobalPosition.Wrapper();
         res = fetchClientDataFromServiceLine(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
         
         return res;
    }

    @AuraEnabled
    public static Object fetchData(String selectedTab, Id clientId, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize, String customerId) {
        Object res = fetchInitialData(selectedTab, clientId, lCountries, searchDate, clientPositionsType, page, pageSize, customerId);
        return res;
    }

    @AuraEnabled
    public static Id getAccountIdFromRecordId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        String sobjectType = recordId.getSObjectType().getDescribe().getName();

        if (sobjectType == 'Account') {
            return recordId;
        } else if (sobjectType == 'Opportunity') {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :recordId];
            return opp.AccountId;
        } else if (sobjectType == 'DMT_Line__c') {
            // Assuming the object type is "Line" and it has a lookup field to Account
            DMT_Line__c line = [SELECT Client__c FROM DMT_Line__c WHERE Id = :recordId];
            return line.Client__c;
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getSalesforceAccountIdsByCustomerIds(List<String> customerIds) {
        Map<String, Id> result = new Map<String, Id>();

        if (customerIds == null || customerIds.isEmpty()) {
            return result;
        }

        for (Account acc : [
            SELECT Id, g_customer_id__c
            FROM Account
            WHERE g_customer_id__c IN :customerIds
        ]) {
            result.put(acc.g_customer_id__c, acc.Id);
        }

        return result;
    }

    public static String calculateSegment(String segmentCode){

        if(segmentCode == '00005') return 'Corporates';
        if(segmentCode == '00006') return 'Fin Inst-B';
        if(segmentCode == '00001') return 'Sov';
        if(segmentCode == '00002') return 'Pub Inst';
        if(segmentCode == '00003') return 'FINS';

        return '';
    }

    /* NEW MULTIHOLDER MODEL METHOD 
    @AuraEnabled
    public static void saveOpportunityClients(List<Object> selectedClients, Id opportunityId){

        if(opportunityId == null){
            throw new AuraHandledException('OpportunityId is null');
        }

        Set<String> incomingAlphaCodes = new Set<String>();

        if(selectedClients != null){
            for(Object obj : selectedClients){
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));

                String alphaCode = (String) row.get('customerId');

                if(String.isNotBlank(alphaCode)){
                    incomingAlphaCodes.add(alphaCode);
                }
            }
        }

        // Traemos TODOS los existentes
        List<DMT_Opportunity_Client__c> existingRecords = [
            SELECT Id, Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
        ];

        List<Custom_Association_Opportunity__c> association = [
            SELECT Id, g_customer_id__c, Group__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            LIMIT 1
        ];

        String segmentCode;

        if(!association.isEmpty() && association[0].Group__c != null){
            Account acc = [
                SELECT Id, DES_Segment__c
                FROM Account
                WHERE Id = :association[0].Group__c
                LIMIT 1
            ];

            segmentCode = acc.DES_Segment__c;
        }

        Map<String, DMT_Opportunity_Client__c> existingByAlpha = new Map<String, DMT_Opportunity_Client__c>();

        for(DMT_Opportunity_Client__c rec : existingRecords){
            if(rec.Alpha_Code_Client__c != null){
                existingByAlpha.put(rec.Alpha_Code_Client__c, rec);
            }
        }

        List<DMT_Opportunity_Client__c> toInsert = new List<DMT_Opportunity_Client__c>();
        List<DMT_Opportunity_Client__c> toDelete = new List<DMT_Opportunity_Client__c>();

        if(selectedClients != null){
            for(Object obj : selectedClients){

                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));

                String alphaCode = (String) row.get('customerId');

                if(String.isNotBlank(alphaCode) && !existingByAlpha.containsKey(alphaCode)){

                    DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c();

                    client.DMT_Activity__c = (String) row.get('assetAllocationActvyType');
                    client.DMT_Sector__c = (String) row.get('assetAllocationSectorType');
                    client.DMT_Subsector__c = (String) row.get('assetAllocationSubSecType');
                    client.DMT_External_Rating_Fitch__c = (String) row.get('fitchLtRatingLcType');
                    client.DMT_External_Rating_Moodys__c = (String) row.get('moodysLtRatingLcType');
                    client.DMT_External_Rating_SP__c = (String) row.get('spLtRatingLcType');
                    client.External_Rating__c = (String) row.get('unifiedExtRatgLtFcType');
                    client.g_upd_lmscl_internal_ratg_type__c = (String) row.get('updLmsclInternalRatgType');
                    client.Alpha_Code_Client__c = (String) row.get('customerId');
                    client.DMT_MDE_Opportunity__c = opportunityId;
                    client.Custom_Association__c = association.isEmpty() ? null : association[0].Id;
                    client.Counterpart__c = calculateSegment(segmentCode);
                    Object scoringValue = row.get('totalRatingScoreNumber');
                    if(scoringValue != null){
                        Decimal rawValue = Decimal.valueOf(String.valueOf(scoringValue));
                        client.DMT_Scoring__c = rawValue.setScale(2, RoundingMode.HALF_UP);
                    }

                    toInsert.add(client);
                }
            }
        }

        for(DMT_Opportunity_Client__c existing : existingRecords){
            if(existing.Alpha_Code_Client__c == null || !incomingAlphaCodes.contains(existing.Alpha_Code_Client__c)){
                toDelete.add(existing);
            }
        }

        if(!toDelete.isEmpty()){
            delete toDelete;
        }

        if(!toInsert.isEmpty()){
            insert toInsert;
        }
    }*/

    @AuraEnabled
    public static void saveOpportunityClients(List<Object> selectedClients, Id opportunityId){

        if(opportunityId == null){
            throw new AuraHandledException('OpportunityId is null');
        }

        Set<String> incomingAlphaCodes = new Set<String>();
        if(selectedClients != null){
            for(Object obj : selectedClients){
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) row.get('customerId');
                if(String.isNotBlank(alphaCode)){
                    incomingAlphaCodes.add(alphaCode);
                }
            }
        }


        List<Custom_Association_Opportunity__c> association = [
            SELECT Id, g_customer_id__c, gf_customer_group_id__c, Group__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            LIMIT 1
        ];

        if(association.isEmpty()){
            throw new AuraHandledException('No Custom Association found for Opportunity');
        }

        Id assocId = association[0].Id;
        String mainHolderAlphaCode = association[0].g_customer_id__c;

        // Participantes secundarios existentes
        List<DMT_Custom_Association_ClientOpportunity__c> existingSecondaries = [
            SELECT Id, DMT_g_customer_id__c, DMT_gf_customer_group_id__c, DMT_g_entific_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :assocId
        ];
        Map<String, DMT_Custom_Association_ClientOpportunity__c> existingSecondaryByGCustomerId = new Map<String, DMT_Custom_Association_ClientOpportunity__c>();
        for(DMT_Custom_Association_ClientOpportunity__c rec : existingSecondaries){
            if(rec.DMT_g_customer_id__c != null){
                existingSecondaryByGCustomerId.put(rec.DMT_g_customer_id__c, rec);
            }
        }

        // Main Holder existente en DMT_Opportunity_Client__c
        List<DMT_Opportunity_Client__c> existingMainRecords = [
            SELECT Id, Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
        ];
        Map<String, DMT_Opportunity_Client__c> existingMainByAlpha = new Map<String, DMT_Opportunity_Client__c>();
        for(DMT_Opportunity_Client__c rec : existingMainRecords){
            if(rec.Alpha_Code_Client__c != null){
                existingMainByAlpha.put(rec.Alpha_Code_Client__c, rec);
            }
        }

        List<DMT_Opportunity_Client__c> mainToUpsert = new List<DMT_Opportunity_Client__c>();
        List<DMT_Custom_Association_ClientOpportunity__c> toInsertSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();
        List<DMT_Custom_Association_ClientOpportunity__c> toUpdateSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();
        List<DMT_Custom_Association_ClientOpportunity__c> toDeleteSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();

        if(selectedClients != null){
            for(Object obj : selectedClients){
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) row.get('customerId');
                if(String.isBlank(alphaCode)) continue;

                Boolean isMainHolder = alphaCode.equals(mainHolderAlphaCode);

                if(isMainHolder){
                    // HPG data del Main Holder → DMT_Opportunity_Client__c
                    // Reutilizar el registro existente (update) en vez de crear uno nuevo
                    DMT_Opportunity_Client__c client = existingMainRecords.isEmpty()
                        ? new DMT_Opportunity_Client__c(DMT_MDE_Opportunity__c = opportunityId)
                        : new DMT_Opportunity_Client__c(Id = existingMainRecords[0].Id);
                    client.Alpha_Code_Client__c = alphaCode;
                    client.DMT_Activity__c = (String) row.get('assetAllocationActvyType');
                    client.DMT_Sector__c = (String) row.get('assetAllocationSectorType');
                    client.DMT_Subsector__c = (String) row.get('assetAllocationSubSecType');
                    client.DMT_External_Rating_Fitch__c = (String) row.get('fitchLtRatingLcType');
                    client.DMT_External_Rating_Moodys__c = (String) row.get('moodysLtRatingLcType');
                    client.DMT_External_Rating_SP__c = (String) row.get('spLtRatingLcType');
                    client.External_Rating__c = (String) row.get('unifiedExtRatgLtFcType');
                    client.g_upd_lmscl_internal_ratg_type__c = (String) row.get('updLmsclInternalRatgType');
                    Object scoringValue = row.get('totalRatingScoreNumber');
                    if(scoringValue != null){
                        client.DMT_Scoring__c = Decimal.valueOf(String.valueOf(scoringValue)).setScale(2, RoundingMode.HALF_UP);
                    }
                    mainToUpsert.add(client);
                    // Main Holder también en DMT_Custom_Association_ClientOpportunity__c (igual que en Lines)
                    if(!existingSecondaryByGCustomerId.containsKey(alphaCode)){
                        DMT_Custom_Association_ClientOpportunity__c mainAsParticipant = new DMT_Custom_Association_ClientOpportunity__c();
                        mainAsParticipant.DMT_Custom_Association_Opportunity__c = assocId;
                        mainAsParticipant.DMT_g_customer_id__c = alphaCode;
                        mainAsParticipant.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                        mainAsParticipant.DMT_g_entific_id__c = (String) row.get('countryIfoId');
                        toInsertSecondary.add(mainAsParticipant);
                    }
                    else {
                        DMT_Custom_Association_ClientOpportunity__c existingRec = existingSecondaryByGCustomerId.get(alphaCode);
                        if(existingRec != null && existingRec.DMT_g_entific_id__c == null){
                            existingRec.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                            existingRec.DMT_g_entific_id__c = (String) row.get('countryIfoId');
                            toUpdateSecondary.add(existingRec);
                        }
                    }
                } else if(!existingSecondaryByGCustomerId.containsKey(alphaCode)){
                    // Clientes secundarios → DMT_Custom_Association_ClientOpportunity__c (solo identificación)
                    DMT_Custom_Association_ClientOpportunity__c secClient = new DMT_Custom_Association_ClientOpportunity__c();
                    secClient.DMT_Custom_Association_Opportunity__c = assocId;
                    secClient.DMT_g_customer_id__c = alphaCode;
                    secClient.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                    secClient.DMT_g_entific_id__c = (String) row.get('countryIfoId');
                    toInsertSecondary.add(secClient);
                }
                else{
                    DMT_Custom_Association_ClientOpportunity__c existingRec = existingSecondaryByGCustomerId.get(alphaCode);
                    if(existingRec != null && existingRec.DMT_g_entific_id__c == null){
                        existingRec.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                        existingRec.DMT_g_entific_id__c = (String) row.get('countryIfoId');
                        toUpdateSecondary.add(existingRec);
                    }
                }
            }
        }

        // Eliminar secundarios que ya no están seleccionados
        for(DMT_Custom_Association_ClientOpportunity__c existing : existingSecondaries){
            if(existing.DMT_g_customer_id__c == null || !incomingAlphaCodes.contains(existing.DMT_g_customer_id__c)){
                toDeleteSecondary.add(existing);
            }
        }

        if(!toDeleteSecondary.isEmpty()){
            delete toDeleteSecondary;
        } 
        if(!mainToUpsert.isEmpty()){
            upsert mainToUpsert;
        } 
        if(!toInsertSecondary.isEmpty()){
            insert toInsertSecondary;
        }
        if(!toUpdateSecondary.isEmpty()){
            update toUpdateSecondary;
        }
    }

    @AuraEnabled
    public static void updateMainHolderApprovalData(Id opportunityId, String mainHolderPrevious, String mainHolderNew){
        if(opportunityId == null || String.isBlank(mainHolderPrevious) || String.isBlank(mainHolderNew)){
            return;
        }

        //DMT_Opportunity_Client__c
        List<DMT_Opportunity_Client__c> oppClientsNew = [
            SELECT Id, Basic_Financials_Required_Fields__c, DMT_comments__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
            AND Alpha_Code_Client__c = :mainHolderNew
            LIMIT 1
        ];

        List<DMT_Opportunity_Client__c> oppClientsOld = [
            SELECT Id, Basic_Financials_Required_Fields__c, DMT_comments__c,
            Current_FY_Cash_Management_amount__c, Current_FY_Client_Resources_amount__c,
            Current_FY_Corp_Synd_Lending_amount__c, Current_FY_Credit_Equity_amount__c,
            Current_FY_DCM_amount__c, Current_FY_ECM_M_A_Amount__c,
            Current_FY_FX_CCS_amount__c, Current_FY_GTF_amount__c,
            Current_FY_Rates_amount__c, Current_FY_Securities_Services_amount__c,
            Current_FY_Str_Trade_Finance_amount__c, Current_FY_Structured_Finance_amount__c,
            Current_FY_Working_Capital_amount__c,
            Debt_EBITDA_Current_Year_number__c, Debt_EBITDA_Last_Year_number__c,
            Debt_EBITDA_Next_Year_1_number__c, Debt_EBITDA_Next_Year_2_number__c,
            Debt_EBITDA_Next_Year_number__c,
            EBIT_Current_Year_number__c, EBIT_Last_Year_number__c,
            EBIT_Next_Year_1_number__c, EBIT_Next_Year_2_number__c, EBIT_Next_Year_number__c,
            EBITDA_Current_Year_number__c, EBITDA_Last_Year_number__c,
            EBITDA_Next_Year_1_number__c, EBITDA_Next_Year_2_number__c, EBITDA_Next_Year_number__c,
            Free_Cash_Flow_Current_Year_number__c, Free_Cash_Flow_Last_Year_number__c,
            Free_Cash_Flow_Next_Year_1_number__c, Free_Cash_Flow_Next_Year_2_number__c,
            Free_Cash_Flow_Next_Year_number__c,
            Geographical_Footprint_desc__c,
            gf_co_list_tcfd_ind_type__c, gf_customer_sustnbl_strg_desc__c,
            gf_esg_score_close_ope_name__c,
            gf_kpi_trans_fees_2ya_amount__c, gf_kpi_trans_fees_cyr_amount__c,
            gf_kpi_trans_fees_ly_amount__c, gf_kpi_trans_fees_nxy_amount__c,
            gf_paris_agreement_ind_type__c,
            gf_xb_cust_ope_revenue_2ya_per__c, gf_xb_cust_ope_revenue_cyr_per__c,
            gf_xb_cust_ope_revenue_ly_per__c, gf_xb_cust_ope_revenue_nxy_per__c,
            Industry_Overview_desc__c,
            Net_Debt_EBITDA_Current_Year_number__c, Net_Debt_EBITDA_Last_Year_number__c,
            Net_Debt_EBITDA_Next_Year_1_number__c, Net_Debt_EBITDA_Next_Year_2_number__c,
            Net_Debt_EBITDA_Next_Year_number__c,
            Net_Income_Current_Year_number__c, Net_Income_Last_Year_number__c,
            Net_Income_Next_Year_1_number__c, Net_Income_Next_Year_2_number__c,
            Net_Income_Next_Year_number__c,
            Next_FY_Cash_Management_amount__c, Next_FY_Client_Resources_amount__c,
            Next_FY_Corp_Synd_Lending_amount__c, Next_FY_Credit_Equity_amount__c,
            Next_FY_DCM_amount__c, Next_FY_ECM_M_A_amount__c,
            Next_FY_FX_CCS_amount__c, Next_FY_GTF_amount__c, Next_FY_Rates_amount__c,
            Next_FY_Securities_Services_amount__c, Next_FY_Str_Trade_Finance_amount__c,
            Next_FY_Structured_Finance_amount__c, Next_FY_Working_Capital_amount__c,
            Other_Relevant_Ratios_desc__c,
            Past2_FY_Cash_Management_amount__c, Past2_FY_Client_Resources_amount__c,
            Past2_FY_Corp_Synd_Lending_amount__c, Past2_FY_Credit_Equity_amount__c,
            Past2_FY_DCM_amount__c, Past2_FY_ECM_M_A_Amount__c,
            Past2_FY_FX_CCS_amount__c, Past2_FY_GTF_amount__c, Past2_FY_Rates_amount__c,
            Past2_FY_Securities_Services_amount__c, Past2_FY_Str_Trade_Finance_amount__c,
            Past2_FY_Structured_Finance_amount__c, Past2_FY_Working_Capital_amount__c,
            Past_FY_Cash_Management_amount__c, Past_FY_Client_Resources_amount__c,
            Past_FY_Corp_Synd_Lending_amount__c, Past_FY_Credit_Equity_amount__c,
            Past_FY_DCM_amount__c, Past_FY_ECM_M_A_Amount__c,
            Past_FY_FX_CCS_amount__c, Past_FY_GTF_amount__c, Past_FY_Rates_amount__c,
            Past_FY_Securities_Services_amount__c, Past_FY_Str_Trade_Finance_amount__c,
            Past_FY_Structured_Finance_amount__c, Past_FY_Working_Capital_amount__c,
            Relationship_Status_desc__c,
            Revenues_Current_Year_number__c, Revenues_Last_Year_number__c,
            Revenues_Next_Year_1_number__c, Revenues_Next_Year_2_number__c,
            Revenues_Next_Year_number__c,
            DMT_cca__c, DMT_cta__c, DMT_positioning__c, DMT_tri__c, DMT_tri_Engagement_Plan__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
            AND Alpha_Code_Client__c = :mainHolderPrevious
            LIMIT 1
        ];

        if (oppClientsOld.isEmpty()) {
            return;
        }

        DMT_Opportunity_Client__c oppClientOld = oppClientsOld[0];

        
        if (oppClientsNew.isEmpty()) {
            return;
        }

        DMT_Opportunity_Client__c oppClientNew = oppClientsNew[0];


        //Mapear campos
        oppClientNew.DMT_comments__c = oppClientOld.DMT_comments__c;
        oppClientNew.Current_FY_Cash_Management_amount__c = oppClientOld.Current_FY_Cash_Management_amount__c;
        oppClientNew.Current_FY_Client_Resources_amount__c = oppClientOld.Current_FY_Client_Resources_amount__c;
        oppClientNew.Current_FY_Corp_Synd_Lending_amount__c = oppClientOld.Current_FY_Corp_Synd_Lending_amount__c;
        oppClientNew.Current_FY_Credit_Equity_amount__c = oppClientOld.Current_FY_Credit_Equity_amount__c;
        oppClientNew.Current_FY_DCM_amount__c = oppClientOld.Current_FY_DCM_amount__c;
        oppClientNew.Current_FY_ECM_M_A_Amount__c = oppClientOld.Current_FY_ECM_M_A_Amount__c;
        oppClientNew.Current_FY_FX_CCS_amount__c = oppClientOld.Current_FY_FX_CCS_amount__c;
        oppClientNew.Current_FY_GTF_amount__c = oppClientOld.Current_FY_GTF_amount__c;
        oppClientNew.Current_FY_Rates_amount__c = oppClientOld.Current_FY_Rates_amount__c;
        oppClientNew.Current_FY_Securities_Services_amount__c = oppClientOld.Current_FY_Securities_Services_amount__c;
        oppClientNew.Current_FY_Str_Trade_Finance_amount__c = oppClientOld.Current_FY_Str_Trade_Finance_amount__c;
        oppClientNew.Current_FY_Structured_Finance_amount__c = oppClientOld.Current_FY_Structured_Finance_amount__c;
        oppClientNew.Current_FY_Working_Capital_amount__c = oppClientOld.Current_FY_Working_Capital_amount__c;
        oppClientNew.Debt_EBITDA_Current_Year_number__c = oppClientOld.Debt_EBITDA_Current_Year_number__c;
        oppClientNew.Debt_EBITDA_Last_Year_number__c = oppClientOld.Debt_EBITDA_Last_Year_number__c;
        oppClientNew.Debt_EBITDA_Next_Year_1_number__c = oppClientOld.Debt_EBITDA_Next_Year_1_number__c;
        oppClientNew.Debt_EBITDA_Next_Year_2_number__c = oppClientOld.Debt_EBITDA_Next_Year_2_number__c;
        oppClientNew.Debt_EBITDA_Next_Year_number__c = oppClientOld.Debt_EBITDA_Next_Year_number__c;
        oppClientNew.EBIT_Current_Year_number__c = oppClientOld.EBIT_Current_Year_number__c;
        oppClientNew.EBIT_Last_Year_number__c = oppClientOld.EBIT_Last_Year_number__c;
        oppClientNew.EBIT_Next_Year_1_number__c = oppClientOld.EBIT_Next_Year_1_number__c;
        oppClientNew.EBIT_Next_Year_2_number__c = oppClientOld.EBIT_Next_Year_2_number__c;
        oppClientNew.EBIT_Next_Year_number__c = oppClientOld.EBIT_Next_Year_number__c;
        oppClientNew.EBITDA_Current_Year_number__c = oppClientOld.EBITDA_Current_Year_number__c;
        oppClientNew.EBITDA_Last_Year_number__c = oppClientOld.EBITDA_Last_Year_number__c;
        oppClientNew.EBITDA_Next_Year_1_number__c = oppClientOld.EBITDA_Next_Year_1_number__c;
        oppClientNew.EBITDA_Next_Year_2_number__c = oppClientOld.EBITDA_Next_Year_2_number__c;
        oppClientNew.EBITDA_Next_Year_number__c = oppClientOld.EBITDA_Next_Year_number__c;
        oppClientNew.Free_Cash_Flow_Current_Year_number__c = oppClientOld.Free_Cash_Flow_Current_Year_number__c;
        oppClientNew.Free_Cash_Flow_Last_Year_number__c = oppClientOld.Free_Cash_Flow_Last_Year_number__c;
        oppClientNew.Free_Cash_Flow_Next_Year_1_number__c = oppClientOld.Free_Cash_Flow_Next_Year_1_number__c;
        oppClientNew.Free_Cash_Flow_Next_Year_2_number__c = oppClientOld.Free_Cash_Flow_Next_Year_2_number__c;
        oppClientNew.Free_Cash_Flow_Next_Year_number__c = oppClientOld.Free_Cash_Flow_Next_Year_number__c;
        oppClientNew.Geographical_Footprint_desc__c = oppClientOld.Geographical_Footprint_desc__c;
        oppClientNew.gf_co_list_tcfd_ind_type__c = oppClientOld.gf_co_list_tcfd_ind_type__c;
        oppClientNew.gf_customer_sustnbl_strg_desc__c = oppClientOld.gf_customer_sustnbl_strg_desc__c;
        oppClientNew.gf_esg_score_close_ope_name__c = oppClientOld.gf_esg_score_close_ope_name__c;
        oppClientNew.gf_kpi_trans_fees_2ya_amount__c = oppClientOld.gf_kpi_trans_fees_2ya_amount__c;
        oppClientNew.gf_kpi_trans_fees_cyr_amount__c = oppClientOld.gf_kpi_trans_fees_cyr_amount__c;
        oppClientNew.gf_kpi_trans_fees_ly_amount__c = oppClientOld.gf_kpi_trans_fees_ly_amount__c;
        oppClientNew.gf_kpi_trans_fees_nxy_amount__c = oppClientOld.gf_kpi_trans_fees_nxy_amount__c;
        oppClientNew.gf_paris_agreement_ind_type__c = oppClientOld.gf_paris_agreement_ind_type__c;
        oppClientNew.gf_xb_cust_ope_revenue_2ya_per__c = oppClientOld.gf_xb_cust_ope_revenue_2ya_per__c;
        oppClientNew.gf_xb_cust_ope_revenue_cyr_per__c = oppClientOld.gf_xb_cust_ope_revenue_cyr_per__c;
        oppClientNew.gf_xb_cust_ope_revenue_ly_per__c = oppClientOld.gf_xb_cust_ope_revenue_ly_per__c;
        oppClientNew.gf_xb_cust_ope_revenue_nxy_per__c = oppClientOld.gf_xb_cust_ope_revenue_nxy_per__c;
        oppClientNew.Industry_Overview_desc__c = oppClientOld.Industry_Overview_desc__c;
        oppClientNew.Net_Debt_EBITDA_Current_Year_number__c = oppClientOld.Net_Debt_EBITDA_Current_Year_number__c;
        oppClientNew.Net_Debt_EBITDA_Last_Year_number__c = oppClientOld.Net_Debt_EBITDA_Last_Year_number__c;
        oppClientNew.Net_Debt_EBITDA_Next_Year_1_number__c = oppClientOld.Net_Debt_EBITDA_Next_Year_1_number__c;
        oppClientNew.Net_Debt_EBITDA_Next_Year_2_number__c = oppClientOld.Net_Debt_EBITDA_Next_Year_2_number__c;
        oppClientNew.Net_Debt_EBITDA_Next_Year_number__c = oppClientOld.Net_Debt_EBITDA_Next_Year_number__c;
        oppClientNew.Net_Income_Current_Year_number__c = oppClientOld.Net_Income_Current_Year_number__c;
        oppClientNew.Net_Income_Last_Year_number__c = oppClientOld.Net_Income_Last_Year_number__c;
        oppClientNew.Net_Income_Next_Year_1_number__c = oppClientOld.Net_Income_Next_Year_1_number__c;
        oppClientNew.Net_Income_Next_Year_2_number__c = oppClientOld.Net_Income_Next_Year_2_number__c;
        oppClientNew.Net_Income_Next_Year_number__c = oppClientOld.Net_Income_Next_Year_number__c;
        oppClientNew.Next_FY_Cash_Management_amount__c = oppClientOld.Next_FY_Cash_Management_amount__c;
        oppClientNew.Next_FY_Client_Resources_amount__c = oppClientOld.Next_FY_Client_Resources_amount__c;
        oppClientNew.Next_FY_Corp_Synd_Lending_amount__c = oppClientOld.Next_FY_Corp_Synd_Lending_amount__c;
        oppClientNew.Next_FY_Credit_Equity_amount__c = oppClientOld.Next_FY_Credit_Equity_amount__c;
        oppClientNew.Next_FY_DCM_amount__c = oppClientOld.Next_FY_DCM_amount__c;
        oppClientNew.Next_FY_ECM_M_A_amount__c = oppClientOld.Next_FY_ECM_M_A_amount__c;
        oppClientNew.Next_FY_FX_CCS_amount__c = oppClientOld.Next_FY_FX_CCS_amount__c;
        oppClientNew.Next_FY_GTF_amount__c = oppClientOld.Next_FY_GTF_amount__c;
        oppClientNew.Next_FY_Rates_amount__c = oppClientOld.Next_FY_Rates_amount__c;
        oppClientNew.Next_FY_Securities_Services_amount__c = oppClientOld.Next_FY_Securities_Services_amount__c;
        oppClientNew.Next_FY_Str_Trade_Finance_amount__c = oppClientOld.Next_FY_Str_Trade_Finance_amount__c;
        oppClientNew.Next_FY_Structured_Finance_amount__c = oppClientOld.Next_FY_Structured_Finance_amount__c;
        oppClientNew.Next_FY_Working_Capital_amount__c = oppClientOld.Next_FY_Working_Capital_amount__c;
        oppClientNew.Other_Relevant_Ratios_desc__c = oppClientOld.Other_Relevant_Ratios_desc__c;
        oppClientNew.Past2_FY_Cash_Management_amount__c = oppClientOld.Past2_FY_Cash_Management_amount__c;
        oppClientNew.Past2_FY_Client_Resources_amount__c = oppClientOld.Past2_FY_Client_Resources_amount__c;
        oppClientNew.Past2_FY_Corp_Synd_Lending_amount__c = oppClientOld.Past2_FY_Corp_Synd_Lending_amount__c;
        oppClientNew.Past2_FY_Credit_Equity_amount__c = oppClientOld.Past2_FY_Credit_Equity_amount__c;
        oppClientNew.Past2_FY_DCM_amount__c = oppClientOld.Past2_FY_DCM_amount__c;
        oppClientNew.Past2_FY_ECM_M_A_Amount__c = oppClientOld.Past2_FY_ECM_M_A_Amount__c;
        oppClientNew.Past2_FY_FX_CCS_amount__c = oppClientOld.Past2_FY_FX_CCS_amount__c;
        oppClientNew.Past2_FY_GTF_amount__c = oppClientOld.Past2_FY_GTF_amount__c;
        oppClientNew.Past2_FY_Rates_amount__c = oppClientOld.Past2_FY_Rates_amount__c;
        oppClientNew.Past2_FY_Securities_Services_amount__c = oppClientOld.Past2_FY_Securities_Services_amount__c;
        oppClientNew.Past2_FY_Str_Trade_Finance_amount__c = oppClientOld.Past2_FY_Str_Trade_Finance_amount__c;
        oppClientNew.Past2_FY_Structured_Finance_amount__c = oppClientOld.Past2_FY_Structured_Finance_amount__c;
        oppClientNew.Past2_FY_Working_Capital_amount__c = oppClientOld.Past2_FY_Working_Capital_amount__c;
        oppClientNew.Past_FY_Cash_Management_amount__c = oppClientOld.Past_FY_Cash_Management_amount__c;
        oppClientNew.Past_FY_Client_Resources_amount__c = oppClientOld.Past_FY_Client_Resources_amount__c;
        oppClientNew.Past_FY_Corp_Synd_Lending_amount__c = oppClientOld.Past_FY_Corp_Synd_Lending_amount__c;
        oppClientNew.Past_FY_Credit_Equity_amount__c = oppClientOld.Past_FY_Credit_Equity_amount__c;
        oppClientNew.Past_FY_DCM_amount__c = oppClientOld.Past_FY_DCM_amount__c;
        oppClientNew.Past_FY_ECM_M_A_Amount__c = oppClientOld.Past_FY_ECM_M_A_Amount__c;
        oppClientNew.Past_FY_FX_CCS_amount__c = oppClientOld.Past_FY_FX_CCS_amount__c;
        oppClientNew.Past_FY_GTF_amount__c = oppClientOld.Past_FY_GTF_amount__c;
        oppClientNew.Past_FY_Rates_amount__c = oppClientOld.Past_FY_Rates_amount__c;
        oppClientNew.Past_FY_Securities_Services_amount__c = oppClientOld.Past_FY_Securities_Services_amount__c;
        oppClientNew.Past_FY_Str_Trade_Finance_amount__c = oppClientOld.Past_FY_Str_Trade_Finance_amount__c;
        oppClientNew.Past_FY_Structured_Finance_amount__c = oppClientOld.Past_FY_Structured_Finance_amount__c;
        oppClientNew.Past_FY_Working_Capital_amount__c = oppClientOld.Past_FY_Working_Capital_amount__c;
        oppClientNew.Relationship_Status_desc__c = oppClientOld.Relationship_Status_desc__c;
        oppClientNew.Revenues_Current_Year_number__c = oppClientOld.Revenues_Current_Year_number__c;
        oppClientNew.Revenues_Last_Year_number__c = oppClientOld.Revenues_Last_Year_number__c;
        oppClientNew.Revenues_Next_Year_1_number__c = oppClientOld.Revenues_Next_Year_1_number__c;
        oppClientNew.Revenues_Next_Year_2_number__c = oppClientOld.Revenues_Next_Year_2_number__c;
        oppClientNew.Revenues_Next_Year_number__c = oppClientOld.Revenues_Next_Year_number__c;
        oppClientNew.DMT_cca__c = oppClientOld.DMT_cca__c;
        oppClientNew.DMT_cta__c = oppClientOld.DMT_cta__c;
        oppClientNew.DMT_positioning__c = oppClientOld.DMT_positioning__c;
        oppClientNew.DMT_tri__c = oppClientOld.DMT_tri__c;
        oppClientNew.DMT_tri_Engagement_Plan__c = oppClientOld.DMT_tri_Engagement_Plan__c;

        update oppClientNew;
    }


    @AuraEnabled
    public static void updateMainHolderOnAssociation(Id opportunityId, String alphaCode) {

        if(opportunityId == null){
            throw new AuraHandledException('OpportunityId is null');
        }

        Custom_Association_Opportunity__c association = [
            SELECT Id, g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            LIMIT 1
        ];

        if(association != null){
            association.g_customer_id__c = alphaCode;
            update association;
        }

    }

    @AuraEnabled
    public static void saveCustomAssociation(Id lineId, String mainHolderAlphaCode, String currencyLine, String groupId, Id groupSfId, String externallineId) {

        if (lineId == null) {
            throw new AuraHandledException('LineId is null');
        }

        List<Custom_Association__c> associationList = queryLineAssociation(lineId); // CIBGLOBALD-4811

        // CIBGLOBALD-4811 - the association record comes from prepareAssociation, shared with buildSelectionSave
        Custom_Association__c association = prepareAssociation(
            associationList.isEmpty() ? null : associationList[0], lineId, mainHolderAlphaCode, currencyLine, groupId, groupSfId, externallineId
        );
        if (associationList.isEmpty()) {
            insert association;

            DMT_Line__c line = new DMT_Line__c();
            line.Id = lineId;
            line.Custom_Association__c = association.Id;
            update line;
        } else {
            update association;
        }
    }


    @AuraEnabled
    public static void saveLineClients(List<Object> selectedClients, Id lineId) {

        if (lineId == null) {
            throw new AuraHandledException('LineId is null');
        }

        // 1. Obtener o crear Custom_Association__c para la línea
        List<Custom_Association__c> associationList = queryLineAssociation(lineId); // CIBGLOBALD-4811

        Custom_Association__c association;
        if (associationList.isEmpty()) {
            association = new Custom_Association__c();
            association.DMT_Line__c = lineId;
            insert association;
        } else {
            association = associationList[0];
        }

        // CIBGLOBALD-4811 - the rows to insert and delete come from buildClientInserts / buildClientDeletes, shared
        // with buildSelectionSave. Enhancement fix to existing process: with no association before this call the
        // new clients read the group code from the record just created (before, associationList[0] failed).
        List<Custom_Association_Client__c> existingRecords = queryAssociationClients(association.Id);
        List<Custom_Association_Client__c> toInsert = buildClientInserts(association, selectedClients, existingRecords);
        List<Custom_Association_Client__c> toDelete = buildClientDeletes(existingRecords, incomingAlphaCodes(selectedClients));

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    @AuraEnabled
    public static void saveLineClientFields(List<Object> selectedClients, Id lineId) {
        if (lineId == null || selectedClients == null) return;

        List<Custom_Association__c> associationList = [
            SELECT Id FROM Custom_Association__c WHERE DMT_Line__c = :lineId LIMIT 1
        ];
        if (associationList.isEmpty()) return;

        Set<String> alphaCodes = new Set<String>();
        Map<String, Map<String, Object>> rowsByAlpha = new Map<String, Map<String, Object>>();

        for (Object obj : selectedClients) {
            Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
            String alphaCode = (String) row.get('customerId');
            if (String.isNotBlank(alphaCode)) {
                alphaCodes.add(alphaCode);
                rowsByAlpha.put(alphaCode, row);
            }
        }

        List<Custom_Association_Client__c> toUpdate = [
            SELECT Id, Alpha_Code_Client__c, DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :associationList[0].Id
            AND Alpha_Code_Client__c IN :alphaCodes
        ];

        for (Custom_Association_Client__c client : toUpdate) {
            applyClientFields(client, rowsByAlpha.get(client.Alpha_Code_Client__c)); // CIBGLOBALD-4811
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // CIBGLOBALD-4811 - the Line's association, read by the saves and by buildSelectionSave.
    private static List<Custom_Association__c> queryLineAssociation(Id lineId) {
        return [
            SELECT Id, g_customer_id__c, Group__c, gf_customer_group_id__c
            FROM Custom_Association__c
            WHERE DMT_Line__c = :lineId
            LIMIT 1
        ];
    }

    // CIBGLOBALD-4811 - the association's client rows with the fields the saves write.
    private static List<Custom_Association_Client__c> queryAssociationClients(Id associationId) {
        if (associationId == null) {
            return new List<Custom_Association_Client__c>();
        }
        return [
            SELECT Id, Alpha_Code_Client__c, DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :associationId
        ];
    }

    // CIBGLOBALD-4811 - the association saveCustomAssociation writes: a new one with the line and group data, or the
    // existing one with the new main holder.
    private static Custom_Association__c prepareAssociation(
        Custom_Association__c existing, Id lineId, String mainHolderAlphaCode, String currencyLine, String groupId, Id groupSfId, String externallineId
    ) {
        if (existing == null) {
            Custom_Association__c association = new Custom_Association__c();
            association.DMT_Line__c = lineId;
            association.CurrencyIsoCode = currencyLine;
            association.g_group_Id__c   = groupId;
            association.Group__c = groupSfId;
            association.gf_customer_group_Id__c = externallineId;
            association.g_customer_id__c = mainHolderAlphaCode;
            return association;
        }
        existing.g_customer_id__c = mainHolderAlphaCode;
        return existing;
    }

    // CIBGLOBALD-4811 - the alpha codes of the selected clients.
    private static Set<String> incomingAlphaCodes(List<Object> selectedClients) {
        Set<String> alphaCodes = new Set<String>();
        if (selectedClients != null) {
            for (Object obj : selectedClients) {
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) row.get('customerId');
                if (String.isNotBlank(alphaCode)) {
                    alphaCodes.add(alphaCode);
                }
            }
        }
        return alphaCodes;
    }

    // CIBGLOBALD-4811 - a client row for each selected client the association does not have yet (saveLineClients).
    private static List<Custom_Association_Client__c> buildClientInserts(
        Custom_Association__c association, List<Object> selectedClients, List<Custom_Association_Client__c> existingRecords
    ) {
        Set<String> existingAlphaCodes = new Set<String>();
        for (Custom_Association_Client__c rec : existingRecords) {
            if (rec.Alpha_Code_Client__c != null) {
                existingAlphaCodes.add(rec.Alpha_Code_Client__c);
            }
        }
        List<Custom_Association_Client__c> toInsert = new List<Custom_Association_Client__c>();
        if (selectedClients != null) {
            for (Object obj : selectedClients) {
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) row.get('customerId');

                if (String.isNotBlank(alphaCode) && !existingAlphaCodes.contains(alphaCode)) {
                    Custom_Association_Client__c client = new Custom_Association_Client__c();
                    client.Custom_Association__c = association.Id;
                    client.Alpha_Code_Client__c = (String) row.get('customerId');
                    client.g_customer_id__c = (String) row.get('customerId');
                    client.gf_customer_group_Id__c = (String) association.gf_customer_group_Id__c;
                    client.DMT_ClientRating__c = (String) row.get('updSmsclInternalRatgType');
                    client.Name = (String) row.get('customerName');
                    client.g_entific_Id__c = (String) row.get('countryIfoId');
                    String dateStr = (String) row.get('currentRatingToolDate');
                    client.DMT_Client_Rating_Date__c = String.isNotBlank(dateStr) ? Date.valueOf(dateStr.substring(0, 10)) : null;
                    client.DMT_ClientStarCode__c = (String) row.get('customerCounterpartiesCodesDesc');
                    client.DMT_ClientContracts__c = (String) row.get('operationMitigantDesc');
                    client.DMT_Term__c = (String) row.get('term');
                    toInsert.add(client);
                }
            }
        }
        return toInsert;
    }

    // CIBGLOBALD-4811 - the stored client rows no longer selected (saveLineClients).
    private static List<Custom_Association_Client__c> buildClientDeletes(List<Custom_Association_Client__c> existingRecords, Set<String> incomingAlphaCodes) {
        List<Custom_Association_Client__c> toDelete = new List<Custom_Association_Client__c>();
        for (Custom_Association_Client__c existing : existingRecords) {
            if (existing.Alpha_Code_Client__c == null || !incomingAlphaCodes.contains(existing.Alpha_Code_Client__c)) {
                toDelete.add(existing);
            }
        }
        return toDelete;
    }

    // CIBGLOBALD-4811 - the term and amounts of a selected client row (saveLineClientFields).
    private static void applyClientFields(Custom_Association_Client__c client, Map<String, Object> row) {
        client.DMT_Term__c = (String) row.get('term');

        Object amountObj = row.get('amount');
        Object amountFDObj = row.get('amountFD');
        Object amountDVPObj = row.get('amountDVP');

        String amount =
            amountObj == null ? null : String.valueOf(amountObj).trim();

        String amountFD =
            amountFDObj == null ? null : String.valueOf(amountFDObj).trim();

        String amountDVP =
            amountDVPObj == null ? null : String.valueOf(amountDVPObj).trim();

        client.DMT_Amount__c =
            String.isNotBlank(amount) && amount != 'null'
            ? Decimal.valueOf(amount)
            : null;

        client.DMT_FDAmount__c =
            String.isNotBlank(amountFD) && amountFD != 'null'
            ? Decimal.valueOf(amountFD)
            : null;

        client.DMT_DVPAmount__c =
            String.isNotBlank(amountDVP) && amountDVP != 'null'
            ? Decimal.valueOf(amountDVP)
            : null;
    }

    /**
     * @description CIBGLOBALD-4811 - Everything a Line client selection save writes (saveCustomAssociation,
     * saveLineClients and saveLineClientFields in that order, as DMT_SelectClientsInLineService.saveSelection runs
     * them), built without DML: the association, the client rows to delete, the new client rows (with term and
     * amounts) and the stored rows still selected with their new term and amounts. The association and its
     * clients are read once (the three methods read the association three times and the clients twice).
     */
    public static SelectionSave buildSelectionSave(
        Id lineId, String mainHolderAlphaCode, String currencyLine, String groupId, Id groupSfId, String externallineId, List<Object> selectedRows
    ) {
        if (lineId == null) {
            throw new AuraHandledException('LineId is null');
        }
        List<Custom_Association__c> associationList = queryLineAssociation(lineId);
        SelectionSave selectionSave = new SelectionSave();
        selectionSave.lineId = lineId;
        selectionSave.isNewAssociation = associationList.isEmpty();
        selectionSave.association = prepareAssociation(
            associationList.isEmpty() ? null : associationList[0], lineId, mainHolderAlphaCode, currencyLine, groupId, groupSfId, externallineId
        );

        List<Custom_Association_Client__c> existingRecords = queryAssociationClients(selectionSave.association.Id);
        Set<String> alphaCodes = incomingAlphaCodes(selectedRows);
        selectionSave.clientsToInsert = buildClientInserts(selectionSave.association, selectedRows, existingRecords);
        selectionSave.clientsToDelete = buildClientDeletes(existingRecords, alphaCodes);

        if (selectedRows != null) {
            Map<String, Map<String, Object>> rowsByAlpha = new Map<String, Map<String, Object>>();
            for (Object obj : selectedRows) {
                Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) row.get('customerId');
                if (String.isNotBlank(alphaCode)) {
                    rowsByAlpha.put(alphaCode, row);
                }
            }
            for (Custom_Association_Client__c client : selectionSave.clientsToInsert) {
                applyClientFields(client, rowsByAlpha.get(client.Alpha_Code_Client__c));
            }
            for (Custom_Association_Client__c existing : existingRecords) {
                if (existing.Alpha_Code_Client__c != null && rowsByAlpha.containsKey(existing.Alpha_Code_Client__c)) {
                    Custom_Association_Client__c client = new Custom_Association_Client__c(Id = existing.Id, Alpha_Code_Client__c = existing.Alpha_Code_Client__c);
                    applyClientFields(client, rowsByAlpha.get(existing.Alpha_Code_Client__c));
                    selectionSave.clientsToUpdate.add(client);
                }
            }
        }
        return selectionSave;
    }

    // CIBGLOBALD-4811 - writes a buildSelectionSave result in the order of the three save methods: association (and the
    // Line link when new), deleted clients, new clients, then the term and amounts of the clients kept.
    public static void applySelectionSave(SelectionSave selectionSave) {
        if (selectionSave.isNewAssociation) {
            insert selectionSave.association;
            update new DMT_Line__c(Id = selectionSave.lineId, Custom_Association__c = selectionSave.association.Id);
        } else {
            update selectionSave.association;
        }
        if (!selectionSave.clientsToDelete.isEmpty()) {
            delete selectionSave.clientsToDelete;
        }
        if (!selectionSave.clientsToInsert.isEmpty()) {
            for (Custom_Association_Client__c client : selectionSave.clientsToInsert) {
                client.Custom_Association__c = selectionSave.association.Id;
            }
            insert selectionSave.clientsToInsert;
        }
        if (!selectionSave.clientsToUpdate.isEmpty()) {
            update selectionSave.clientsToUpdate;
        }
    }

    // CIBGLOBALD-4811 - the records a Line client selection save writes (buildSelectionSave).
    public class SelectionSave {
        public Id lineId;
        public Boolean isNewAssociation = false;
        public Custom_Association__c association;
        public List<Custom_Association_Client__c> clientsToDelete = new List<Custom_Association_Client__c>();
        public List<Custom_Association_Client__c> clientsToInsert = new List<Custom_Association_Client__c>();
        public List<Custom_Association_Client__c> clientsToUpdate = new List<Custom_Association_Client__c>();

        // Every row in the DMT_ApprovalChangeStep_Handler.previewUnsavedChanges format: a row without Id is new.
        public List<Map<String, Object>> toUnsavedRows() {
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            List<SObject> written = new List<SObject>{ association };
            written.addAll((List<SObject>) clientsToInsert);
            written.addAll((List<SObject>) clientsToUpdate);
            for (SObject record : written) {
                Map<String, Object> values = new Map<String, Object>(record.getPopulatedFieldsAsMap());
                values.remove('Id');
                rows.add(new Map<String, Object>{
                    'objectApiName' => String.valueOf(record.getSObjectType()),
                    'rowId' => (String) record.Id,
                    'values' => values
                });
            }
            for (Custom_Association_Client__c record : clientsToDelete) {
                rows.add(new Map<String, Object>{ 'objectApiName' => 'Custom_Association_Client__c', 'rowId' => (String) record.Id, 'deleted' => true });
            }
            return rows;
        }
    }
}
