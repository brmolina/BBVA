/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_AddFlatPRoductCtrl
* @Author   Global Hub
* @Date     Created: 2021-07-26
* ------------------------------------------------------------------------------------------------
* @Description Controller class for PRW_AddFlatPRoduct component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-07-26 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class PRW_AddFlatPRoductCtrl {

  /**
  * SINGLETON PATTERN
  */
  private static PRW_AddFlatPRoductCtrl instance;

  /**
  * Constructor
  */
  private PRW_AddFlatPRoductCtrl() {
  }

  /**
  * getInstance
  */
  public static PRW_AddFlatPRoductCtrl gtInstance() {
    if(instance == null) {
      instance = new PRW_AddFlatPRoductCtrl();
    }
    return instance;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a JSON with the data to construct the policie table
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-26
  * @param recordId - Record Id of the account
  * @return List - Data of the flat products
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static List<Flat_product_model__mdt> gtFlatProducts() {
    List<Flat_product_model__mdt> lstProducts = new List<Flat_product_model__mdt>();
    try {
      lstProducts = [
        SELECT Family_Name__c, Family_order__c, Id_product__c, Order__c, Product_name__c
        FROM Flat_product_model__mdt
        ORDER BY Family_order__c, Order__c asc
        LIMIT 1000
      ];
    } catch (Exception e) { //NOSONAR
      throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    system.debug(lstProducts);
    return lstProducts;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a JSON with the data to construct the policie table
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-26
  * @param recordId - Record Id of the account
  * @return List - Data of the conditions
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static List<cuco__ps_catalog_condition__c> gtSpecialProducts() {
    List<cuco__ps_catalog_condition__c> lstProducts = new List<cuco__ps_catalog_condition__c>();
    final List<String> forbiddenConditions = new List<String>{'EEEp.rec.order.pay','EEEp.issued.order.pay.EUR','EEEp.issued.order.pay','EEEp.issued.order.pay.URGENT.EUR','debit.counter.phone','debit.counter.foreign', 'debit.counter.internet','debit.express.phone',
    'debit.express.card' , 'debit.express.branch' , 'debit.express.atm' , 'debit.express.internet' , 'debit.sepa.dev.preliquid.other','debit.sepa.dev.preliquidation' };
    try {
      lstProducts = [
        SELECT name, cuco__gf_psc_family_id__r.name,cuco__gf_psc_condition_id__c, cuco__gf_psc_family_id__r.cuco__gf_psc_family_product_name__c
        FROM cuco__ps_catalog_condition__c
        WHERE cuco__gf_psc_cond_avail_ind_type__c = true and cuco__gf_psc_family_id__r.cuco__gf_psc_family_avail_ind_type__c = true and gf_psc_cond_pricewise_ind_type__c = true and cuco__gf_psc_condition_id__c not in:forbiddenConditions
        ORDER BY cuco__gf_psc_family_id__r.cuco__gf_psc_fmly_visual_ord_number__c, cuco__gf_psc_cond_visual_ord_number__c
        LIMIT 1000
      ];

      system.debug(lstProducts);
    } catch (Exception e) { //NOSONAR
      system.debug(lstProducts);
      throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    return lstProducts;
  }
}