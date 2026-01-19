/**
*
*
* @author Global Desktop
*/
public without sharing class RiskInformation {
   /**
   *
   *
   * @author Global Desktop
   */
   private RiskInformation() {}
   /**
   *
   *
   * @author Global Desktop
   */
	@AuraEnabled
    public static list<Consumo_de_Linea__c> getRiskAccount(String recordId) {
      try {
         return [SELECT Id from Consumo_de_Linea__c where participant_id__c=:recordId];
      } catch(Exception e) {
			throw new AuraHandledException(Label.DES_Error + e);
		}
    }
    /**
      *
      *
      * @author Global Desktop
      */
    @AuraEnabled
    public static List<AggregateResult> getMaxConsumo(String recordId) {
       try {
         return [SELECT participant_id__c,MAX(settlement_drawn_amount__c)Settlement_Consumption,MAX(repos_drawn_amount__c)Repos_Consumption,
                                           MAX(delivery_vs_pay_drawn_amount__c)DVP_Consumption,MAX(derivatives_drawn_amount__c)Derivatives_Consumption,
                                           MAX(deposits_drawn_amount__c)Deposits_Consumption,MAX(credit_drawn_amount__c)Credit_Consumption from Consumo_de_Linea__c where participant_id__c=:recordId GROUP BY participant_id__c limit 1];
       } catch(Exception e) {
			throw new AuraHandledException(Label.DES_Error + e);
		}
    }
    /**
      *
      *
      * @author Global Desktop
      */
    @AuraEnabled
    public static list<Consumo_de_Linea__c> getRisklimit(String recordId) {
       try {
         return [SELECT credit_prdt_limit_tenor_amount__c, derv_prdt_limit_tenor_amount__c, dpst_prdt_limit_tenor_amount__c, repos_prdt_limit_tenor_amount__c, settl_prdt_limit_tenor_amount__c, dlvry_vs_pay_lim_tenor_amount__c from Consumo_de_Linea__c where participant_id__c=:recordId limit 1];
       } catch(Exception e) {
			throw new AuraHandledException(Label.DES_Error + e);
		}
    }
}