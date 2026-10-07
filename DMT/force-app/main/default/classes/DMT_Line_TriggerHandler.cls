/**
* ────────────────────────────────────────────────────────────────────
* DMT_Line__c Trigger Handler
* ────────────────────────────────────────────────────────────────────
* @author     torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2024-07-29
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public without sharing class DMT_Line_TriggerHandler extends DMT_TriggerHandler {

    private List<DMT_Line__c> lstNew;
    private Map<Id,DMT_Line__c> mapNew;
    private Map<Id,DMT_Line__c> mapOld;

    public DMT_Line_TriggerHandler(){
        this.lstNew=(List<DMT_Line__c>) Trigger.new;
        this.mapNew=(Map<Id,DMT_Line__c>) Trigger.newmap;
        this.mapOld=(Map<Id,DMT_Line__c>) Trigger.oldmap;
    }
    // public override void afterInsert() {
    //      for(DMT_Line__c line : (List<DMT_Line__c>) Trigger.new) {
    //           getOppCode(line.Id);
    //       }
    //     DMT_Line_Helper lineHelper = new DMT_Line_Helper();
    //     lineHelper.createConsolidatedLine(lstNew,mapNew,mapOld);
    //   }

    public override void afterUpdate() {
        System.debug('DMT_Line_TriggerHandler afterUpdate');
        DMT_Line_Helper lineHelper = new DMT_Line_Helper();
        System.debug('entering createConsolidatedLine');
        lineHelper.createConsolidatedLine(lstNew, mapNew, mapOld);
        System.debug('entering closeFather');
        lineHelper.closeFather(lstNew, mapOld);
        System.debug('entering createLineVersionSnapshot');
        lineHelper.createLineVersionSnapshot(lstNew, mapOld);
        lineHelper.syncCustomAssociationName(lstNew);
        lineHelper.handleCancelChange(lstNew, mapOld);
        lineHelper.updatePassport_LineStatusChanged(lstNew, mapOld);
        lineHelper.enqueueRecalculateApprovals(lstNew, mapOld);


        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(lstNew, mapOld);
        DMT_CloseWonNotificationService.sendDraftLineNotifications(lstNew, mapOld);

        //after all after update methods
        DMT_AsyncOrchestrator.flush();
    }

    public override void beforeUpdate() {
        System.debug('DMT_Line_TriggerHandler beforeUpdate');
        DMT_Line_Helper lineHelper = new DMT_Line_Helper();
        lineHelper.avoidPassingApproval(lstNew, mapOld, Trigger.size);
        lineHelper.blockReadyToCloseWithProspectInMultiholder(lstNew, mapOld);
        lineHelper.fillFields(lstNew, mapOld);
        lineHelper.updateLastModifiedByHuman(lstNew);
        lineHelper.updateStartDateOnClosedWon(lstNew, mapOld);
        lineHelper.validateRiskLineTermContinuity(lstNew, mapOld);
        lineHelper.setDestinationSystemOnClosedWon(lstNew, mapOld);
        lineHelper.syncApprovalTermAndEndDate(lstNew, mapOld);
    }

    public override void beforeInsert() {
        System.debug('DMT_Line_TriggerHandler beforeInsert');
        DMT_Line_Helper lineHelper = new DMT_Line_Helper();
        lineHelper.fillFields(lstNew);
        lineHelper.syncApprovalTermAndEndDate(lstNew, null);
    }

    // @Future (callout=true)
    // private static void getOppCode(String lineId) {
    //     DMT_Line__c line = [SELECT DMT_Client_Entific__c from DMT_Line__c WHERE Id =: lineId];
    //     Map<String, Object> request = new Map<String, Object>();
    //     request.put('origin', 'KDCO');
    //     request.put('operationType', 'OPP');
    //     request.put('entific', line.DMT_Client_Entific__c);
    //     DMT_OpportunityCodes.Wrapper oppCode = DMT_OpportunityCodes.getOpportunityCode(request);
    //     if (oppCode.success) {
    //         line.Line_Id__c = oppCode.data.opportunityId;
    //         update line;
    //     } else {
    //         system.debug('ERROR obtaining Line Id: ' + oppCode.errorMessage);
    //     }
    // }
}