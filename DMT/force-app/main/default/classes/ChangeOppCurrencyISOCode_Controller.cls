/*
*
*   Global Desktop - DSL
*   Esta clase contiene los methods necesarios para llevar a cabo la lógica del componente 'ChangeOppCurrencyISOCode'
*
*
*/
public with sharing class ChangeOppCurrencyISOCode_Controller {

  public static final Map<Id, OpportunityLineItem> MAP_OLLI_OLD_NEW = new Map<Id, OpportunityLineItem>();
  private static final List<String> LST_EXCLUDE_FIELDS = new List<String>{'unitprice','sortorder', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'isdeleted'/*, 'DES_NBC_Approval__c', 'DES_NBC_Approval_Date__c', 'opportunity_nbc_recm_ind_type__c', 'opportunity_nbc_recm_date__c', 'des_nbc_comments__c', 'opportunity_nbc_recm_ind_type__c', 'opportunity_nbc_comments_desc__c'*/};
  private static final String STR_SELECT = 'SELECT ';
  private static final String MSG_ERROR = 'Something went wrong: ';

  /**
  * @author Global Desktop  - DSL
  */
  @AuraEnabled
  public static Opportunity gtOpportunityInfo(Id recordId) {
    List<Opportunity> listOpp;
    try {
            listOpp = new List<Opportunity>([
            SELECT Id, Name, CurrencyISOCode, StageName
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
      ]);
    } catch (Exception e) {
      throw new AuraHandledException(MSG_ERROR + e);
    }

    return listOpp.get(0);
  }

  /**
  * @author Global Desktop  - DSL
  */
  @AuraEnabled
  public static DES_Template__c gtRelatedTemplate(Id recordId) {
    DES_Template__c templ;
    templ = new DES_Template__c();
    List<DES_Template__c> listTemplate;
    try {
      listTemplate = new List<DES_Template__c>([
        SELECT Id, opportunity_id__c
        FROM DES_Template__c
        WHERE opportunity_id__c = :recordId
        LIMIT 1
      ]);
    } catch (Exception e) {
      throw new AuraHandledException(MSG_ERROR + e);
    }
    system.debug('>>>>> listTemplate : ' + listTemplate);
    if(!listTemplate.isEmpty()) {
      templ = listTemplate.get(0);
    }
    system.debug('>>>>> templ : ' + templ);
    return templ;
  }

  /**
  * @author Global Desktop  - DSL
  */
  @AuraEnabled
  public static String chgOppCurrencyISOCode(Id recordId, String isoCodeSelected) {
    String strMessage;
    try {
		gtOpportunityLineItems(recordId, isoCodeSelected);
      	strMessage = 'The currency has been changed succesfully.';
    } catch(Exception e) {
  		throw new AuraHandledException(MSG_ERROR + e);
    }
    return strMessage;
  }

  @future
  private static void gtOpportunityLineItems(Id oppId, String isoCode) {
    //Lista con campos que no se tienen que copiar. PONER SIEMPRE EN MINUSCULAS
    String query;
    query = STR_SELECT;
    final Schema.DescribeSObjectResult oppliDesc = OpportunityLineItem.sObjectType.getDescribe();
    for(String apiName : oppliDesc.fields.getMap().keySet()) {
      system.debug('>>>>> apiName : ' + apiName);
      if(!LST_EXCLUDE_FIELDS.contains(apiName)) {
        if(query == STR_SELECT) {
          query += apiName;
        } else {
          query += ', ' + apiName;
        }
      }
    }
    query += ' FROM OpportunityLineItem WHERE OpportunityId = :oppId';
    system.debug('>>>>> query: ' + query);

    //GET Tranches
    final List<String> listStrExclFields = new List<String>{'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'isdeleted'};
    String query2;
    query2 = STR_SELECT;
    final Schema.DescribeSObjectResult trnacheDesc = fprd__GBL_Complex_product_section__c.sObjectType.getDescribe();
    for(String apiName : trnacheDesc.fields.getMap().keySet()) {
      system.debug('>>>>> apiName : ' + apiName);
      if(!listStrExclFields.contains(apiName)) {
        if(query2 == STR_SELECT) {
          query2 += apiName;
        } else {
          query2 += ', ' + apiName;
        }
      }
    }
    query2 += ' FROM fprd__GBL_Complex_product_section__c WHERE opportunity_id__c = :oppId';
    final List<fprd__GBL_Complex_product_section__c> listRelTranches = Database.query(query2);

	//Borrado de las antiguas oppLine y creación de las nuevas con el cambio de currency
    final List<OpportunityLineItem> lOppLineFuture = Database.query(query);
    final List<OpportunityLineItem> lOppLineDelete = Database.query(query);
    delete lOppLineDelete;
    final Opportunity oppISOChanged = new Opportunity(Id = oppId, CurrencyISOCode = isoCode, Pricebook2Id = null);
	update oppISOChanged;
    final List<OpportunityLineItem> lstOppProdClone = new List<OpportunityLineItem>();
    final Map<Id, Id> mapProdPriceBook = gtPriceBookEntry(lOppLineFuture, isoCode);
    for(OpportunityLineItem oppProd : lOppLineFuture) {
      OpportunityLineItem oppli;
      oppli = oppProd.clone(false, true);
      oppli.PriceBookEntryID = mapProdPriceBook.get(oppProd.Product2Id);
      lstOppProdClone.add(oppli);
      MAP_OLLI_OLD_NEW.put(oppProd.Id, oppli);
    }
    insert MAP_OLLI_OLD_NEW.values();

    //INSERT TRANCHES
    final List<fprd__GBL_Complex_product_section__c> lstNewTrnchs = new List<fprd__GBL_Complex_product_section__c>();
    for(fprd__GBL_Complex_product_section__c tranche : listRelTranches) {
      fprd__GBL_Complex_product_section__c newTranche;
      newTranche = tranche.clone(false, true);
      newTranche.fprd__GBL_Opportunity_product__c = MAP_OLLI_OLD_NEW.get(tranche.fprd__GBL_Opportunity_product__c).Id;
      newTranche.opportunity_id__c = oppId;
      lstNewTrnchs.add(newTranche);
    }
    if(!lstNewTrnchs.isEmpty()) {
        insert lstNewTrnchs;
        update lstNewTrnchs;
  	}
  }

  /**
  * @author Global Desktop  - DSL
  */
  private static Map<Id, Id> gtPriceBookEntry(List<OpportunityLineItem> lstOppProdOrig, String isoCode) {
    Map<Id, Id> mapProdPriceBook;
    mapProdPriceBook = new Map<Id, Id>();
    Set<Id> setProductsIds;
    setProductsIds = new Set<Id>();
    for(OpportunityLineItem oppli : lstOppProdOrig) {
        if(!setProductsIds.contains(oppli.Product2Id)) {
          setProductsIds.add(oppli.Product2Id);
        }
    }
    for(PricebookEntry prbe : [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN :setProductsIds AND CurrencyIsoCode = :isoCode]) {
      mapProdPriceBook.put(prbe.Product2Id, prbe.Id);
    }

    system.debug('>>>>> mapProdPriceBook : ' + mapProdPriceBook);
    return mapProdPriceBook;
  }

  /**
  * @author Global Desktop  - DSL
  */
  @AuraEnabled
  public static Boolean deleteTemplate(Id templateId) {
    Boolean success = false; //NOSONAR
    final DES_Template__c templ = new DES_Template__c(Id = templateId);
    system.debug('>>>>> templ : ' + templ);
    try {
      delete templ;
      success = true;
    } catch(Exception e) {
      throw new AuraHandledException(MSG_ERROR + e);
    }
    system.debug('>>>>> success : ' + success);
    return success;
  }

}