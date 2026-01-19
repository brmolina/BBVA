public without sharing class Product_cls {
	@AuraEnabled public static List<OpportunityLineItem_Local__c> getIdProductByOpportunity(String IdOpportunity){
		List<OpportunityLineItem_Local__c> row= [SELECT  product2Id__c  FROM OpportunityLineItem_Local__c Where Id=: IdOpportunity LIMIT 1];
		if(!row.isEmpty())
			return row;
		else
			return row;
	}
	/*Description
	Comments to describe the functionality of this method
	*/
	@AuraEnabled public static List<Commit_Inter_Garant__c> getGuaranteeDataByProduct(String IdOpportunity,String IdProduct){
		List<OpportunityLineItem_Local__c> OLI= [SELECT unique_id__c, CurrencyIsoCode FROM OpportunityLineItem_Local__c WHERE id=: IdOpportunity ];
		List<Commit_Inter_Garant__c> objData= [SELECT Id,guarantee_desc__c, guarantee_modality_type__c, guarantee_status_type__c,guarantee_term_number__c, guarantee_periodicity_type__c,guarantee_id__c,convertCurrency(guaranteed_amount__c)  amount FROM Commit_Inter_Garant__c Where GBL_Opportunity_product__c=: OLI[0].unique_id__c and guaranteed_amount__c  != null ];
		for (Commit_Inter_Garant__c row : objData)
			row.CurrencyIsoCode = OLI[0].CurrencyIsoCode;
		return objData;
	}
	@AuraEnabled public static List<Commit_Inter_Garant__c> getParticipantDataByProduct(String IdOpportunity,String IdProduct){
		List<OpportunityLineItem_Local__c> OLI= [SELECT unique_id__c FROM OpportunityLineItem_Local__c WHERE id=: IdOpportunity ];
		List<Commit_Inter_Garant__c> objData= [SELECT Id,Name__c,toLabel(fiscal_identifier_type__c), toLabel(guarantor_marital_status_type__c), toLabel(participant_type__c),taxpayer_id__c FROM Commit_Inter_Garant__c Where GBL_Opportunity_product__c=: OLI[0].unique_id__c and taxpayer_id__c != null];
		return objData;
	}
}