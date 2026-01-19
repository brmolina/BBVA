/**
* @author Global Desktop
* @description Lookup Custom para oferta comercial
*/
public with sharing class DES_MultiSelect_Lookup_Ctr {

	/**
	* @author Global Desktop
	* @description SINGLETON PATTERN
	*/
  	private static DES_MultiSelect_Lookup_Ctr instance;

  	/**
   	* @author Global Desktop
   	* @description getInstance
   	*/
  	public static DES_MultiSelect_Lookup_Ctr getInstance() { //NOSONAR
    	if (instance == null) {
      		instance = new DES_MultiSelect_Lookup_Ctr();
    	}
    	return instance;
  	}

   /*
    * Met0d0 para pasar sonar
    */
    private DES_MultiSelect_Lookup_Ctr() {}

	/*
	* Met0d0 principal que construye la query dinámicamente
	*/
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String comOfferId, List<sObject> excludeitemsList) {
        final String searchKey = '%' + searchKeyWord + '%';
        system.debug(searchKey);
        final String searchKey2 = '*'+searchKeyWord + '*';
        List<List<Opportunity>> lstOfRecordsSOSL = new List<List<Opportunity>> ();
        final coff__Commercial_Offer__c objectCO = [SELECT id, coff__participant_id__r.DES_Client_Type__c, coff__participant_id__c from coff__Commercial_Offer__c where id = :comOfferId LIMIT 1];
        Boolean isCibGroup = false;

        final List<string> lstExcludeitems = new List<string>();
        if(!excludeitemsList.isEmpty()) {
            for(sObject item : excludeitemsList) {
                lstExcludeitems.add(item.id);
            }
        }
        if(objectCO.coff__participant_id__r.DES_Client_Type__c == Label.CIB_Group) {
            isCibGroup = true;
        }

        lstOfRecordsSOSL = soslquery(isCibGroup, objectCO, lstExcludeitems, searchKey2);

        return filtrarLista(lstOfRecordsSOSL, comOfferId);
    }
    /**
    * Met0d0 que devuelve la query con los valores que se buscan en el met0do fetchlookup
     */
    @AuraEnabled
    public static List<List<Opportunity>> soslquery(Boolean isCibGroup,coff__Commercial_Offer__c objectCO, List<string> lstExcludeitems, string searchKey2) {

        List<List<Opportunity>> lstOfRecordsSOSL = new List<List<Opportunity>> ();
        if(isCibGroup) {
            final List<DES_Subsidiary_Group_Relation__c> listaFiliales = [SELECT participant_child_id__c from DES_Subsidiary_Group_Relation__c WHERE participant_parent_id__c = :objectCO.coff__participant_id__c];
            final Set<Id> subsRealated = new set<Id> ();
            for(DES_Subsidiary_Group_Relation__c eachSub : listaFiliales) {
                subsRealated.add(eachSub.participant_child_id__c);
            }
            //Hacemos la Query de todas las oportunidades relacionadas a las filiales del grupo
            lstOfRecordsSOSL = [FIND :searchKey2 IN NAME FIELDS RETURNING Opportunity(id, Name where AccountId IN :subsRealated AND Id NOT IN :lstExcludeitems)];
        } else {
            //Hacemos la Query de todas las oportunidades relacionadas a la filial
            lstOfRecordsSOSL = [FIND :searchKey2 IN NAME FIELDS RETURNING Opportunity(id, Name where AccountId = :objectCO.coff__participant_id__c AND Id NOT IN :lstExcludeitems)]; //NOSONAR
        }
        return lstOfRecordsSOSL;
    }

    /**
    * Met0d0 que devuelve el resultado final del met0do fetchlookup
     */
    @AuraEnabled
    public static List <Opportunity> filtrarLista(List<List<Opportunity>> lstOfRecordsSOSL,String comOfferId) {
        final List <Opportunity> tripleFiltro = new List <Opportunity> ();
        if(lstOfRecordsSOSL != null) {
        List <Opportunity> lstFiltrada = new List <sObject> ();
        List <Opportunity> dobleFiltro = new List <Opportunity> ();
            final Set <Id> lstIdFilt = new Set < Id > ();
            for(List<SObject> lObject : lstOfRecordsSOSL) {
                for(SObject op : lObject) {
                lstIdFilt.add(String.valueof(op.get('Id')));
                }
            }
            lstFiltrada = [SELECT id, Name, Owner.Name, gf_opportunity_product_desc__c FROM Opportunity WHERE id =:lstIdFilt];
            dobleFiltro = [SELECT id FROM Opportunity Where coff__gf_commercial_offer_id__c =:comOfferId];
            Boolean check = false;
            for(Opportunity cuOpp : lstFiltrada) {
                for(Opportunity cu2Opp :dobleFiltro) {
                    if(cuOpp.Id == cu2Opp.Id) {
                        check = true;
                    }
                }
                if(!check) {
                    tripleFiltro.add(cuOpp);
                }
                check = false;
                system.debug(check);
            }
        }
        return tripleFiltro;
    }

    /*
    * Met0d0 para mostrar todas las oportunidades asociadas.
    */
    @AuraEnabled
    public static void oppReadyToRelate(String commercialOffer, List<sObject> lstOpp) {
        try {
            Set<Id> lstExcludeitems;
            lstExcludeitems = new Set<Id>();
            Boolean anchor = false;
            Boolean newAnchor = false;
            for(sObject item : lstOpp) {
                lstExcludeitems.add(item.id);
            }
            System.debug('----------------> la lstExcludeitems es: ' +lstExcludeitems);
            final List<Opportunity> oppRecord = [SELECT Id, Name, coff__gf_commercial_offer_id__c, gf_comm_offer_moppy_ind_type__c from Opportunity where Id = :lstExcludeitems];
            final List<Opportunity> relatedOpps = [SELECT Id, Name, coff__gf_commercial_offer_id__c, gf_comm_offer_moppy_ind_type__c FROM Opportunity WHERE coff__gf_commercial_offer_id__c =: commercialOffer];
            System.debug('----------------> la oppRecord es: ' +oppRecord);
            for(Opportunity opp: relatedOpps) {
                if(opp.gf_comm_offer_moppy_ind_type__c) {
                    anchor = true;
                }
            }
            for(Opportunity opp: oppRecord) {
                opp.coff__gf_commercial_offer_id__c = commercialOffer;
                if(!anchor && !newAnchor) {
                    opp.gf_comm_offer_moppy_ind_type__c = true;
                    newAnchor = true;
                    system.debug(newAnchor);
                }
            }
            update oppRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }

    /*
    * Met0d0 para mostrar todas las oportunidades asociadas.
    */
    @AuraEnabled
    public static String listarOpp(List<Opportunity> lstOpp) {
        try {
			Set<Id> idOpps = new Set<Id>(); //NOSONAR
            Boolean relacionada = false;
            final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
            System.debug(listWrapperClass);
            String resultado = '';
            if(!lstOpp.isEmpty()) {
                for(Opportunity opp : lstOpp) {
                    idOpps.add(opp.Id);
                }
                final List<Opportunity> newOpps = [Select Id, coff__gf_commercial_offer_id__c, Name, gf_opportunity_product_desc__c, Owner.Name FROM Opportunity WHERE Id =: idOpps];
                for(Opportunity opp : newOpps) {
                    if(opp.coff__gf_commercial_offer_id__c == null) {
                        listWrapperClass.add(new wrapperClass(opp.Id, opp.Name, opp.Owner.Name, opp.gf_opportunity_product_desc__c));
                    } else {
                	    relacionada = true;
                    }
                }
            }
            if(relacionada) {
                resultado = 'error'; //NOS
            } else {
                resultado = JSON.serialize(listWrapperClass);
            }
            return resultado;
        } catch(Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }

    /**
    *
    * Clase necesaria para  recoger los valores de la tabla
    * @author Global Desktop
    */
    public class wrapperClass {
      /*
      * Variable para recoger el nombre de la oportunidad
      */
      final String oppName;
      /*
      * Variable para recoger el id de la oportunidad
      */
      final Id idOpp;
      /*
      * Variable para recoger el nombre de la oportunidad
      */
      final String owner;
      /*
      * Variable para recoger el id de la oportunidad
      */
      final String product;

      /*
      * Met0d0 para setear los datos de la tabla
      */
      public wrapperClass(Id idOpp, String oppName, String owner, String product) {
        this.oppName = oppName;
        this.idOpp = idOpp;
        this.owner = owner;
        this.product = product;
      }
    }
}