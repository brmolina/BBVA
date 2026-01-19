/*----------------------------------------------------------------------------------------------
    Description:    Creacion de datos dummy para los Tests de los desarrollos de Desktop.

    History:
    <Date>          <Author>                <Description>
    01/08/2018
-----------------------------------------------------------------------------------------------*/
public with sharing class DES_UtilTestClassAux {
    
    /**
    * Business Plan record
    */
    public bupl__BusinessPlan__c createBusinessPlan(acpl__Account_Planning__c accountPlanning, Account account) {
        final bupl__BusinessPlan__c businessPlan = new bupl__BusinessPlan__c();
        businessPlan.Name = 'Business Plan';
        businessPlan.acpl__gf_account_planning_id__c = accountPlanning.Id;
        businessPlan.bupl__gf_ap_public_ind_type__c = true;
        businessPlan.bupl__participant_id__c = account.Id;
        return businessPlan;
    }
    
    /**
  * Business Plan Version record
  */
  public bupl__BusinessPlan_Version__c createBusinessPlanVersion(bupl__BusinessPlan__c businessPlan) {
    final bupl__BusinessPlan_Version__c  bpVersion = new bupl__BusinessPlan_Version__c ();
    bpVersion.Name = 'Business Plan Version';
    bpVersion.bupl__gf_business_plan_id__c = businessPlan.Id;
    bpVersion.bupl__gf_business_plan_act_ind_type__c = Label.acpl.Yes;
    return bpVersion;
  }

  /**
  * Business Plan Item normal record
  */
  public bupl__BusinessPlan_Item__c createBusinessPlanItemNormal(bupl__BusinessPlan_Version__c bpVersion) {
    final bupl__BusinessPlan_Item__c bpItem = new bupl__BusinessPlan_Item__c();
    bpItem.bupl__gf_cross_border_rev_ind_type__c = Label.acpl.No;
    bpItem.bupl__gf_cross_sell_rev_ind_type__c = Label.acpl.No;
    return createBusinessPlanItem(bpItem,bpVersion);
  }

  /**
  * Business Plan Item cross-sell record
  */
  public bupl__BusinessPlan_Item__c createBusinessPlanItemXSell(bupl__BusinessPlan_Version__c bpVersion) {
    final bupl__BusinessPlan_Item__c bpItem = new bupl__BusinessPlan_Item__c();
    bpItem.bupl__gf_cross_border_rev_ind_type__c = Label.acpl.Yes;
    bpItem.bupl__gf_cross_sell_rev_ind_type__c = Label.acpl.Yes;
    return createBusinessPlanItem(bpItem,bpVersion);
  }

  /**
  * Business Plan Item record
  */
  public bupl__BusinessPlan_Item__c createBusinessPlanItem(bupl__BusinessPlan_Item__c bpItem, bupl__BusinessPlan_Version__c bpVersion) {
    bpItem.CurrencyIsoCode = 'EUR';
    bpItem.bupl__gf_business_plan_version_id__c = bpVersion.Id;
    bpItem.bupl__gf_booking_operation_cntry_id__c = 'Spain';
    bpItem.bupl__solution_category_id__c = 'GTB';
    bpItem.bupl__annual_expect_profit_py_amount__c = 2481512;
    bpItem.bupl__customer_open_oppy_amount__c = 2637166;
    bpItem.bupl__expected_revenue_amount__c = 2267649;
    bpItem.bupl__gf_total_revenues_ytd_amount__c = 666946;
    bpItem.bupl__pre_expct_prft_next_12m_amount__c = 3147074;
    bpItem.bupl__total_revenues_py_amount__c = 1176623;
    bpItem.bupl__gf_business_plan_vldt_ind_type__c = true;
    bpItem.bupl__solution_category_desc__c = 'Cash Management';
    return bpItem;
  }
    
    /**
    * Commercial Plan record
    */
    public acpl__Commercial_Plan_Event__c createCommercialPlanEvent(acpl__Account_Planning__c accountPlanning, Account account) {
        final acpl__Commercial_Plan_Event__c commPlanEvent = new acpl__Commercial_Plan_Event__c();
        commPlanEvent.Name = 'Commercial Plan Event Visit';
        commPlanEvent.acpl__gf_account_planning_id__c = accountPlanning.Id;
        commPlanEvent.acpl__gf_comm_plan_event_type_name__c = 'Visit';
        commPlanEvent.acpl__participant_id__c = account.Id;
        commPlanEvent.acpl__gf_event_date__c = Date.Today();
        commPlanEvent.gf_plan_event_xbrdr_ind_type__c = 'Yes';
        return commPlanEvent;
    }
    
    /**
    * Need record
    */
    public bupl__BP_Need__c createNeed(acpl__Account_Planning__c accountPlanning, bupl__BusinessPlan__c businessPlan) {
        final bupl__BP_Need__c need = new bupl__BP_Need__c();
        need.acpl__gf_account_planning_id__c = accountPlanning.Id;
        need.bupl__gf_business_plan_id__c = businessPlan.Id;
        return need;
    }
    
    /**
    * Growth Driver record
    */
    public bupl__BP_GrowthDriver__c createGrowthDriver(acpl__Account_Planning__c accountPlanning, bupl__BusinessPlan__c businessPlan) {
        final bupl__BP_GrowthDriver__c growthDriver = new bupl__BP_GrowthDriver__c();
        growthDriver.acpl__gf_account_planning_id__c = accountPlanning.Id;
        growthDriver.bupl__gf_business_plan_id__c = businessPlan.Id;
        return growthDriver;
    }
    
    /**
    * Growth Driver record
    */
    public DES_Group_Analysis__c createGroupAnalysis(acpl__Account_Planning__c accountPlanning, Account account) {
        final DES_Group_Analysis__c groupAnalysis = new DES_Group_Analysis__c();
        groupAnalysis.gf_account_planning_id__c = accountPlanning.Id;
        groupAnalysis.participant_id__c = account.Id;
        return groupAnalysis;
    }
}