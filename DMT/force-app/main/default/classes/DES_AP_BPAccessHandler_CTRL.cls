/**
* Global Desktop
*/
public with sharing class DES_AP_BPAccessHandler_CTRL {
    /**
    * Checks if user has access or not
    */
    @AuraEnabled
    public static Boolean userHasAccess(Id accountplanid) {
        Boolean result;
        System.debug('accountplanid : '+accountplanid);
        final List<bupl__AP_Team__c> apTeamMembers = [select Id from bupl__AP_Team__c where acpl__gf_account_planning_id__c = :accountplanid and bupl__gf_ap_team_user_id__c = :UserInfo.getUserId()];
        final Boolean userismember = !apTeamMembers.isEmpty();
        System.debug('userismember : '+userismember);
        final bupl__BusinessPlan__c businessplan = [select Id, bupl__gf_ap_public_ind_type__c from bupl__BusinessPlan__c where acpl__gf_account_planning_id__c = :accountplanid][0];
        System.debug('businessplan : '+businessplan);
        final Boolean bpVisibility = businessplan != null && businessplan.bupl__gf_ap_public_ind_type__c;
        System.debug('bpVisibility : '+bpVisibility);
        result = bpVisibility || (!bpVisibility && userismember);
        System.debug('result : '+result);
        return result;
    }
    
    /**
    * Checks if user has edit permission or not
    */
    @AuraEnabled
    public static Boolean userHasEditPermission(Id accountplanid, String bpVersionId) {
        Boolean result;
        System.debug('accountplanid : '+accountplanid);
        final acpl__Account_Planning__c accountplan = [select Id, acpl__gf_ap_indvi_lock_edit_ind_type__c from acpl__Account_Planning__c where Id = :accountplanid][0];
        System.debug('accountplan : '+accountplan);
        final Boolean accountplanopen = accountplan.acpl__gf_ap_indvi_lock_edit_ind_type__c;
        System.debug('accountplanopen : '+accountplanopen);
        final List<bupl__AP_Team__c> apTeamMembers = [select Id from bupl__AP_Team__c where acpl__gf_account_planning_id__c = :accountplanid and bupl__gf_ap_team_user_id__c = :UserInfo.getUserId()];
        System.debug('apTeamMembers : '+apTeamMembers);
        final Boolean userismember = !apTeamMembers.isEmpty();
        System.debug('userismember : '+userismember);
        
        Boolean draftVersion = false;
        bupl__BusinessPlan_Version__c bpVersion;
        bpVersion = new bupl__BusinessPlan_Version__c();
        if(bpVersionId == '' || bpVersionId == null) {
            bpVersion = [SELECT Id, Name, bupl__gf_bus_pl_lst_vldt_vr_ind_type__c FROM bupl__BusinessPlan_Version__c 
                         WHERE bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :accountplanid AND bupl__gf_business_plan_act_ind_type__c = 'Yes' LIMIT 1];
            if(!bpVersion.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c) {
                draftVersion = true;
            }
        } else {
            bpVersion = [SELECT Id,Name, bupl__gf_business_plan_act_ind_type__c, bupl__gf_bus_pl_lst_vldt_vr_ind_type__c FROM bupl__BusinessPlan_Version__c WHERE Id = :bpVersionId];
            if(!bpVersion.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c && bpVersion.bupl__gf_business_plan_act_ind_type__c == 'Yes') {
                draftVersion = true;
            }
        }
        System.debug('bpVersion : '+result);
        System.debug('draftVersion : '+draftVersion);
        result = accountplanopen && userismember && draftVersion;
        System.debug('result : '+result);
        return result;
    }
  
  @AuraEnabled
  public static List<String> getCountriesBP(String recordId, Boolean lastValidatedV) { //NOSONAR
    final List<String> sections = new List<String>();
    final Id parentId = recordId;
    final String parentObjectName = parentId.getSObjectType().getDescribe().getName();
   /*  String businessPlanVersionIdQuery=[Select bupl__gf_business_plan_version_id__c  from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :recordId LIMIT 1]; //Query a lanzar sobre el objeto en el que se visualiza el componente para sacar el objeto del que saquen los hijos enlazados
    System.debug('La query sobre el businessplanID : '+businessPlanVersionIdQuery); */

    final List<SObject> parent =[Select bupl__gf_business_plan_version_id__c  from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :recordId LIMIT 1]; //Query a lanzar sobre el objeto en el que se visualiza el componente para sacar el objeto del que saquen los hijos enlazados

    final String bpVersionId = (Id) parent[0].get('bupl__gf_business_plan_version_id__c').toString();
    /* String childrenquery; //Query sobre los hijos filtrada por el registro padre del registro en el que se situa el componente
    childrenquery = ' select bupl__gf_booking_operation_cntry_id__c from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c ';
    childrenquery += '= \''+recordId+'\''; */
    List<AggregateResult> childrenAgregate = new List<AggregateResult>();
      if(lastValidatedV) {
          childrenAgregate=[select bupl__gf_booking_operation_cntry_id__c from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :recordId AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c  = true GROUP BY bupl__gf_booking_operation_cntry_id__c];
      } else {
          if(bpVersionId == '' || bpVersionId == null) {
              childrenAgregate =[select bupl__gf_booking_operation_cntry_id__c from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :recordId AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c ='Yes' GROUP BY bupl__gf_booking_operation_cntry_id__c ];
          } else {
              childrenAgregate =[select bupl__gf_booking_operation_cntry_id__c from bupl__BusinessPlan_Item__c where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :recordId AND bupl__gf_business_plan_version_id__c  = :bpVersionId GROUP BY bupl__gf_booking_operation_cntry_id__c];
          }
      }
    //childrenquery += ' GROUP BY bupl__gf_booking_operation_cntry_id__c';
    System.debug('La query sobre los hijos queda : '+childrenAgregate);
    for(AggregateResult section : childrenAgregate) { //NOSONAR
      sections.add((String) section.get('bupl__gf_booking_operation_cntry_id__c'));
    }
    return sections;
  }
}