/**
* --------------------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Service
* @Author   César Octavio Villanueva Ceballos  cesaroctavio.villanueva.cebal@bbva.com
* @Date     Created: 2020-05-12
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------------
* @Description Service to set the financial sponsor indicator on the AccountHasAnalysis linked to a single Analysis
* --------------------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-12 cesaroctavio.villanueva.cebal@bbva.com
*             Class creation.
* |2020-05-14 cesaroctavio.villanueva.cebal@bbva.com
*			  Modified to use arce analysis instead of account has analysis of each account
* |2020-05-25 cesaroctavio.villanueva.cebal@bbva.com
*			  Added wrapper to get the current Financial Spondor Indicator value
* |2020-06-23 joseluis.garcia4.contractor@bbva.com
*			  Refactor + Changes to call generic implementation.
* |2020-07-16 joseluis.garcia4.contractor@bbva.com
*			  Reset Leveraged Test results if financial sponsor flag changes.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-03-29 juanignacio.hita.contractor@bbva.com
*             Add exception in callPersistence for 204 code financialsponsor service.
* ----------------------------------------------------------------------------------------------------------
*/
public class Arc_Gen_SetFinancialSponsor_Service {
    /*
    * @Description: Value for "Yes" in the arce__controlled_by_sponsor_type__c picklist field.
    */
    public static final String FINANCIAL_SPONSOR_YES = '1';
    /*
    * @Description: Value for "No" in the arce__controlled_by_sponsor_type__c picklist field.
    */
    public static final String FINANCIAL_SPONSOR_NO = '2';
    /**
    * @Description: Remove reason when arce is revoked.
    */
    static final String REMOVE_REASON = '2';

    /**
    *-------------------------------------------------------------------------------
    * @description Custom Exception to signal exceptions in the financial sponsor logic.
    *--------------------------------------------------------------------------------
    * @date		24/06/2020
    */
    public class SetFinancialSponsorException extends Exception { }

    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_ExecRep_Service
    * ------------------------------------------------------------------------------------------------------
    * @Author   César Villanueva
    * @Date     2020-05-12
    * @param    null
    * @return   Arc_Gen_SetFinancialSponsor_Service
    * @example  new Arc_Gen_SetFinancialSponsor_Service()
    * */
    @TestVisible
    private Arc_Gen_SetFinancialSponsor_Service() {}

    /*-----------------------------------------------------------------------------------------------------------------------
    * @Description Sets the value of Financial Sponsor to the ARCE of the requested analysis id and updates this value in database.
    * -----------------------------------------------------------------------------------------------------------------------
    * @Author   César Villanueva
    * @Date     2020-05-12
    * @param    String analysisId Id of the analysis to retrieve and update info
    * */
    public static void setFinancialSponsorAndUpdate(String analysisId) {
        // Get analysis info.
        final arce__Analysis__c dataArce = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id> {analysisId})[0];
        final String oldFsIndicator = dataArce.arce__controlled_by_sponsor_type__c;

        setFinancialSponsor(dataArce);
        arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { dataArce });

        // Clear Leveraged Test results if indicator changes.
        final String newFsIndicator = dataArce.arce__controlled_by_sponsor_type__c;
        if (oldFsIndicator != newFsIndicator) {
            Arc_Gen_TestLeverage_service.clearTestLeveragedResultsAnalysis(analysisId);
        }
    }

    /*-----------------------------------------------------------------------------------------------------------------------
    * @Description Sets the value of Financial Sponsor to the provided ARCE.
    * -----------------------------------------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     2020-06-23
    * @param    analysis - Analysis to set financial sponsor indicator for.
    * */
    public static void setFinancialSponsor(arce__Analysis__c analysis) {
        if (analysis.arce__analysis_customer_relation_type__c == arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN) {
            // Financial sponsor is always false when client is orphan.
            analysis.arce__controlled_by_sponsor_type__c = FINANCIAL_SPONSOR_NO;
        } else {
            // Get group info.
            final Id groupId = analysis.arce__Group__c;
            final arce.Arc_Gen_Account_Wrapper groupInfo = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String> { groupId }).get(groupId);

            try {
                // Call logic to get financial sponsor presence (Note: may incur in web service calls).
                final Arc_Gen_FinancialSponsor_Interface finSponsorImpl = Arc_Gen_GenericUtilitiesInterface.getFinancialSponsorCheckClass();
                final Boolean hasFinancialSponsor = finSponsorImpl.getFinancialSponsorStatus(groupInfo.accNumber);

                analysis.arce__controlled_by_sponsor_type__c = hasFinancialSponsor ? FINANCIAL_SPONSOR_YES : FINANCIAL_SPONSOR_NO;
            } catch (Exception ex) {
                final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
                if (ex.getMessage() == String.valueOf(serviceMessage.CODE_204)) {
                    final arce__Account_has_Analysis__c accHasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(analysis.Id);
                    // Remove analysis
                    Arc_Gen_Remove_Service.updateRemoveInfo(accHasAn.Id, REMOVE_REASON, System.Label.Arc_Gen_RevokeArceByChangesStrucGroup, '');
                }
                throw new SetFinancialSponsorException(ex.getMessage(), ex);
            }
        }
    }
}