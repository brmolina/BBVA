public with sharing class DMT_UnderwritingFormController {

    public class LookupOption {
        @AuraEnabled public String value; 
        @AuraEnabled public String label; 
        public LookupOption(String v, String l){
            value = v; label = l;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getUnderwritingData(Id recordId) {
        Boolean isGodMode = FeatureManagement.checkPermission('DMT_Line_God');
        AccessLevel dbMode = isGodMode ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;

        Map<String, Object> result = new Map<String, Object>();

        String oppQuery = 'SELECT Id, Name, underwriting_agreement_type__c, deal_total_amount__c, ' +
            'bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, ' +
            'gf_current_be_sold_mk_amount__c, operation_underwriting_per__c, ' +
            'gf_est_fee_cust_sycr_bp_amount__c, opening_fee_per__c, ' +
            'risk_committee_aprvl_ind_type__c, signing_date__c, ' +
            'gf_mk_curr_rsk_synd_amount__c, gf_prort_sale_ord_sum_amount__c, ' +
            'gf_total_nominal_sold_amount__c, gf_total_sold_ord_stl_amount__c, ' +
            'gf_tl_sold_ord_not_stl_amount__c, underwriting_amount__c, ' +
            'gf_comt_not_settled_amount__c, gf_synd_fnl_primry_allc_amount__c, ' +
            'gf_prort_setl_order_tl_amount__c, risk_effective_date__c, ' +
            'gf_settlement_date__c, gf_oppy_credit_agree_sign_date__c, ' +
            'clan_syndicated_loan_id__c, gf_opportunity_end_year_id__c, DES_Date_Won_Lost__c, ' +
            'gf_oppy_undwr_approval_year_id__c, oppy_undwr_cmtee_approval_date__c, ' +
            'oppy_undwr_cmtee_rspse_type__c, DMT_HasGUMSProduct__c, ' +
            'bbva_participation_per__c, underwriting_fee_amount__c, ' +
            'gf_own_undwr_mk_rsk_fee_amount__c, gf_upfront_undwr_fees_amount__c, ' +
            'gf_tot_sold_order_fees_amount__c, oppy_product_ctrct_comt_date__c, ' +
            'gf_oppy_undwr_cmtee_comnt_desc__c ' +
            'FROM Opportunity WHERE Id = :recordId';

        Opportunity opp = (Opportunity) Database.query(oppQuery, dbMode);
        result.put('opportunity', opp);

        Map<String, List<Map<String, String>>> picklistValues = new Map<String, List<Map<String, String>>>();
        picklistValues.put('underwriting_agreement_type__c', getPicklistOptions('Opportunity', 'underwriting_agreement_type__c'));
        picklistValues.put('risk_committee_aprvl_ind_type__c', getPicklistOptions('Opportunity', 'risk_committee_aprvl_ind_type__c'));
        picklistValues.put('oppy_undwr_cmtee_rspse_type__c', getPicklistOptions('Opportunity', 'oppy_undwr_cmtee_rspse_type__c'));
        result.put('picklistValues', picklistValues);

        String soQuery = 'SELECT Id, gf_loan_br_ctpty_id__c, gf_loan_br_ctpty_id__r.Name, ' +
            'gf_ctpty_sold_order_amount__c, gf_sold_ord_ctpty_setl_amount__c, ' +
            'gf_sold_order_settled_ind_type__c, Currency__c, ' +
            'gf_sold_orders_fees_bps_amount__c, gf_bbva_assur_prtcp_per__c, opportunity_id__c ' +
            'FROM Sold_Order__c WHERE opportunity_id__c = :recordId ORDER BY CreatedDate';

        result.put('soldOrders', Database.query(soQuery, dbMode));
        result.put('soldOrderCurrencyOptions', getPicklistOptions('Sold_Order__c', 'Currency__c'));
        result.put('soldOrderSettledOptions', getPicklistOptions('Sold_Order__c', 'gf_sold_order_settled_ind_type__c'));

        String accQuery = 'SELECT Id, Name FROM Account WHERE Name != null AND DES_Structure_Type__c = \'Subsidiary\' ';
        List<Account> accounts = Database.query(accQuery, dbMode);
        
        List<Map<String, String>> counterpartyOptions = new List<Map<String, String>>();
        for (Account acc : accounts) {
            counterpartyOptions.add(new Map<String, String>{ 'label' => acc.Name, 'value' => acc.Id });
        }
        result.put('soldOrderCounterpartyOptions', counterpartyOptions);

        return result;
    }

    private static List<Map<String, String>> getPicklistOptions(String objectApiName, String fieldApiName) {
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeFieldResult fieldDescribe = sobjectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            options.add(new Map<String, String>{ 'label' => entry.getLabel(), 'value' => entry.getValue() });
        }
        return options;
    }

    @AuraEnabled
    public static void saveUnderwritingData(Id recordId, Map<String, Object> updatedFields, List<Sold_Order__c> soldOrders, List<Id> idsToDelete) {
        Boolean isGodMode = FeatureManagement.checkPermission('DMT_Line_God');
        AccessLevel dbMode = isGodMode ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;

        Set<String> allowedFields = new Set<String>{
            'underwriting_agreement_type__c', 'deal_total_amount__c', 'bbva_prtcp_tranche_amount__c', 'syndicated_loan_drawn_amount__c',
            'operation_underwriting_per__c', 'gf_est_fee_cust_sycr_bp_amount__c', 'opening_fee_per__c', 'risk_committee_aprvl_ind_type__c',
            'signing_date__c', 'underwriting_amount__c', 'gf_synd_fnl_primry_allc_amount__c', 'risk_effective_date__c',
            'gf_settlement_date__c', 'gf_oppy_credit_agree_sign_date__c', 'clan_syndicated_loan_id__c', 'DES_Date_Won_Lost__c',
            'oppy_undwr_cmtee_approval_date__c', 'oppy_undwr_cmtee_rspse_type__c', 'bbva_participation_per__c', 'oppy_product_ctrct_comt_date__c',
            'gf_oppy_undwr_cmtee_comnt_desc__c'
        };

        if (updatedFields != null && !updatedFields.isEmpty()) {
            Opportunity oppToUpdate = new Opportunity(Id = recordId);
            for (String key : updatedFields.keySet()) {
                if (!allowedFields.contains(key)) continue;
                
                Object value = updatedFields.get(key);
                if (value instanceof String && String.valueOf(value).trim() == '') value = null;

                if (value != null && value instanceof String && (key.contains('_date__c') || key == 'DES_Date_Won_Lost__c')) { 
                    try {
                        value = Date.valueOf((String)value);
                    } catch (Exception e) { 
                        DES_Exception_Utils.logException(e,'DMT_UnderwritingFormController', 'saveUnderwritingData', 'DMT', '');
                        throw new AuraHandledException('Invalid date format for field ' + key + ': ' + value);
                    }
                }
                oppToUpdate.put(key, value);
            }

            // Fee Formula Recalculation
            if (updatedFields.containsKey('operation_underwriting_per__c') || updatedFields.containsKey('bbva_prtcp_tranche_amount__c')) {
                Opportunity currentOpp = [SELECT operation_underwriting_per__c, bbva_prtcp_tranche_amount__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
                Decimal opUnderwriting = updatedFields.containsKey('operation_underwriting_per__c') ? Decimal.valueOf(String.valueOf(updatedFields.get('operation_underwriting_per__c'))) : currentOpp.operation_underwriting_per__c;
                Decimal trancheAmount = updatedFields.containsKey('bbva_prtcp_tranche_amount__c') ? Decimal.valueOf(String.valueOf(updatedFields.get('bbva_prtcp_tranche_amount__c'))) : currentOpp.bbva_prtcp_tranche_amount__c;
                oppToUpdate.underwriting_fee_amount__c = (opUnderwriting != null && trancheAmount != null) ? (opUnderwriting / 10000) * trancheAmount : null;
            }
            Database.update(oppToUpdate, dbMode);
        }

        if (idsToDelete != null && !idsToDelete.isEmpty()) {
            Database.delete([SELECT Id FROM Sold_Order__c WHERE Id IN :idsToDelete], dbMode);
        }

        if (soldOrders != null && !soldOrders.isEmpty()) {
            for (Sold_Order__c so : soldOrders) {
                so.opportunity_id__c = recordId;
                if (so.Id != null) {
                    try { Id.valueOf(so.Id); } catch(Exception e) { so.Id = null; }
                }
            }
            Database.upsert(soldOrders, dbMode);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchClientsFromLocal(String searchTerm) {
        String term = (searchTerm == null) ? '' : searchTerm.trim();
        if (term.length() < 2) return new List<LookupOption>();
        term = '%' + String.escapeSingleQuotes(term) + '%';

        List<Local_Client__c> locals = [SELECT Cib_Client__c, Cib_Client__r.Name FROM Local_Client__c WHERE Name LIKE :term ORDER BY Name LIMIT 50];
        Map<Id, String> uniq = new Map<Id, String>();
        for (Local_Client__c lc : locals) {
            if (lc.Cib_Client__c != null) uniq.put(lc.Cib_Client__c, lc.Cib_Client__r.Name);
        }
        List<LookupOption> out = new List<LookupOption>();
        for (Id clientId : uniq.keySet()) {
            out.add(new LookupOption(String.valueOf(clientId), uniq.get(clientId)));
        }
        return out;
    }
}