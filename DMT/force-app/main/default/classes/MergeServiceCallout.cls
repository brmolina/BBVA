/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-31-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:AvoidLiteralsInIfCondition')
public without sharing class MergeServiceCallout {
  
  @InvocableMethod(label='MergeServiceCallout' description='Process to Call Services to creditlense and oracle' callout=true)
  public static void serviceCallout(List<WrapperMerge> mgList) {
    system.debug('** Entrada especial -> ' + mgList[0].idProspect);
    final List<Account> prospect = new List<Account>([SELECT Id, Name, gf_customer_prospect_id__c FROM Account WHERE Id = :mgList[0].idProspect]);
    String prospectId = prospect.get(0).gf_customer_prospect_id__c;
          String origin = 'ALPHA';
          String legalName = mgList[0].lClientName;
          String businessId = mgList[0].lClientAlpha;
          String jsonInputTemplate = '{"origin": "' + origin + '", "legalName": "' + legalName + '", "businessId": "' + businessId + '"}';
          Map<String, Object> request = new Map<String, Object>();
          request.put('prospectId', prospectId);
          request.put('jsonInputTemplate', jsonInputTemplate);
          String requestStr = JSON.serialize(request);
          if(!Test.isRunningTest()){
            HttpResponse response = iaso.GBL_Integration_GenericService.invoke('DES_CreditlensPropose', requestStr);
            system.debug(response);
            System.debug(response.getStatusCode());
            System.debug(response.getBody());
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