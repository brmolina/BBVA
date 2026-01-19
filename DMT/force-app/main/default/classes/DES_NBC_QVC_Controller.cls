/**
   * Autor: Christian Jimeno Fuertes
   */
public with sharing class DES_NBC_QVC_Controller {

  /**
   * SINGLETON PATTERN
   */
  private static DES_NBC_QVC_Controller instance;


  /**
   * Constructor
   */
  private DES_NBC_QVC_Controller() {
  }

  /**
   * getInstance
   */
  public static DES_NBC_QVC_Controller getInstance() {//NOSONAR
    if (instance == null) {
      instance = new DES_NBC_QVC_Controller();
    }
    return instance;
  }

    /**
   * Devuelve las oportunidades asociadas al comite nbc.
   */
  public static List<Opportunity> listOpp(id nbcId) {
      try {
        return [SELECT Id, Name, Account.Name   FROM Opportunity WHERE Committee_id__c=:nbcId];
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
  }

    /**
   * Devuelve el numero de miembros del comite
   */
  public static Integer countMembers() {
      try {
        final List<GroupMember> nbcMembers = [select id from GroupMember where GroupId in (select id from Group where DeveloperName = 'Virtual_NBC_Commitee_Team') ];

        return nbcMembers.size();
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
  }

       /**
   * Devuelve el numero de votos por comite
   */
  public static Map<Id,Integer> countMembersVotes(id nbcId) {
      try {
        Final Map<Id,Integer>  mapaVotos = new Map<Id,Integer>();
        final List<NBC_Commitee_Member__c> nbcMembers = [select id, opportunity_id__c from NBC_Commitee_Member__c where gf_oppy_virtual_cmtee_id__c = :nbcId and gf_virtual_cmtee_supp_ind_type__c != '-' ];//NOSONAR
        for (NBC_Commitee_Member__c member : nbcMembers) {
          if (mapaVotos.containsKey(member.opportunity_id__c)) {
            mapaVotos.put(member.opportunity_id__c,mapaVotos.get(member.opportunity_id__c)+1);
          } else {
            mapaVotos.put(member.opportunity_id__c,1);
          }
        }
        return mapaVotos;
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
  }

       /**
   * Devuelve las oportunidades asociadas al comite nbc.
   */
  @AuraEnabled
  public static String opportunityJson(id nbcId) {
      String json = '';
      try {
        final List<Opportunity> lOpty = listOpp(nbcId);
        final Integer members = countMembers();
        final Map<Id,Integer> votes = countMembersVotes(nbcId);
        json = generateStructure(lOpty,members,votes);//NOSONAR

      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
      return json;
  }
    /**
   * generateStructure.
   */
    public static String generateStructure(List<Opportunity> lOpty, Integer members, Map<Id,Integer> votes) {//NOSONAR
        String json = '';
        Final DES_QVC_Json jsoncls = new DES_QVC_Json();
        final DES_QVC_Json.InputJsonCs inputcs = new DES_QVC_Json.InputJsonCs();
        final List<List<DES_QVC_Json.InputJsonData>> data = new List<List<DES_QVC_Json.InputJsonData>>();
        final List<DES_QVC_Json.InputJsonData> cardsBase = new List<DES_QVC_Json.InputJsonData>();
        final DES_QVC_Json.InputJsonData itemBase = new DES_QVC_Json.InputJsonData();

        //Config card
        inputcs.GBLshowTitle = false ;
        inputcs.GBLorientation = 2; //Vertical
        inputcs.Id = 'inputJsonModeId';
        inputcs.Name = 'inputJsonModeCS';

        //Config Base Item
        itemBase.type = '08';
        itemBase.format = 'NOTHING';
        itemBase.icon = 'NOTHING';
        itemBase.typeIcon = 'NOTHING';

        for(Opportunity opp : lOpty) {
            final List<DES_QVC_Json.InputJsonData> cards = cardsBase.clone();
            //Opp name
            final DES_QVC_Json.InputJsonData itemOpp = itemBase.clone();
            itemOpp.label = 'Opportunity';
            if(opp.Name.length() > 35) {//NOSONAR
                itemOpp.value = opp.Name.substring(0,34)  ;
            } else {
                itemOpp.value = opp.Name;
            }
            itemOpp.isSubtitle = 'true';
            itemOpp.idRecord = opp.Id;

            //cliente
            final DES_QVC_Json.InputJsonData itemCliente = itemBase.clone();
            itemCliente.label = 'Client';
            if(opp.Account.Name.length() > 35){//NOSONAR
                itemCliente.value = opp.Account.Name.substring(0,34);
            } else {
                itemCliente.value = opp.Account.Name;
            }
            itemCliente.idRecord = opp.Id;
            itemCliente.isSubtitle = 'false';

            //votes
            final DES_QVC_Json.InputJsonData itemVotos = itemBase.clone();
            itemVotos.label = 'Votes';
            if(votes.containsKey(opp.Id)) {
              itemVotos.value = votes.get(opp.Id) + ' out of ' + members;
            } else {
              itemVotos.value = '0 out of ' + members;
            }
            itemVotos.idRecord = opp.Id;
            itemVotos.isSubtitle = 'false';

            cards.add(itemOpp);
            cards.add(itemCliente);
            cards.add(itemVotos);
            data.add(cards);
        }
        jsoncls.inputJsonCs = inputcs;
        jsoncls.inputJsonData = data;
        json = jsoncls.toJson();

        return json;
  }

}