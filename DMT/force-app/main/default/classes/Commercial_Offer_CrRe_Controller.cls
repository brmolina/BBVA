/*
* Clase controlador para el componente Commercial_Offer_Cr_re
* @Author: Global Desktop
*/
public with sharing class Commercial_Offer_CrRe_Controller {

    /**
	* @author Global Desktop
	* @description SINGLETON PATTERN
	*/
  	private static Commercial_Offer_CrRe_Controller instance;

  	/**
   	* @author Global Desktop
   	* @description getInstance
   	*/
  	public static Commercial_Offer_CrRe_Controller getInstance() { //NOSONAR
    	if (instance == null) {
      		instance = new Commercial_Offer_CrRe_Controller();
    	}
    	return instance;
  	}

    /*
    * Met0d0 para pasar sonar
    */
    private Commercial_Offer_CrRe_Controller() {}

  /*
  * Met0do para obtener el Cliente automaticamente cuando la quickaction es lanzada desde cliente.
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static Account getinitAcount (String idAccs) {

    return [Select id, Name from Account where id = :idAccs LIMIT 1];

  }

  /*
  * Met0do para comprobar si se cumplen las condiciones.
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static boolean checkAccountConditions (Id AccountId) {
    SObjectType t = AccountId.getSObjectType();
    if(AccountId.getSObjectType() == Opportunity.sObjectType){
      Opportunity opp = [Select AccountId from Opportunity where ID = :AccountId limit 1];
      Id accId = opp.AccountId;
      Account accOpp = [Select DES_Client_Type__c , gf_cust_orig_prospect_ind_type__c, gf_prtcpt_act_status_ind_type__c from Account where ID = :accId];
      if(accOpp.DES_Client_Type__c == 'Counterparty' || accOpp.gf_prtcpt_act_status_ind_type__c == true || accOpp.gf_cust_orig_prospect_ind_type__c == true){
        return true;
      } else {
      return false;
      }
    }else{
    Account acc = [Select DES_Client_Type__c , gf_cust_orig_prospect_ind_type__c, gf_prtcpt_act_status_ind_type__c from Account where ID = :AccountId];
    
    if(acc.DES_Client_Type__c == 'Counterparty' || acc.gf_prtcpt_act_status_ind_type__c == true || acc.gf_cust_orig_prospect_ind_type__c == true){
      return true;
    } else {
    return false;
    }
  }

  }

  /*
  * Met0do para comprobar los permisos
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static Boolean gtPermissions() {
    return Schema.SObjectType.coff__Commercial_Offer__c.isCreateable();
  }


  /*
  * Met0do para obtener el Cliente y la Opp automaticamente cuando la quickAction es lanzada desde opp.
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static List<sObject> getinitOpp (String idOpp) {

    List<sObject> listToReturn;
    listToReturn = new List<sObject>();

    final Opportunity currentOpp = [Select id, Name, AccountId,StageName from Opportunity where id = :idOpp LIMIT 1];
    final Account currentAcc = [Select id, Name from Account where id = :currentOpp.AccountId LIMIT 1];

    Opportunity oppReturn;
    oppReturn = new Opportunity();
    oppReturn.Id = currentOpp.Id;
    oppReturn.Name = currentOpp.Name;
    oppReturn.StageName = currentOpp.StageName;

    listToReturn.add(oppReturn);
    listToReturn.add(currentAcc);

    return listToReturn;

  }

  /*
  * Met0do para la creación de Oferta comercial.
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static coff__Commercial_Offer__c saveCommOff (coff__Commercial_Offer__c apexCommOff, String clientCO, String oppCO) {

    apexCommOff.coff__participant_id__c = clientCO;

    try {
      insert apexCommOff;
    } catch(DmlException e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }

    if(oppCO != null) {
      Opportunity oppToUpdate;
      oppToUpdate = new Opportunity();
      oppToUpdate = [Select Id, coff__gf_commercial_offer_id__c, gf_comm_offer_moppy_ind_type__c from Opportunity where id = :oppCO LIMIT 1];
      oppToUpdate.coff__gf_commercial_offer_id__c = apexCommOff.Id;
      oppToUpdate.gf_comm_offer_moppy_ind_type__c = true;
      try {
        update oppToUpdate;
      } catch(DmlException e) {
        System.debug('The following exception has occurred: ' + e.getMessage());
      }
    }

    return apexCommOff;

  }

  /*
  * Met0do para relacionar la oportunidad a la oferta comercial
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static void relateCo (String commOffrId, String currentOpp) {
    //Verificamos si la oferta comercial tiene alguna oportunidad.
    final List<Opportunity> checkAnchor = [Select Id from Opportunity where coff__gf_commercial_offer_id__c = :commOffrId];
    Opportunity oppToUpdate;
    oppToUpdate = new Opportunity();

    oppToUpdate = [Select Id, coff__gf_commercial_offer_id__c, gf_comm_offer_moppy_ind_type__c from Opportunity where Id = :currentOpp];

    // Si la oferta comercial no tiene ninguna oportunidad relacionada, la que se relaciona se marca como ancla.
    if(checkAnchor.isEmpty()) {
      oppToUpdate.gf_comm_offer_moppy_ind_type__c = true;
    }

    oppToUpdate.coff__gf_commercial_offer_id__c = commOffrId;
    try {
      update oppToUpdate;
    } catch(DmlException e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }


  }


  /*
  * Met0do para rellenar campos de la picklist RFP Status
  * @Author: Global Desktop
  */
  @AuraEnabled
  public static List<String> pickListValuesIn() { //NOSONAR
      List<String> picklist;
      picklist = new List<String>();
      final Schema.DescribeFieldResult fieldResult = coff__Commercial_Offer__c.gf_rfp_status_name__c.getDescribe();
      final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for( Schema.PicklistEntry pickListVal : ple) {
          picklist.add(pickListVal.getLabel());
      }
      return picklist;
  }
}