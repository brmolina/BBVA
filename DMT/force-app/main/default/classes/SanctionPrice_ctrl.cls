public with sharing class SanctionPrice_ctrl {
	static Map<String,Object> mapReturn = new Map<String,Object>();
	static String genericError;
	@AuraEnabled
	public static Map<String,Object> getInfoWithoutDefaultValues(String recordId){ 
		List<OpportunityLineItem_Local__c> lstOpp = [SELECT  Id,
									Local_Client_id__c,
									Local_Client_id__r.segment_desc__c,
									product_price_approval_method__c,
									product_price_approval_indicator__c,
									productCode__c,
									opportunity_product__c
									FROM OpportunityLineItem_Local__c
									WHERE Id = :recordId];
		try{
			//If opportunity has opportunityLineItems
			if(lstOpp.size() != null){
				mapReturn.put('IdOppLineItem',lstOpp[0].id);
				mapReturn.put('approvalMethod',lstOpp[0].product_price_approval_method__c);
				mapReturn.put('hasOLI',true);
				mapReturn.put('priceIndicator',lstOpp[0].product_price_approval_indicator__c);
				mapReturn.put('ProductCode',lstOpp[0].productCode__c);
				mapReturn.put('Product',lstOpp[0].opportunity_product__c);
				List<OpportunityLineItem_Local__c> validacion = [SELECT cpliq_Cuenta_vinculada__c FROM OpportunityLineItem_Local__c WHERE id = :recordId];
				if(validacion[0].cpliq_Cuenta_vinculada__c != null){
					mapReturn.put('isOk',true);
                }else{
					mapReturn.put('isOk',false);
				}
			//If opportunity hasn't opportunityLineItems
			}else{
				mapReturn.put('hasOLI',false);
			}
		}catch(Exception e){
			genericError = e.getMessage();
		}
		mapReturn.put('genericError',genericError);
		return mapReturn; 
 	}
}