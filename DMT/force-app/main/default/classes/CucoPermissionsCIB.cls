/**
* ____________________________________________________________________________
* profitabilityAnalysis Permissions Sample
* Sample implementation of the interface Permissions_itf to determine
* whether the user can perform the different typologies of profitability
* analysis: create, edit and delete.
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-02-04
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf.TooManyFields, sf:TooManyMethods')
global with sharing class CucoPermissionsCIB implements cuco.Permissions_itf {

    /**
    * @description Returns user permissions to manage conditions in the specified Profitability Ananlysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Boolean> canManageConditions(Id profAnalysisId, Id userId) {

        final Set<Id> ids = new Set<Id>{profAnalysisId};
        final Map<String, Boolean> res = new Map<String, Boolean>();
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
        Boolean canAdd = false;
        Boolean canEdit = false;
        Boolean canRemove = false;
        Boolean isCucoUser = isCucoUser(userId);

        final cuco.ProfitabilityAnalysis_Selector selector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> pa = selector.selectById(ids);

        if (isCucoUser && pa.size() > 0) {
            canAdd = validStatus.indexOf(pa[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  pa[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
        canEdit = canAdd;
        canRemove = canAdd;

        res.put('add', canAdd);
        res.put('edit', canEdit);
        res.put('remove', canRemove);

        return res;
    }

    /**
    * @description Returns whether the user can add conditions in the Profitability Ananlysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canAddConditions(Id profAnalysisId, Id userId) {

        final Set<Id> ids = new Set<Id>{profAnalysisId};
        final Map<String, Object> res = new Map<String, Object>();
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
        Boolean canAdd = false;
        Boolean isCucoUser = isCucoUser(userId);

        final cuco.ProfitabilityAnalysis_Selector selector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> pa = selector.selectById(ids);

        if (isCucoUser && pa.size() > 0) {
            canAdd = validStatus.indexOf(pa[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  pa[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
        res.put('add', canAdd);

        if (!canAdd) {
            res.put('addMessage', Label.cuco.add_cond_perm_error_sample);
        }

        return res;
    }

    /**
    * @description Returns whether the user can edit a family of conditions in the Profitability Ananlysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param familyId : Id of the Family
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canEditConditions(Id profAnalysisId, Id userId, Id familyId) {

        final Set<Id> ids = new Set<Id>{profAnalysisId};
        final Map<String, Object> res = new Map<String, Object>();
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
        Boolean canEdit = false;
        Boolean isCucoUser = isCucoUser(userId);

        final cuco.ProfitabilityAnalysis_Selector selector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> pa = selector.selectById(ids);

        if (isCucoUser && pa.size() > 0) {
            canEdit = validStatus.indexOf(pa[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  pa[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
        res.put('edit', canEdit);

        if (!canEdit) {
            res.put('editMessage', Label.cuco.edit_cond_perm_error_sample);
        }

        return res;
    }

    /**
    * @description Returns whether the user can remove a specific condition in the Profitability Ananlysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param conditionId : Id of the Condition
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canRemoveCondition(Id profAnalysisId, Id userId, Id paConditionId) {

        final Set<Id> ids = new Set<Id>{profAnalysisId};
        final Map<String, Object> res = new Map<String, Object>();
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
        Boolean canRemove = false;
        Boolean isCucoUser = isCucoUser(userId);

        final cuco.ProfitabilityAnalysis_Selector selector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> pa = selector.selectById(ids);

        if (isCucoUser && pa.size() > 0) {
            canRemove = validStatus.indexOf(pa[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  pa[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
        res.put('remove', canRemove);

        if (!canRemove) {
            res.put('removeMessage', Label.cuco.remove_cond_perm_error_sample);
        }

        return res;
    }

    /**
    * @description Returns whether the user has available the specific actions Add/Remove on a Profitability Analysis record
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canManageParticipants(Id profAnalysisId, Id userId) {

        final Set<Id> setIdsCanManage = new Set<Id>{profAnalysisId};
        final Map<String, Object> retMapCanManage = new Map<String, Object>();
        final List<String> lstValidStatusManage = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
        Boolean canAddManage = false;
        Boolean canRemoveManage = false;
        Boolean extraActions = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelectorManage = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPAManage = paSelectorManage.selectById(setIdsCanManage);
            if (!lstPAManage.isEmpty()) {
                canAddManage = lstValidStatusManage.indexOf(lstPAManage[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  lstPAManage[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }
        canRemoveManage = canAddManage;
        extraActions = canAddManage;

        retMapCanManage.put('add', canAddManage);
        retMapCanManage.put('remove', canRemoveManage);
        retMapCanManage.put('extraActions', extraActions);

        return retMapCanManage;
    }

    /**
    * @description Returns whether the user can use the specific action Add on a Profitability Analysis record
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canAddParticipants(Id profAnalysisId, Id userId) {

      final Set<Id> setIdsAdd = new Set<Id>{profAnalysisId};
      final Map<String, Object> retMapAdd = new Map<String, Object>();
      final List<String> lstValidStatusAdd = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
      Boolean canAdd = false;
      Boolean isCucoUser = isCucoUser(userId);

      if (isCucoUser) {
        final cuco.ProfitabilityAnalysis_Selector paSelectorAdd = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPAAdd = paSelectorAdd.selectById(setIdsAdd);
        if (!lstPAAdd.isEmpty()) {
            canAdd = lstValidStatusAdd.indexOf(lstPAAdd[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  lstPAAdd[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
      }

      retMapAdd.put('add', canAdd);

      if (!canAdd) {
        retMapAdd.put('addMessage', Label.cuco.add_subs_perm_error_sample);
      }

      return retMapAdd;
    }

    /**
    * @description Returns whether the user can use the specific action Remove on a Profitability Analysis record
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param accountId : Id of the Account
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canRemoveParticipant(Id profAnalysisId, Id userId, Id accountId) {

      final Set<Id> setIdsRemove = new Set<Id>{profAnalysisId};
      final Map<String, Object> retMapRemove = new Map<String, Object>();
      final List<String> lstValidStatusRemove = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
      Boolean canRemove = false;
      Boolean isCucoUser = isCucoUser(userId);

      if (isCucoUser) {
        final cuco.ProfitabilityAnalysis_Selector paSelectorRemove = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPARemove = paSelectorRemove.selectById(setIdsRemove);
        if (lstPARemove.size() > 0) {
            canRemove = lstValidStatusRemove.indexOf(lstPARemove[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 &&  lstPARemove[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
        }
      }

      retMapRemove.put('remove', canRemove);

      if (!canRemove) {
        retMapRemove.put('removeMessage', Label.cuco.remove_subs_perm_error_sample);
      }

      return retMapRemove;
    }

    /**
    * @description Returns whether the user can create a specific condition in the Profitability Ananlysis
    * @param accountId : Id of the Account
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canCreateNewPA(Id accountId, Id userId) {

        final Map<String, Object> res = new Map<String, Object>();

        //PERMITIR TODOS
        Boolean canCreate = true;
        Boolean isCucoUser = isCucoUser(userId);
        canCreate = isCucoUser;

        // LIMIT TO OWNER OF THE ACCOUNT/GROUP
        // final List<Account> lstAcc = [SELECT Id, OwnerId, parentId FROM Account WHERE Id = :accountId];
        // final cuco.ParticipantHierarchy_Wrapper resPartHierarchy = new CucoParticipantCIB().getParticipantHierarchy(accountId);
        //
        //final String participantType = resPartHierarchy.type;
        //if (isCucoUser && (participantType == 'group' || participantType == 'orphan')) {
        //    if (lstAcc[0].OwnerId == userId) {
        //        canCreate = true;
        //    }
        //}
        //if (isCucoUser && participantType == 'subsidiary') {
        //    final List<Account> lstAccParent = [SELECT Id, OwnerId FROM Account WHERE parentId = :lstAcc[0].parentId];
        //    if (lstAccParent[0].OwnerId == userId) {
        //        canCreate = true;
        //    }
        //}

        res.put('create', canCreate);
        if (!canCreate) {
            res.put('createMessage', Label.cuco.creation_perm_error_sample);
        }
        return res;
    }

    /**
    * @description Returns user permissions to manage package in the specified Profitability Analysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canManagePackages(Id profAnalysisId, Id userId) {
        final Map<String, Object> retMapManagePkg = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};

        Boolean canAddManagePkg = false;
        Boolean canEditManagePkg = false;
        Boolean canCancelManagePkg = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                canAddManagePkg = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        canEditManagePkg = canAddManagePkg;
        canCancelManagePkg = canAddManagePkg;

        retMapManagePkg.put('add', canAddManagePkg);
        retMapManagePkg.put('edit', canEditManagePkg);
        retMapManagePkg.put('cancel', canCancelManagePkg);

        return retMapManagePkg;
    }

    /**
    * @description Returns whether the user can add a package to a Profitability Analysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param pkgType : String with the pkg type to be added
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canAddPackage(Id profAnalysisId, Id userId, String pkgType) {
        final Map<String, Object> retMapAddPkg = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};

        Boolean canAddPkg = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                canAddPkg = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapAddPkg.put('add', canAddPkg);

        if (!canAddPkg) {
            retMapAddPkg.put('addMessage', Label.cuco.pkg_add_perm_error_sample);
        }
        return retMapAddPkg;
    }

    /**
    * @description Returns whether the user can edit a package from a Profitability Analysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param package : Wrapper with package values to edit
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canEditPackage(Id profAnalysisId, Id userId, cuco.Package_Wrapper packageWrapper) {
        final Map<String, Object> retMapEditPkg = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};

        Boolean canEditPkg = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                canEditPkg = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapEditPkg.put('edit', canEditPkg);

        if (!canEditPkg) {
            retMapEditPkg.put('editMessage', Label.cuco.pkg_edit_perm_error_sample);
        }

        return retMapEditPkg;
    }

    /**
    * @description Returns whether the user can cancel a package from a Profitability Analysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @param package : Wrapper with package values to cancel
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canCancelPackage(Id profAnalysisId, Id userId, cuco.Package_Wrapper packageWrapper) {
        final Map<String, Object> retMapCancelPkg = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};
        final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};

        Boolean canCancelPkg = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                canCancelPkg = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapCancelPkg.put('cancel', canCancelPkg);

        if (!canCancelPkg) {
            retMapCancelPkg.put('cancelMessage', Label.cuco.pkg_cancel_perm_error_sample);
        }

        return retMapCancelPkg;
    }
    /**
    * @description Returns whether the user can manage a Profitability Analysis
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canManageAnalysis(Id profAnalysisId, Id userId) {
        final Map<String, Object> retMapManAnalysis= new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};

        Boolean canManageAnalys = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
                retMapManAnalysis.put('profAnalys', lstPA[0]);
                canManageAnalys = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapManAnalysis.put('manage', canManageAnalys);

        if (!canManageAnalys) {
            retMapManAnalysis.put('manageMessage', Label.cuco.manage_analysis_perm_error_sample);
        }

        return retMapManAnalysis;
    }
    /**
    * @description Returns whether the user can create requests for a Profitability Analysis
    * @param profAnalysisId : Wrapper with Profitability information
    * @param userId : Id of the User
    * @param typology : typology of profSheet
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canCreateRequestPA(cuco.ProfitabilitySheet_Wrapper profSheet, Id userId, String typology) {

        final Map<String, Object> retMapCrReq= new Map<String, Object>();
        Boolean canCreateRequest = false;
        Boolean isCucoUser = isCucoUser(userId);

        if(isCucoUser) {
            canCreateRequest = true;
            retMapCrReq.put('canCreate',canCreateRequest);
        } else {
            if(typology == 'Renewal') {
                retMapCrReq.put('message', Label.cuco.creation_perm_error_sample);
            } else if(typology == 'Novation') {
                retMapCrReq.put('message', Label.cuco.novation_perm_error_sample);
            } else if(typology == 'Cancellation') {
                retMapCrReq.put('message', Label.cuco.cancellation_perm_error_sample);
            }
        }
        return retMapCrReq;
    }

    /**
    * @description Returns whether the user can manage a Flat Rates
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canManageFlatRates(Id profAnalysisId, Id userId) {
        final Map<String, Object> retMapManageFlatRates = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};

        Boolean canManageFlatRates = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
                canManageFlatRates = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapManageFlatRates.put('setup', canManageFlatRates);
        retMapManageFlatRates.put('remove', canManageFlatRates);
        return retMapManageFlatRates;
    }

    /**
    * @description Returns whether the user can setup a flat rates
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canSetupFlatRates(Id profAnalysisId, Id userId) {
        final Map<String, Object> retMapSetupFlatRates = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};

        Boolean canSetupFlatRates  = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
                canSetupFlatRates  = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapSetupFlatRates.put('setup', canSetupFlatRates);

        if(!canSetupFlatRates){
            retMapSetupFlatRates.put('setupMessage', Label.cuco.setup_fr_perm_error_sample);
        }

        return retMapSetupFlatRates;
    }

    /**
    * @description Returns whether the user can remove a Flat Rate
    * @param profAnalysisId : Id of the Profitability Analysis
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canRemoveFlatRates(Id profAnalysisId, Id userId) {
        final Map<String, Object> retMapRemoveFlatRates = new Map<String, Object>();
        final Set<Id> setProfAnId = new Set<Id>{profAnalysisId};

        Boolean canRemoveFlatRates  = false;
        Boolean isCucoUser = isCucoUser(userId);

        if (isCucoUser) {
            final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
            final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setProfAnId);
            if (!lstPA.isEmpty()) {
                final List<String> validStatus = new List<String>{'Analysis', 'Restudy', 'Sent for Price Approval', 'Sent for Price Approval Top'};
                canRemoveFlatRates  = validStatus.indexOf(lstPA[0].cuco__gf_pa_mgmt_status_type_name__c) > -1 && lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation';
            }
        }

        retMapRemoveFlatRates.put('remove', canRemoveFlatRates);

        if(!canRemoveFlatRates){
            retMapRemoveFlatRates.put('removeMessage', Label.cuco.remove_fr_perm_error_sample);
        }

        return retMapRemoveFlatRates;
    }

    public Boolean isCucoUser(Id userId) {
        Boolean res = [SELECT gf_manage_cuco__c FROM User WHERE Id =:userId LIMIT 1].gf_manage_cuco__c;
        return res;
    }

    /**
    * @description Returns whether the user can discard a Sheet
    * @param profSheet : Sheet wrapper
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String,Object> canDiscardExpiredPS(cuco.ProfitabilitySheet_Wrapper wrapper, Id userId) {
        final Map<String, Object> retMap = new Map<String, Object>();
        Boolean isCucoUser = isCucoUser(userId);
        if (isCucoUser) {
            retMap.put('canDiscard', true);
        } else {
            retMap.put('canDiscard', false);
            retMap.put('discardMessage', Label.cuco.discard_renewal_perm_error_sample);
        }
        return retMap;
    }

    /**
    * @description Returns whether the user can modify a sheet
    * @param profSheet : Sheet wrapper
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String,Object> canModifyPSData(cuco.ProfitabilitySheet_Wrapper profSheet, Id userId) {
        final Map<String, Object> retMap = new Map<String, Object>();
        final cuco__profitability_sheet__c pS = [SELECT ownerId FROM cuco__profitability_sheet__c WHERE Id =:profSheet.Id LIMIT 1];
        if (pS.OwnerId == userId) {
            retMap.put('canModifyPS', true);
        } else {
            retMap.put('canModifyPS', false);
            retMap.put('modifyMessage', Label.cuco.modify_notebook_error_sample);
        }

        return retMap;
    }

    /**
    * @description Returns whether the user can clone a sheet
    * @param sourcePSId : PS origin Id
    * @param userId : Id of the User
    * @return Map<String, Object> map with the actions and permissions
    */
    global Map<String, Object> canClonePre(Id sourcePSId, Id userId) {
        final Map<String, Object> retMapClone = new Map<String, Object>();
        final cuco.ProfitabilitySheet_Selector profSheetSelector = new cuco.ProfitabilitySheet_Selector(false);
        final List<cuco__profitability_sheet__c> lstClonePS = profSheetSelector.selectById(new Set<Id>{sourcePSId});
        if (lstClonePS.isEmpty()) {
            retMapClone.put('canClone', false);
            retMapClone.put('cloneMessage', Label.cuco.clone_pre_perm_error_sample);
        } else {
            retMapClone.put('canClone', true);
        }
        return retMapClone;
    }

    /**
    * @description Returns whether the user can clone a sheet
    * @param cloneSelectionMap : Map with accountId key
    * @param userId : Id of the User
    * @return Map<String, Object> map with result
    */
    global Map<String,Object> canClonePost(Map<String,Object> cloneSelectionMap, Id userId) {
        boolean canClone = true;
        final Map<String, Object> retMap = new Map<String, Object>();
        if (cloneSelectionMap.get('accountId') == null) {
            canClone = false;
        } else {
            final List<Account> listAcc = [SELECT Id, ParentId, DES_Client_Type__c FROM Account WHERE Id =: (Id)cloneSelectionMap.get('accountId') LIMIT 1];
            if (listAcc.isEmpty() || !(String.isBlank(listAcc[0].ParentId)) || listAcc[0].DES_Client_Type__c == 'Subsidiary') {
                canClone = false;
            }
        }
        retMap.put('canClone', canClone);
        if (!canClone) {
            retMap.put('cloneMessage', Label.cuco_clone_error);
        }
        return retMap;
    }
}