/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsCancel_Service
* @Author         marcos.gimeno.contractor@bbva.com
* @Date           25-05-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for cancel rating operations.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.contractor@bbva.com
* 25-05-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_IFIS_ButtonsCancel_Service {
    /** @description Cancelled status string**/
    private static final String STATUS_CANCELLED = '14';
    /** @description Cancelled stage string**/ 
    private static final String STAGE_CLOSED = '3';
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Empty constructor to avoid sonar warnings.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_IFIS_ButtonsCancel_Service() {
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Executes the logic related to the cancellation process.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * @param    ahaId          ID of the Account_has_Analysis__c record
    * @param    reasonValue    Reason for cancellation
    * @param    reasonLabel    Reason label for cancellation
    * @param    reasonDesc     Reason description for cancellation
    * @return   Database update save result
    * @example  arce.Arc_Gen_RatingGlobal_data.SaveResult e = toCancel(ahaId, reasonValue, reasonDesc)
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static arce.Arc_Gen_RatingGlobal_data.SaveResult toCancel(
        Id ahaId,
        String reasonValue,
        String reasonLabel,
        String reasonDesc
    ) {
        final arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();

        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
        final arce__Analysis__c analysisToUpd = setAnalysisValues(analysis, reasonValue, reasonDesc);
        final arce.Arc_Gen_RatingGlobal_data.SaveResult response = locator.updateRecords(
            new List<sObject>{ analysisToUpd }
        );

        if (response.status == 'true') {
            Arc_IFIS_Buttons_Helper.sendNotifications(analysis.Id, System.Label.arce.Arc_IFIS_BtnCancel_Notification);
            setTraceability(analysis.Id, reasonLabel, reasonDesc);
        }

        return response;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets the arce__Analysis__c with the new values of the propose.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysis       Analysis__c record
    * @param    reasonValue    Reason for cancellation
    * @param    reasonDesc     Reason description for cancellation
    * @return   arce__Analysis__c object with new values
    * @example  arce__Analysis__c e = setAnalysisValues(analysis, userId, selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    private static arce__Analysis__c setAnalysisValues(
        arce__Analysis__c analysis,
        String reasonValue,
        String reasonDesc
    ) {
        final arce__Analysis__c analysisToUpd = new arce__Analysis__c(Id = analysis.Id);
        analysisToUpd.put('arce__wf_status_id__c', STATUS_CANCELLED);
        analysisToUpd.put('arce__Stage__c', STAGE_CLOSED);
        analysisToUpd.put('arce__anlys_wkfl_discard_reason_id__c', reasonValue);
        analysisToUpd.put('arce__anlys_wkfl_discard_reason_desc__c', reasonDesc);

        return analysisToUpd;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Creates the traceability event for the rating button.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysisId       ID of the Analysis__c record
    * @param    reasonDesc       Reason description for cancellation
    * @return   void
    * @example  setTraceability(analysisId, assignedUser, analysisId)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void setTraceability(String analysisId, String reasonLabel, String reasonDesc) {
        String traceComments = System.Label.arce.Arc_IFIS_BtnCancel_Reason + ': ' + reasonLabel;
        if (String.isNotBlank(reasonDesc)) {
            traceComments += ' | ' + System.Label.arce.Arc_IFIS_Comments + ': ' + reasonDesc;
        }

        arce.Arc_IFIS_Traceability.saveStatusEvent(
            analysisId,
            'Cancelled',
            traceComments.abbreviate(255),
            new Map<String, String>()
        );
    }
}