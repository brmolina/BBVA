/**
* @author Global Desktop
* @description Controlador del componente lightning RelatedAccOppInProgress
*/
public with sharing class RelatedAccOppInProgressController {

    /*SINGLETON PATTERN*/
    private static RelatedAccOppInProgressController instance;

    /*Constructor de la clase*/
    public RelatedAccOppInProgressController() {
    system.debug('Constructor RelatedAccOppInProgressController');
  }

  /*Instancia de la clase*/
  public static RelatedAccOppInProgressController getInstance(){ //NOSONAR
        if (instance == null) {
          instance = new RelatedAccOppInProgressController();
        }
        return instance;
    }

  /*
  * @author Global Desktop
  * @description Recupera las oportunidades relacionadas con la cuenta
  */
    @auraEnabled
    public static String getRelatedOpportunities(String tableSize, String accId) {
      try {
          String resultJSON;
        List<AMH_Denorm_Account_Opportunity__c> relatedOpps = new list<AMH_Denorm_Account_Opportunity__c>();
        relatedOpps = [SELECT Name, AMH_OpportunityId__c, AMH_OpportunityId__r.Name, AMH_OpportunityId__r.AccountId, AMH_OpportunityId__r.Account.Name,
                        AMH_OpportunityId__r.StageName, AMH_OpportunityId__r.DES_Expected_Revenues__c, AMH_OpportunityId__r.CloseDate,
                        AMH_OpportunityId__r.DES_Booking_Geography__c
                         FROM AMH_Denorm_Account_Opportunity__c WHERE AMH_AccountId__c =: accId
                          AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Won
                          AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Lose];
        Integer oppNumber;
        oppNumber = relatedOpps.size();
        Integer tSize;
        if(tableSize != null) {
          tSize = Integer.valueOf(tableSize);
        }
      
      final Schema.DescribeFieldResult fieldResult = Opportunity.DES_Booking_Geography__c.getDescribe();
      final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
      final Map<String,String> mapValueLabel = new Map<String,String>();
      for( Schema.PicklistEntry v : values) {
          mapValueLabel.put(v.getValue(),v.getLabel());        
      }
      
        final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
        for(AMH_Denorm_Account_Opportunity__c i :relatedOpps) {
          
          String labelCountry;
        labelCountry = mapValueLabel.get(i.AMH_OpportunityId__r.DES_Booking_Geography__c);
            
              listWrapperClass.add(new wrapperClass(i.AMH_OpportunityId__c, i.AMH_OpportunityId__r.Name, i.AMH_OpportunityId__r.AccountId,
                                                    i.AMH_OpportunityId__r.Account.Name, i.AMH_OpportunityId__r.StageName,
                                                    i.AMH_OpportunityId__r.DES_Expected_Revenues__c, i.AMH_OpportunityId__r.CloseDate,
                                                    labelCountry, oppNumber));
        }

        if(tSize == null) {
          system.debug('>>>>> listWrapperClass tSize NULL : ' + listWrapperClass);
                  resultJSON = JSON.serialize(listWrapperClass);
        } else {
          
          
          
          
          final List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
                  Integer regTable = tSize;
                  if(tSize > listWrapperClass.size()) {
                      regTable = listWrapperClass.size();
                  }
                  for(Integer cn = 0; cn < regTable ; cn++) {
                      if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
                          listaWrapperAux.add(listWrapperClass.get(cn));
                      }
                  }
                  resultJSON = JSON.serialize(listaWrapperAux);
        }
          return resultJSON;

      } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }

    }

  /*
  * @author Global Desktop
  * @description clase wrapper para devolver la informacion al componente lightning
  */
    public class wrapperClass {
      /*Declarando variable*/
      final private String oppUrl; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private String accUrl; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private String oppName; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private String accName; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private String status; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private Date closingDate; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private Decimal expectedRevenue; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private String oppCountry; //NOSONAR se usa en wrapperClass
      /*Declarando variable*/
      final private integer oppNumber; //NOSONAR se usa en wrapperClass
      /*Constructor*/
      public wrapperClass(Id oppId, String oppName, Id clientId, String clientName, String status, Decimal expRev, Date closDate, String country, Integer oppNumber) {
        this.oppUrl = '/lightning/r/Opportunity/' + oppId + '/view';
        this.accUrl = '/lightning/r/Account/' + clientId + '/view';
        this.oppName = oppName;
        this.accName = clientName;
        this.status = status;
        this.expectedRevenue = expRev;
        this.closingDate = closDate;
        this.oppCountry = country;
        this.oppNumber = oppNumber;
    }
  }
}