public with sharing class Object_Controller {
	@AuraEnabled
	public static Id getOportunityLineItemID(String Filtro) {
		ID OpLiItem =
			[SELECT Id FROM OpportunityLineItem_Local__c
			where Opportunityid__c =:Filtro][0].Id;
		return OpLiItem;
	}
	/*@AuraEnabled
	public static String getOportunityModality(String Filtro) {
		String Modality = [SELECT Risk_modality_type__c FROM OpportunityLineItem_Local__c
			WHERE Id =:Filtro LIMIT 1].Risk_modality_type__c;
		return Modality;
	}*/
	@AuraEnabled
	public static String getOportunidadSytem(String Filtro) {
		String OpLiItem =
			[SELECT Id, Product2Local__r.Type_of_quote__c  FROM OpportunityLineItem_Local__c
			where Opportunityid__c =:Filtro][0].Product2Local__r.Type_of_quote__c;
		return OpLiItem;
	}
	@AuraEnabled
	public static void  setSanction(String Idopp){
		OpportunityLineItem_Local__c op  = new OpportunityLineItem_Local__c();
		Map<string,string> MapStatus = getMapOppStatus();
		Task t = [SELECT Id,Subject,Status FROM Task WHERE WhatId = : idopp ORDER BY CreatedDate DESC];
		op = [SELECT StageName__c,opportunity_status_type__c FROM OpportunityLineItem_Local__c WHERE ID =:Idopp];
		op.opportunity_status_type__c='10';
		String[] valStatus = t.Subject.split('##');
		String filter = '%'+valStatus[0]+'%';
		Integer totalTrace;
		update op;
		AggregateResult[] countTrace  = [SELECT Count(Id) total FROM dwp_cvad__Action_Audit__c];
		new OpportunityTraceability_cls().addOpportunityTraceability(valStatus[1],'Código SIO:' +valStatus[0],'Opportunity',op.Id,'Aprove',('AT-'+totalTrace),UserInfo.getUserId(),'embedded',1,true);
	}
	private static  Map<string,string> getMapOppStatus(){
		Map<string,string> MapStatus = new Map<string,string>();
		Schema.DescribeFieldResult fieldResult = Opportunity_Local__c.opportunity_status_type__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry f : ple)
		{
			MapStatus.put(f.getLabel(), f.getValue());
		}
		return MapStatus;
	}
	@AuraEnabled
	public static List<String>  getVflasClient(String Idopp, string tipex){
		List<String> ret= new List<String>();
		String Tip= tipex=='Recursos gestionados' ? '02':'01';
		AggregateResult[] scop= [SELECT FORMAT(SUM(average_balance_amount__c)) average_balance_amount__c,
								FORMAT(SUM(current_balance_var_month_amount__c)) current_balance_var_month_amount__c,
								FORMAT(SUM(current_balance_var_year_amount__c)) current_balance_var_year_amount__c
								FROM Account_BBVA_Information__c WHERE  type__c =: Tip AND
								product_group_classification_id__c != '' AND product_desc__c != ''
								AND local_client_id__c =: Idopp AND is_last_date__c = true AND
								product_group_classification_id__c=:tipex
								Group By product_group_classification_id__c limit 1];
		List<Account_Banking_System_Debt__c> banking = new List<Account_Banking_System_Debt__c>();
		banking= [select id, debt_quote_amount__c from Account_Banking_System_Debt__c
					where  product_group_classification_id__c!='' and
					entity_name__c LIKE '%BBVA%' AND product_desc__c='' AND is_last_date__c = true AND
					entity_name__c != '' and
					local_client_id__c=: Idopp and product_group_classification_id__c=:tipex limit 1];
		for (AggregateResult ar :scop){
			ret.add(String.valueOf(ar.get('average_balance_amount__c')));
			ret.add(banking.isEmpty()? 'N/A':String.valueOf(banking[0].debt_quote_amount__c)+'%');
			ret.add(String.valueOf(ar.get('current_balance_var_month_amount__c')));
			ret.add(String.valueOf(ar.get('current_balance_var_year_amount__c')));
		}
		if(ret.isEmpty()){ 
			ret.add('0');
			ret.add(banking.isEmpty()? 'N/A':String.valueOf(banking[0].debt_quote_amount__c)+'%');
			ret.add('0');ret.add('0');
		}
		return ret;
	}
	@AuraEnabled
	public static OpportunityLineItem_Local__c getProduct2(String recordId){
		OpportunityLineItem_Local__c temp = new OpportunityLineItem_Local__c();
		if(!String.isEmpty(recordId)){
			temp = [select id,product_risk_approval_indicator__c,product_price_approval_indicator__c from OpportunityLineItem_Local__c where id=: recordId limit 1];
		}
		return temp;
	}
}