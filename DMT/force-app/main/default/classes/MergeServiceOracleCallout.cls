/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-31-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:AvoidLiteralsInIfCondition')
public without sharing  class MergeServiceOracleCallout {
	
    @InvocableMethod(label='MergeServiceOracleCallout' description='Process to Call Services to oracle' callout=true)
    public static void serviceCallout(List<WrapperMerge> mgList) {
        final List<Account> prospect = new List<Account>([
          SELECT Id, Name, DES_ID_Fiscal__c, participant_id__c, customer_stock_exchange_name__c, gf_customer_prospect_id__c,
          participant_status_type__c, gf_stock_exchange_company_id__c, gf_cust_orig_prospect_ind_type__c, DES_Prospect_status__c
          FROM Account WHERE Id = :mgList[0].idProspect
        ]); 
        
        //SEGUNDO SERVICIO ORACLE
          String prospectId2 = prospect.get(0).gf_customer_prospect_id__c;
          String participantId = mgList[0].lClientAlpha;
          Map<String, Object> request2 = new Map<String, Object>();
          request2.put('prospectId', prospectId2);
          request2.put('participantId', participantId);
          String requestStr2 = JSON.serialize(request2);
          if(!Test.isRunningTest()){
            HttpResponse response2 = iaso.GBL_Integration_GenericService.invoke('DES_OraclePropose', requestStr2);
            system.debug(response2);
            System.debug(response2.getStatusCode());
            System.debug(response2.getBody());
          }
    }
    
    /*
  * Entrada del method invocable addMemberGroup
  */
  public class WrapperMerge {
    /*
    * Id del prospect
    */
    @InvocableVariable(label='Id del prospect' required=false)
    public String idProspect; //NOSONAR

    /**
    * Id del cliente al que se va a mergear
    */
    @InvocableVariable(label='Id del cliente' required=false)
    public String idClient; //NOSONAR

    /**
    * Id del localClient
    */
    @InvocableVariable(label='Id del cliente local' required=false)
    public String idLocalClient; //NOSONAR

    /**
    * Lista de Arces
    */
    @InvocableVariable(label='Lista de Arce' required=false)
    public List<arce__Account_has_Analysis__c> arceList; //NOSONAR

    /**
    * Lista de Arces
    */
    @InvocableVariable(label='Tiene ARCE' required=false)
    public Boolean hasNoArce; //NOSONAR

    /**
    * Nombre local client
    */
    @InvocableVariable(label='Local Client Name' required=false)
    public String lClientName; //NOSONAR

    /**
    * Nombre local client
    */
    @InvocableVariable(label='Local Client Alpha' required=false)
    public String lClientAlpha; //NOSONAR
  }
}