/**
 * @author Global Desktop
 * @description Clase del componente lightning AlertRelatedList de la ficha de grupo.
 */
public with sharing class Campaign_Initiative_RelatedList_Cnt {
  /**
   * SINGLETON PATTERN
   */
  private static Campaign_Initiative_RelatedList_Cnt instance;

  /**
   * getInstance
   */
  public static Campaign_Initiative_RelatedList_Cnt gtInstance() {
    if (instance == null) {
      instance = new Campaign_Initiative_RelatedList_Cnt();
    }
    return instance;
  }

  /*
   * Met0d0 para pasar sonar
   */
  private Campaign_Initiative_RelatedList_Cnt() {
  }

  /*
   * Met0d0 para pasar sonar
   */
  private static List<Campaign> codicionesFamily(String family,String famFilter,String accId) {

    List<Campaign> listCampaign = new List<Campaign>();
    final Set<Id> setCampaignId = new Set<Id>();

    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                      cond__campaign_id__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE cond__participant_id__c = :accId]) {

      setCampaignId.add(iAccountCampaign.cond__campaign_id__c);
    }
    system.debug('setCampaignId>>>==='+setCampaignId);
    if(trueCondition(family)) {
      System.debug('::::::::::>>>famfilter: ' + famfilter);
      listCampaign = [SELECT Id,
                      Name,
                      EndDate,
                      cond__priority_campaign_type__c,
                      Status,
                      soluction_category_id__c,
                      Owner.Name
                      FROM Campaign
                      WHERE Id IN :setCampaignId
                      AND soluction_category_id__c LIKE :famfilter];
    } else {
      listCampaign = [SELECT Id,
                      Name,
                      EndDate,
                      cond__priority_campaign_type__c,
                      Status,
                      soluction_category_id__c,
                      Owner.Name
                      FROM Campaign
                      WHERE Id IN :setCampaignId];
    }
    system.debug('listCampaign>>>==='+listCampaign);
    
    return listCampaign;
  }

  /**
   * @author Global Desktop
   * @description Method para recuperar las alertas relacionadas al cliente
   */
  @auraEnabled
  public static String relatedCampaigns(String tableSize, String accId, String family) {
    try {
      List<Campaign> listCampaign = new List<Campaign>();
      final String famFilter = '%' + family + '%';
      system.debug(famFilter);

      listCampaign = Campaign_Initiative_RelatedList_Cnt.codicionesFamily(family,famFilter,accId);
      final Integer campaignNumber = listCampaign.size();

      List<WrapperClass> listWrapperClass = new List<WrapperClass>();
      for(Campaign iCampaign : listCampaign) {
        WrapperClass iWrapperClass;
        iWrapperClass= new WrapperClass(
          iCampaign.Name,
          iCampaign.Id,
          String.valueOf(Datetime.newInstance(iCampaign.EndDate.year(), iCampaign.EndDate.month(), iCampaign.EndDate.day()).format('dd/MM/yyyy')),
          iCampaign.cond__priority_campaign_type__c,
          iCampaign.Status,
          iCampaign.soluction_category_id__c,
          iCampaign.Owner.Name,
          iCampaign.OwnerId,
          campaignNumber);
        listWrapperClass.add(iWrapperClass);
      }

      Integer tSize;
      if(tableSize != null) {
        tSize = Integer.valueOf(tableSize);
      }
      if(tSize != null) {
        final List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
        Integer regTable = tSize;
        if(tSize > listWrapperClass.size()) {
          regTable = listWrapperClass.size();
        }
        for(Integer cn = 0; cn < regTable; cn++) {
          if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
            listaWrapperAux.add(listWrapperClass.get(cn));
          }
        }
        listWrapperClass = listaWrapperAux;
      }
      return JSON.serialize(listWrapperClass);
    } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }
  }

  /**
   * @author Global Desktop
   * @description Method auxiliar para comprobar una condicion negativa
   */
  private static boolean trueCondition(String family) {
    Boolean isTrue = false;
    if(family != null && family != '' && family != 'Todos' && family != 'All') {
      isTrue = true;
    }
    return isTrue;
  }

  /**
   * @author Global Desktop
   * @description clase para construir lista wrapper
   */
  public class WrapperClass {
    /**
     * @author Global Desktop
     * @description Variables de la clase wrapper
     */
    /* Campaign Name */
    private String campaignName; //NOSONAR
    /* Campaign URL */
    private String campaignURL; //NOSONAR
    /* Campaign End Date */
    private String campaignEndDate; //NOSONAR
    /* Campaign Priority */
    private String campaignPriority; //NOSONAR
    /* Campaign Status */
    private String campaignStatus; //NOSONAR
    /* Campaign Product */
    private String campaignProduct; //NOSONAR
    /* Campaign Status */
    private String campaignOwner; //NOSONAR
    /* Campaign Priority */
    private String campaignOwnerURL; //NOSONAR
    /* Campaign Number */
    private Integer campaignNumber; //NOSONAR

    /**
     * @author Global Desktop
     * @description Construye lista wrapper
     */
    public wrapperClass(String campaignName, Id campaignURL, String campaignEndDate, String campaignPriority, String campaignStatus, String campaignProduct, String campaignOwner, Id campaignOwnerURL, Integer campaignNumber) {
      this.campaignName = campaignName;
      this.campaignURL = '/lightning/r/Campaign/' + campaignURL + '/view';
      this.campaignEndDate = campaignEndDate;
      this.campaignPriority = campaignPriority;
      this.campaignStatus = campaignStatus;
      this.campaignProduct = campaignProduct;
      this.campaignOwner = campaignOwner;
      this.campaignOwnerURL = '/lightning/r/User/' + campaignOwnerURL + '/view';
      this.campaignNumber = campaignNumber;
    }
  }
}