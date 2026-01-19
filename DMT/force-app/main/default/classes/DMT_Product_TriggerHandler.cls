/**
* ────────────────────────────────────────────────────────────────────
* DMT_Line__c Trigger Handler
* ────────────────────────────────────────────────────────────────────
* @author     Francisco José Díaz Ramírez
* @modifiedBy
* @version     1.0
* @created     2025-01-31
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class DMT_Product_TriggerHandler extends DMT_TriggerHandler {

    private List<Product2> lstNew;
    private Map<Id,Product2> mapNew;
    private Map<Id,Product2> mapOld;

    public DMT_Product_TriggerHandler(){
        this.lstNew=(List<Product2>) Trigger.new;
        this.mapNew=(Map<Id,Product2>) Trigger.newmap;
        this.mapOld=(Map<Id,Product2>) Trigger.oldmap;
    }

    public override void beforeInsert() {
        DMT_Product_Helper productHelper = new DMT_Product_Helper();
        productHelper.completeFields(lstNew);
    }

    public override void beforeUpdate()
    {
        DMT_Product_Helper productHelper = new DMT_Product_Helper();
        productHelper.completeFields(lstNew);
    }

         public override void afterInsert() {
         DMT_Product_Helper productHelper = new DMT_Product_Helper();
         productHelper.createPriceBookEntry(lstNew);
     }

   
}