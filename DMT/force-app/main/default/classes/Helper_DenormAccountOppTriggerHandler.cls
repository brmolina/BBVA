/**
* @author Global Desktop
* @description Auxiliar para comprobar las condiciones del if
*/
public with sharing class Helper_DenormAccountOppTriggerHandler {
		
	/**
	* @author Global Desktop
	* @escription Campo para instanciar la clase
	*/
	private static Helper_DenormAccountOppTriggerHandler instance;
	
  /*
  * @author Global Desktop
  * @description Map to store Expected revenues
  */
  public static Set<Id> PROCESSED = new Set<Id>();

	/**
	* @author Global Desktop
	* @escription Constructor
	*/
	private Helper_DenormAccountOppTriggerHandler() {
		
	}
	

    /**
	* @author Global Desktop
	* @escription Singleton Pattern
	*/
    public static Helper_DenormAccountOppTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
        	instance = new Helper_DenormAccountOppTriggerHandler();
        }
        return instance;
    }
	
	/**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
	public static Boolean helperFirstCheck(Map<Id,Account> relatedAccountMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
        Boolean isValid;
        isValid = false;

        if(triggerOldMap.get(iOpp.Id).success_probability_per__c != null
                            && relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c != null
                            && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Draft
                            && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Won
                            && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperFirstCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperSecondCheck(Map<Id,Account> relatedAccountMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
        Boolean isValid;
        isValid = false;

        if((relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c == null
                                        || relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c == 0)
                                    && (iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Won
                                        || iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Lose)
                                    && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Won
                                    && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperSecondCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperThirdCheck(Map<Id,Account> relatedAccountMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
        Boolean isValid;
        isValid = false;
        if(relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_number__c != null
                            && (iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Won
                                || iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Lose)
                            && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Won
                            && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Lose) {
        isValid = true;
        }
    System.debug(' ++ helperThirdCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperFourthCheck(Map<Id,Account> relatedAccountMap, Map<Id,Opportunity> relatedOppMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp) {
        Boolean isValid;
        isValid = false;
        if(relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_number__c == null
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Draft
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Won
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperFourthCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperFiveCheck(Map<Id,Opportunity> relatedOppMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp) {
        Boolean isValid;
        isValid = false;
        if(relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Draft
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Won
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperFiveCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperSixCheck(Map<Id,Account> relatedAccountMap,Map<Id,Opportunity> relatedOppMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp) {
        Boolean isValid;
        isValid = false;
        if(relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c == null
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Draft
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Won
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperSixCheck -> ' + isValid);
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description Auxiliar para comprobar las condiciones del if
	*/
    public static Boolean helperSevenCheck(Map<Id,Opportunity> relatedOppMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp) {
        Boolean isValid;
        isValid = false;
        if(relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Draft
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Won
                    && relatedOppMap.get(iOpp.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Lose) {
            isValid = true;
        }
    System.debug(' ++ helperSevenCheck -> ' + isValid);
    return isValid;
  }

  /**
   * @author Global Desktop
   * @description Auxiliar para comprobar las condiciones del if
   */
  public static Boolean helperEightCheck(Map<Id,Account> relatedAccountMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
    Boolean isValid;
    isValid = false;

    if(triggerOldMap.get(iOpp.Id).success_probability_per__c != null
       && relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c == null
       && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Draft
       && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Won
       && iOpp.DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Lose) {
      isValid = true;
    }
    System.debug(' ++ helperEightCheck -> ' + isValid);
        return isValid;
    }

  /**
   * @author Global Desktop
   * @description Auxiliar para comprobar las condiciones del if
   */
  public static Boolean helperNineCheck(Map<Id,Account> relatedAccountMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
    Boolean isValid;
    isValid = false;
    if(relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c != null
       && (iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Won
           || iOpp.DES_Opportunity_Stage_Rollup__c == Label.DES_Closed_Lose)
       && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Won
       && triggerOldMap.get(iOpp.Id).DES_Opportunity_Stage_Rollup__c != Label.DES_Closed_Lose) {
      isValid = true;
    }
    System.debug(' ++ helperNineCheck -> ' + isValid);
    return isValid;
  }
}