/**
* ────────────────────────────────────────────────────────────────────
* Profitability Analysis Trigger Handler
*
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-07-09
* @modified
* @systemLayer Trigger
* ────────────────────────────────────────────────────────────────────
* @changes
* 2022-06-22 - torcuato - transform segment picklist values 01, 02, 03 to BEC, PYMES, CIB
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class ProfitabilitySheetTriggerHandler {

    private static ProfitabilitySheetTriggerHandler instance;

    public static ProfitabilitySheetTriggerHandler getInstance() {
        if (instance == null) {
            instance = new ProfitabilitySheetTriggerHandler();
        }
        return instance;
    }

    public void beforeInsert(List<cuco__profitability_sheet__c> triggerNew) {
        final List<User> userList = [SELECT Id, Id_User__c, isActive FROM USER WHERE isActive = true];
        final Map<String,User> userMap = new Map<String,User>();
        for (user userToMap : userList) {
            userMap.put(userToMap.Id_User__c,userToMap);
        }
        for (cuco__profitability_sheet__c pSheet : triggerNew) {
            if (pSheet.apply_cond_ind_type__c == 'S') {
                pSheet.cuco__gf_all_ct_apply_cond_ind_type__c = true;
            }
            if (pSheet.apply_cond_ind_type__c == 'N') {
                pSheet.cuco__gf_all_ct_apply_cond_ind_type__c =  false;
            }
            switch on pSheet.cuco__gf_prftbly_sheet_seg_type_name__c {
                when '01' {
                    pSheet.cuco__gf_prftbly_sheet_seg_type_name__c = 'BEC';
                }
                when '02' {
                    pSheet.cuco__gf_prftbly_sheet_seg_type_name__c = 'PYMES';
                }
                when else {
                    pSheet.cuco__gf_prftbly_sheet_seg_type_name__c = 'CIB';
                }
            }
            if (!userMap.containsKey(pSheet.OwnerId) && userMap.containsKey(System.Label.DefaultOwnerPricingConditionBook)) {
                pSheet.OwnerId = userMap.get(System.Label.DefaultOwnerPricingConditionBook).Id;
            }
        }
    }

    public void beforeUpdate(Map<Id, cuco__profitability_sheet__c> newMap, Map<Id, cuco__profitability_sheet__c> oldMap) {
        final List<User> userList = [SELECT Id, Id_User__c, isActive FROM USER WHERE isActive = true];
        final Map<String,User> userMap = new Map<String,User>();
        for (user userToMap : userList) {
            userMap.put(userToMap.Id_User__c,userToMap);
        }
        for (Id key : oldMap.keySet()) {
            cuco__profitability_sheet__c upd = newMap.get(key);
            cuco__profitability_sheet__c old = oldMap.get(key);
            if (upd.apply_cond_ind_type__c != old.apply_cond_ind_type__c) {
                if (upd.apply_cond_ind_type__c == 'S') {
                    upd.cuco__gf_all_ct_apply_cond_ind_type__c = true;
                }
                if (upd.apply_cond_ind_type__c == 'N') {
                    upd.cuco__gf_all_ct_apply_cond_ind_type__c = false;
                }
            }
            if (upd.cuco__gf_prftbly_sheet_seg_type_name__c != old.cuco__gf_prftbly_sheet_seg_type_name__c) {
                switch on upd.cuco__gf_prftbly_sheet_seg_type_name__c {
                    when '01' {
                        upd.cuco__gf_prftbly_sheet_seg_type_name__c = 'BEC';
                    }
                    when '02' {
                        upd.cuco__gf_prftbly_sheet_seg_type_name__c = 'PYMES';
                    }
                    when else {
                        upd.cuco__gf_prftbly_sheet_seg_type_name__c = 'CIB';
                    }
                }
            }
            if (!userMap.containsKey(upd.OwnerId)) {
                upd.OwnerId = old.OwnerId;
            }
        }
    }
}