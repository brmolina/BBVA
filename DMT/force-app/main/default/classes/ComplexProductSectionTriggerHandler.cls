/*
 *
 *  @author Global Desktop  - DSL
 *  @Description    - Clase que contiene la lógica del trigger del objeto Complex Product Section (tranches)
 *
 * @Revision        JSS - 2019/08/23 añadido rellenar el valor del campo Opportunity__c, que es un lookup al objeto
 *            Opportunity que se ha creado para poder realizar el report con info de Oportunidad + Producto + Tramo

 */
public with sharing class ComplexProductSectionTriggerHandler {

 /*
 *  @author Global Desktop  - DSL
 */
  private static ComplexProductSectionTriggerHandler instance;

/*
 *  @author Global Desktop  - DSL
 *
 */
  private ComplexProductSectionTriggerHandler() {
    system.debug('ComplexProductSectionTriggerHandler constructor');
  }

 /*
 *
 *  @author Global Desktop  - DSL
 *
 */
  public static ComplexProductSectionTriggerHandler getInstance() {//NOSONAR
    if (instance == null) {
      instance = new ComplexProductSectionTriggerHandler();
    }
    return instance;
  }

/*
 *
 *  @author Global Desktop  - DSL
 *
 *  @Description  METHOD que contiene la lógica del Before Insert
 */
  public void onBeforeInsert(List<fprd__GBL_Complex_product_section__c> triggerNew) {
    stOpportunityIdField(triggerNew);
  }

/*
 *
 *  @author Global Desktop  - DSL
 *
 *  @Description  METHOD que setea en el campo opportunity_id__c el Id de la oportunidad relacionada con el producto de la tranche
 */
  private void stOpportunityIdField(List<fprd__GBL_Complex_product_section__c> triggerNew) {//NOSONAR
    final Set<Id> setOppPrductsId = new Set<Id>();
    for(fprd__GBL_Complex_product_section__c tranche : triggerNew) {
      if(!setOppPrductsId.contains(tranche.fprd__GBL_Opportunity_product__c)) {
        setOppPrductsId.add(tranche.fprd__GBL_Opportunity_product__c);
      }
    }

    //BUSCO LOS OPP PRODUCTS PARA COGER EL ID DE LA OPP Y GUARDARLA EN EL CAMPO DE LA TRANCHE
    final Map<Id, Id> mapIdProductIdOpp = new Map<Id, Id>();
    for(OpportunityLineItem oppli : [SELECT Id, OpportunityId, Name FROM OpportunityLineItem WHERE Id IN :setOppPrductsId]) {
      if(mapIdProductIdOpp.get(oppli.Id) == null) {
        mapIdProductIdOpp.put(oppli.Id, oppli.OpportunityId);
      }
    }
    system.debug('>>>>> mapIdProductIdOpp: ' + JSON.serialize(mapIdProductIdOpp));

    for(fprd__GBL_Complex_product_section__c tranche : triggerNew) {
      tranche.opportunity_id__c = mapIdProductIdOpp.get(tranche.fprd__GBL_Opportunity_product__c);
      tranche.Opportunity__c = mapIdProductIdOpp.get(tranche.fprd__GBL_Opportunity_product__c);
    }
    system.debug('>>>>> triggerNew: ' + JSON.serialize(triggerNew));
  }
}