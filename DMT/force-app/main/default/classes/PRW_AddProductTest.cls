/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_AddProductTest
* @Author   Global Hub
* @Date     Created: 2021-08-10
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_AddFlatPRoductCtrl and PRW_AddSpecialPRoductCtrl
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-10 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_AddProductTest {
  /**
  * @description
  * @author Global Hub | 2021-08-10
  **/
  @isTest
  static void gtFlatProductsTest() {
    final PRW_AddFlatPRoductCtrl instance = PRW_AddFlatPRoductCtrl.gtInstance();
    system.debug(instance);
    final List<Flat_product_model__mdt> productsFlat = PRW_AddFlatPRoductCtrl.gtFlatProducts();
    system.assert(!productsFlat.isEmpty(), 'Flat_product_model__mdt empty');
  }

  /**
  * @description
  * @author Global Hub | 2021-08-10
  **/
  @isTest
  static void gtSpecialProductsTest() {
    final cuco__ps_catalog_family__c fam = new cuco__ps_catalog_family__c();
    fam.cuco__gf_psc_family_avail_ind_type__c = true;
    fam.name = 'Transferencias emitidas';
    fam.cuco__gf_psc_family_product_name__c = 'Pagos Nacionales y EEE';
    fam.cuco__gf_psc_fmly_visual_ord_number__c = 1;
    insert fam;
    final cuco__ps_catalog_condition__c cond = new cuco__ps_catalog_condition__c();
    cond.Name = 'Gastos de Correo';
    cond.cuco__gf_psc_family_id__c = fam.Id;
    cond.gf_psc_cond_pricewise_ind_type__c = true;
    cond.cuco__gf_psc_cond_avail_ind_type__c = true;
    cond.cuco__gf_psc_condition_id__c = 'np.transfer.mail.expenses';
    cond.cuco__gf_psc_cond_visual_ord_number__c = 1;
    insert cond;
    final List<cuco__ps_catalog_condition__c> productsSpecial = PRW_AddFlatPRoductCtrl.gtSpecialProducts();
    system.assert(!productsSpecial.isEmpty(), 'productsSpecial empty');
  }
}