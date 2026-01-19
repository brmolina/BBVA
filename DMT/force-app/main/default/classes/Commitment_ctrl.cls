public with sharing class Commitment_ctrl {
	@AuraEnabled
	public static Map<String,Object> getInfoTable(String recordId){
		Map<String,Object> mapReturn = new Map<String,Object>();
		List<Commit_Inter_Garant__c> lstCommitments = [SELECT Id,
														convertCurrency(opp_solution_commitment_amount__c) ComAmount,
														opp_soln_comt_expiry_days_number__c,
														opp_soln_comt_stay_days_number__c,
														opp_solution_comt_product_name__c,
														CurrencyIsoCode
														FROM Commit_Inter_Garant__c
														WHERE Opportunity_Product_Local_id__c = :recordId];
        
		mapReturn.put('lstCommitments', lstCommitments);
		Set<String> setApiName = new Set<String>();
		setApiName.add('opp_solution_commitment_amount__c');
		setApiName.add('opp_soln_comt_expiry_days_number__c');
		setApiName.add('opp_soln_comt_stay_days_number__c');
		setApiName.add('opp_solution_comt_product_name__c');
		setApiName.add('CurrencyIsoCode');
		mapReturn.put('schemaSetup', FieldForm_ctrl.getInfoSchema(setApiName, 'Commit_Inter_Garant__c'));
		return mapReturn; 
	}
}