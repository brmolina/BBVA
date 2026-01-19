/*
 *
 *  @author Global Desktop - DSL
 *  @Description  - Clase que contiene la lógica que valida los campos obligatorios de las tranches al cambiar el estado de la oportunidad.
 *
 */
public with sharing class RelatedTranchesValidations {

  /*
   *  Mapa que contiene el id de la Opp de la tranche y el String del mensaje de error como value
   *
  */
  final public Map<Id, String> mapOppTranchsMess = new Map<Id, String>(); //NOSONAR

  /*SINGLETON PATTERN
   *  @author GlobalDesktop  - DSL
   *
  **/
  private static RelatedTranchesValidations instance;


	/*constructor
   *  @author GlobalDesktop  - DSL
   *
  **/
  private RelatedTranchesValidations() {
    System.debug('CONSTRUCTOR');
  }

  /*SINGLETON PATTERN
   *  @author GlobalDesktop  - DSL
   *
  **/
  public static RelatedTranchesValidations getInstance() { //NOSONAR
      if (instance == null) {
      instance = new RelatedTranchesValidations();
      }
      return instance;
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description  Funcion que se encarga de las validaciones de los campos obligatorios de las tranches
  *
  **/
  public void validateTranches(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
    final Map<Id, Opportunity> mapOppsStageChg = gtOppsStageChanged(triggerNewMap, triggerOldMap);
    if(!mapOppsStageChg.isEmpty()) {
      final Map<Id, OpportunityLineItem> mapAllOppli = gtAllProducts(mapOppsStageChg);
      final Map<Id,List<fprd__GBL_Complex_product_section__c>> mapOpTranches = gtAllTranches(triggerNewMap, mapAllOppli);
      //system.debug('>>>>> mapOpTranches: ' + JSON.serialize(mapOpTranches));
      checkTranchesFields(triggerNewMap, mapOpTranches, mapAllOppli);

    }
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que devuelve un mapa con las oportunidades que han cambiado de estado
  *
  **/
  public Map<Id, Opportunity> gtOppsStageChanged(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
    final Map<Id, Opportunity> mapOppsReturn = new Map<Id, Opportunity>();
    for(Opportunity opp : triggerNewMap.values()) {
      if( opp.opportunity_expiration_ind_type__c == false
      &&  opp.StageName != triggerOldMap.get(opp.Id).StageName
      && !checkPrevStage(opp,triggerOldMap.get(opp.Id))
      && opp.StageName != Label.DES_Ready_to_close) {
        // checkNBCConditions(opp, triggerOldMap.get(opp.Id));
        if(opp.HasOpportunityLineItem) {
          mapOppsReturn.put(opp.Id, opp);
        } else {
          opp.addError(String.format(Label.Des_MandatoryRelatedProduct, new List<String>{opp.StageName,'product'}));
        }
      }
    }
    system.debug('>>>>> mapOppsReturn: ' + mapOppsReturn);
    return mapOppsReturn;
  }

  /*
   *  @author   GLOBAL DESKTOP  - DSL
   *  @Descripiton  Función que devuelve TRUE si se está cambiando a un stage anterior y
   *                FALSE si se está cambiando a un stage más avanzado.
   *
   **/
   private Boolean checkPrevStage(Opportunity oppNew, Opportunity oppOld) { //NOSONAR
     Boolean retrn;
     retrn = false;
     if(oppNew.StageName == Label.DES_OPP_stage_draft
     || (oppNew.StageName ==  Label.DES_Proposal && oppOld.StageName != Label.DES_OPP_stage_draft)
     || (oppNew.StageName == Label.DES_Approvals && oppOld.StageName != Label.DES_Proposal && oppOld.StageName != Label.DES_OPP_stage_draft)
     || (oppNew.StageName == Label.DES_Ready_to_close && oppOld.StageName == Label.DES_Closed_Won && oppOld.StageName == Label.DES_Closed_Lose)) {
       retrn = true;
     }
     system.debug('>>>>> retrn: ' + retrn);
     return retrn;
   }


  /*
  * @author   Global Desktop  - DSL
  * @Description  Funcion que devuelve una lista con ALL los Complex product Section (tranches)
  *               a partir de los opportunitylineitem (opportunity product) indicados por parametro
  *
  **/
  private static Map<Id,List<fprd__GBL_Complex_product_section__c>> gtAllTranches(Map<Id, Opportunity> triggerNewMap, Map<Id, OpportunityLineItem> mapAllOppli) {
    Map<Id,List<fprd__GBL_Complex_product_section__c>> mapRturn;
    mapRturn = new Map<Id,List<fprd__GBL_Complex_product_section__c>>();
    for(Opportunity oppNew : triggerNewMap.values()) {
      final List<fprd__GBL_Complex_product_section__c> lstOpTrnchs = [SELECT Id, fprd__GBL_Opportunity_product__c, fprd__GBL_Empty_visible_fields__c, opportunity_product_tranche_desc__c, opportunity_id__c, Opportunity__c
      FROM fprd__GBL_Complex_product_section__c
      WHERE fprd__GBL_Opportunity_product__c IN :mapAllOppli.keySet() AND Opportunity__c = :oppNew.Id];
      mapRturn.put(oppNew.Id,lstOpTrnchs);
    }

    return mapRturn;
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que devuelve un mapa con ALL los OpportunityLineItem (Opportunity product)
  *               a partir de las oportunidades indicadas por parametro
  *
  **/
  public static Map<Id, OpportunityLineItem> gtAllProducts(Map<Id, Opportunity> mapOppsChanged) {
    // final Map<Id, OpportunityLineItem> mapOppProducts = n
    // system.debug('>>>>> mapOppProducts: ' + mapOppProducts);
    return new Map<Id, OpportunityLineItem>([
      SELECT Id, OpportunityId, Name, Product2.Name, multi_tranche_type__c
      FROM OpportunityLineItem
      WHERE OpportunityId IN :mapOppsChanged.keySet()
    ]);
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que se encarga de validar que esten ALL los campos obligatorios del objeto 'Complex Product Section' (tranches) rellenos.
  *
  **/
  private void checkTranchesFields(Map<Id, Opportunity> triggerNewMap, Map<Id,List<fprd__GBL_Complex_product_section__c>> mapOpTranches, Map<Id, OpportunityLineItem> mapAllOppli) {
    List<fprd__GBL_Complex_product_section__c> lstNewStgeTrnchs;
    lstNewStgeTrnchs = new List<fprd__GBL_Complex_product_section__c>();
    List<fprd__GBL_Complex_product_section__c> lstOptranches;
    Set<Id> oppsChecked;
    oppsChecked = new Set<Id>();
    for(OpportunityLineItem opliNew : mapAllOppli.values()) {//NOSONAR
      Opportunity oppNew = triggerNewMap.get(opliNew.OpportunityId);
      if(opliNew.multi_tranche_type__c != null && opliNew.multi_tranche_type__c == Label.DES_YES && !oppsChecked.contains(oppNew.Id)) {
        oppsChecked.add(oppNew.Id);
        lstOptranches = mapOpTranches.get(oppNew.Id);
        if(oppNew.StageName !=Label.DES_OPP_stage_draft && oppNew.StageName !=Label.DES_Proposal && (lstOptranches == null || lstOptranches.isEmpty())) {
          oppNew.addError(String.format(Label.Des_MandatoryRelatedProduct, new List<String>{oppNew.StageName,'tranche in products marked as multitranche'}));
        }
        for(fprd__GBL_Complex_product_section__c tranche : lstOptranches) {//NOSONAR
          if(tranche.fprd__GBL_Empty_visible_fields__c == null
          || tranche.fprd__GBL_Empty_visible_fields__c == '') {
            tranche.opportunity_stage_type__c = triggerNewMap.get(mapAllOppli.get(tranche.fprd__GBL_Opportunity_product__c).OpportunityId).StageName;
            lstNewStgeTrnchs.add(tranche);
          } else {
            system.debug('>>>>> tranche: ' + tranche);
            createMessage(tranche, mapAllOppli);
          }
        }
      }
    }
    system.debug('>>>>> mapOppTranchsMess: ' + JSON.serialize(mapOppTranchsMess));
    for(Id oppId : mapOppTranchsMess.keySet()) {
      system.debug('>>>>> mapOppTranchsMess.get(oppId) : ' + mapOppTranchsMess.get(oppId));
      triggerNewMap.get(oppId).addError(Label.TRANCHES_VALIDATION_FIELDS_ERROR + mapOppTranchsMess.get(oppId));
    }
    DES_relatedTranchesTriggerHandler.noLoopUpdates = true;
    update lstNewStgeTrnchs;
    DES_relatedTranchesTriggerHandler.noLoopUpdates = false;
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que se encarga de generar el mensaje con los campos obligatorios de cada tranche.
  *
  **/
  private void createMessage(fprd__GBL_Complex_product_section__c tranche, Map<Id, OpportunityLineItem> mapAllOppli) {
    String message;
    message = '';
    if(mapOppTranchsMess.get(tranche.opportunity_id__c) == null) {
      if(tranche.opportunity_product_tranche_desc__c == null) {
        message += ' ' + mapAllOppli.get(tranche.fprd__GBL_Opportunity_product__c).Product2.Name;
      } else {
        message += ' ' + mapAllOppli.get(tranche.fprd__GBL_Opportunity_product__c).Product2.Name + ': Tranche  "' + tranche.opportunity_product_tranche_desc__c + '"';
      }
    } else {
      if(tranche.opportunity_product_tranche_desc__c == null) {
        message += mapOppTranchsMess.get(tranche.opportunity_id__c) + ', ' + mapAllOppli.get(tranche.fprd__GBL_Opportunity_product__c).Product2.Name + ' Untyped Tranche';
      } else {
        message += mapOppTranchsMess.get(tranche.opportunity_id__c) + ', ' + mapAllOppli.get(tranche.fprd__GBL_Opportunity_product__c).Product2.Name + ': Tranche "' + tranche.opportunity_product_tranche_desc__c + '"';
      }
    }
    mapOppTranchsMess.put(tranche.opportunity_id__c, message);
    system.debug('>>>>> mapOppTranchsMess : ' + JSON.serialize(mapOppTranchsMess));
  }


}//FIN RelatedTranchesValidations