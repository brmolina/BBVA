/**
* @File Name          : Arc_Gen_TestLeverage_service.cls
* @Description        : Contains the logic of the test leveraged
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 04-21-2026
* @Changes
*=======================================================================================================================
* Ver         Date                     Author      		      Modification
*=======================================================================================================================
* 1.0    30/4/2019  18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    19/7/2019  18:00:56   luisruben.quinto.munoz@bbva.com                 Change documentations
* 1.2    1/10/2019  15:31:56   javier.soto.carrascosa@bbva.com                 Update sme
* 1.3    2/12/2019  13:28:50   german.sanchez.perez.contractor@bbva.com
*                              franciscojavier.bueno@bbva.com                  Api names modified with the correct name on business glossary
* 1.4    05/3/2020  18:00:36   mariohumberto.ramirez.contractor@bbva.com       Added new method leveragePersistence
* 1.5    21/05/2020 16:30:00   cesaroctavio.villanueva.cebal@bbva.com          Modified risk validation & financial sponsor setting
* 1.6    01/06/2020 13:20:00   cesaroctavio.villanueva.cebal@bbva.com		   Fixed method that sets the risk on an a.h.a.
* 1.7    04/06/2020 17:31:28   cesaroctavio.villanueva.cebal@bbva.com          Added new validations & currency convertion
* 1.8    10/06/2020 12:26:55   cesaroctavio.villanueva.cebal@bbva.com          Fixed currency rate to temporarily set it to euros
* 1.9    11/06/2020 13:45:22   cesaroctavio.villanueva.cebal@bbva.com          Created new validation methods & reordered setupleverage validations
* 2.0    15/06/2020 11:52:58   cesaroctavio.villanueva.cebal@bbva.com          Refactor of getCurrencyRate method
* 2.1    17/06/2020 13:28:30   cesaroctavio.villanueva.cebal@bbva.com          Updated field for risk; added new method to update limits
* 2.2    25/06/2020 15:00:00   joseluis.garcia4.contractor@bbva.com            Add clearTestLeveragedResults() method.
* 2.3    30/06/2020 09:00:00   joseluis.garcia4.contractor@bbva.com            Change references to PoliciesWrapper
* 2.4    16/07/2020 09:00:00   joseluis.garcia4.contractor@bbva.com            Add clearTestLeveragedResultsAnalysis() method
* 2.5    18/08/2020 09:00:00   joseluis.garcia4.contractor@bbva.com            Add currency exchange logic.
* 2.6    02/09/2020 09:00:00   joseluis.garcia4.contractor@bbva.com            Ensure risk for leverage (orphans) are obtained from own analysis.
* 2.6    23/09/2020            saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the arce-dependencies package
* 2.7    27/11/2020 09:00:00   joseluis.garcia4.contractor@bbva.com            Shows error if leveraged risk is zero.
* 2.8    07/04/2021 09:00:00   joseluis.garcia4.contractor@bbva.com            Change references to Arc_Gen_RatingGlobal_* classes.
**/
@SuppressWarnings('PMD')
public without sharing class Arc_Gen_TestLeverage_service {
/**
*-------------------------------------------------------------------------------
* @description wrapper for the test leveraged variables
*--------------------------------------------------------------------------------
* @author  eduardoefrain.hernandez.contractor@bbva.com
* @date    30/4/2019
* @Method: LeverageVariables
* @param:
* @return:
**/
    public class leverageVariables {
        /**
        * @Description: Number of employees
        */
        public Double noEmployees;
        /**
        * @Description: Risk amount
        */
        public Double risk;
        /**
        * @Description: Rating value
        */
        public String rating;
        /**
        * @Description: Was financial sponsor previously filled
        */
        public Boolean prevFS;
        /**
        * @Description: Financial sponsor indicator
        */
        public Boolean financialSponsor;
        /**
        * @Description: Was Small or Medium Enterprise Indicator previously filled
        */
        public Boolean prevSME;
        /**
        * @Description: Small or Medium Enterprise Indicator
        */
        public Boolean smeIndicator;
        /**
        * @Description: Debt amount
        */
        public Double debt;
        /**
        * @Description: Ebitda amount
        */
        public Double ebitda;
        /**
        * @Description: Debt over ebitda ratio
        */
        public Double debtOverEbitda;
        /**
        * @Description: Type of calculation
        */
        public String calculateType;
    }
/**
*-------------------------------------------------------------------------------
* @description wrapper for the LeverageTestResponse
*--------------------------------------------------------------------------------
* @author  eduardoefrain.hernandez.contractor@bbva.com
* @date    30/4/2019
* @Method: LeverageTestResponse
* @param:
* @return:
**/
    public class leverageTestResponse {
        /**
        * @Description: Status of the process
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Message of the leverage
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @Description: List of the variables used in the leveraged
        */
        @AuraEnabled public List<String> leveragedVariables {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that creates the response of the leveraged
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId of type arce__Account_has_Analysis__c
    * @return leverageTestResponse - A wrapper that contains the information of the test leveraged
    * @example public static leverageTestResponse setupLeverage(String analysisId)
    **/
    public static leverageTestResponse setupLeverage(String analysisId) {
        Arc_Gen_TestLeverage_data locator = new Arc_Gen_TestLeverage_data();
        leverageTestResponse leveragedResponse = new leverageTestResponse();
        Arc_Gen_TestLeverage_data.saveResult saveResult = new Arc_Gen_TestLeverage_data.saveResult();
        arce__Account_has_Analysis__c analyzedClient = locator.getAccountHasAnalysis(analysisId);

        // Get currency exchange rate.
        final String currencySelected = analyzedClient.arce__currency_id__c == null ? 'EUR' : analyzedClient.arce__currency_id__c;
        final Decimal currencyRate = getCurrencyRate(currencySelected);

        leverageVariables leverageBefore = setupLeverageVariables(analyzedClient,'before', currencyRate);
        leverageVariables leverageAfter = setupLeverageVariables(analyzedClient,'after', currencyRate);

        if (leverageBefore.risk > 0.0) {
            if (leverageBefore.rating == Null) {
                leveragedResponse.status = 'false';
                leveragedResponse.message = System.Label.Cls_arce_LeverageErrorNoRating;
                locator.updateRecord(analyzedClient);
            }  else {
                if (leverageBefore.prevFS) {
                    if (leverageBefore.prevSME) {
                        if (leverageBefore.noEmployees == null) {
                            leveragedResponse.status = 'false';
                            leveragedResponse.message = System.Label.Cls_arce_LeverageErrorNoEmployees;
                            locator.updateRecord(analyzedClient);
                        } else {
                            List<String> leveragedResults = new List<String>();
                            analyzedClient = calculateLeverage(leverageBefore,analyzedClient);
                            analyzedClient = calculateLeverage(leverageAfter,analyzedClient);
                            saveResult = locator.updateRecord(analyzedClient);
                            arce__Account_has_Analysis__c analyzedClientResult = locator.getLeveragedResults(analyzedClient.Id);
                            leveragedResponse.status = saveResult.status;
                            leveragedResponse.message = saveResult.message;
                            leveragedResults.add(analyzedClientResult.arce__ll_before_adj_ind_type__c);
                            leveragedResults.add(analyzedClientResult.arce__ll_before_adj_clsfn_type__c != null ? analyzedClientResult.arce__ll_before_adj_clsfn_type__c : '');
                            leveragedResults.add(analyzedClientResult.arce__ll_after_adj_ind_type__c);
                            leveragedResults.add(analyzedClientResult.arce__ll_after_adj_clsfn_type__c != null ? analyzedClientResult.arce__ll_after_adj_clsfn_type__c : '');
                            leveragedResponse.leveragedVariables = leveragedResults;
                        }
                    } else {
                        leveragedResponse.status = 'false';
                        leveragedResponse.message = System.Label.Cls_arce_LeverageErrorNoSME;
                        locator.updateRecord(analyzedClient);
                    }
                } else {
                    leveragedResponse.status = 'false';
                    leveragedResponse.message = System.Label.Cls_arce_LeverageErrorNoFS;
                    locator.updateRecord(analyzedClient);
                }
            }
        } else {
            leveragedResponse.status = 'false';
            leveragedResponse.message = System.Label.Cls_arce_LeverageErrorNoRisk;
            locator.updateRecord(analyzedClient);
        }
        Return leveragedResponse;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the variables that will be use for the test leveraged
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param arce__Account_has_Analysis__c analyzedClient for the test leveraged
    * @param String calculateType - "Before" or "After" Adjustments
    * @return leverageVariables - A wrapper that contains the different variables that will be used in test leveraged
    * @example public static leverageVariables setupLeverageVariables(arce__Account_has_Analysis__c analyzedClient,String calculateType)
    **/
    public static leverageVariables setupLeverageVariables(arce__Account_has_Analysis__c analyzedClient, String calculateType, Decimal currencyRate) {
        leverageVariables leverage = new leverageVariables();
        leverage.rating = (String)analyzedClient.arce__ffss_for_rating_id__r.arce__rating_final__c;
        leverage.noEmployees = analyzedClient.arce__employees_number__c;
        leverage.risk = analyzedClient.arce__current_proposed_amount__c == null ? null : (analyzedClient.arce__current_proposed_amount__c) * currencyRate;
        leverage.prevFS = validate1(analyzedClient.arce__Analysis__r.arce__controlled_by_sponsor_type__c);
        leverage.financialSponsor = validate2(analyzedClient.arce__Analysis__r.arce__controlled_by_sponsor_type__c);
        leverage.prevSME = validate1(analyzedClient.arce__smes_eur_comuty_defn_type__c);
        leverage.smeIndicator = validate2(analyzedClient.arce__smes_eur_comuty_defn_type__c);
        leverage.debt = validate3 ('debt',calculateType,analyzedClient);
        leverage.ebitda = validate3 ('ebitda',calculateType,analyzedClient);
        leverage.debtOverEbitda = leverage.ebitda != 0 ? leverage.debt / leverage.ebitda : 0;
        leverage.calculateType = calculateType;
        Return leverage;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that verifies if a value is null or not
    --------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date 11/06/2020
    * @param String - Variable that will be verified if is null or not
    * @return Boolean - Result of null verification
    * @example public static Boolean validate1(String isNull)
    **/
    public static Boolean validate1 (String variable) {
        Boolean result = variable == null ? FALSE : TRUE;
        return result;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that verifies the flag (1 or 2) value
    --------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date 11/06/2020
    * @param String - Variable that will be verified
    * @return Boolean - Result of flag verification
    * @example public static Boolean validate2(String whatValue)
    **/
    public static Boolean validate2 (String variable) {
        Boolean result = variable == '1' ? TRUE : FALSE;
        return result;
    }
    /**
    *------------------------------------------------------------------------------------------------
    * @description Method that verifies the type of calculation of leverage to return the correct value
    --------------------------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date 11/06/2020
    * @param String - debt or ebitda verification
    * @param String - type of calculation on leverage
    * @param arce__Account_has_Analysis__c - aha where the value will be gathered
    * @return double - value to be setted to the leverage variable
    * @example public static double validate3(String whatValue, String calcType, arce__Account_has_Analysis__c analyzedClient)
    **/
    public static double validate3 (String data, String calcType, arce__Account_has_Analysis__c analyzedClient) {
        Double result;
        switch on data {
            when 'debt' {
                result = calcType == 'before' ? analyzedClient.arce__gross_financial_debt_amount__c : analyzedClient.arce__ll_adj_debt_amount__c;
            }
            when 'ebitda' {
                result = calcType == 'before' ? analyzedClient.arce__ebitda_interest_number__c : analyzedClient.arce__ll_adj_ebitda_amount__c;
            }
        }
        return result;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that update the group Account Has Analysis with the Limit amounts
    --------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date 04/06/2020
    * @param arce__Account_has_Analysis__c accHasAnalysis - Account Has Analysis Record
    * @return arce__Account_has_Analysis__c - Account Has Analysis Record
    * @example public arce__Account_has_Analysis__c getAhaGroup(arce__Account_has_Analysis__c accHasAnalysis)
    **/
    private static arce__Account_has_Analysis__c getAhaGroup(arce__Account_has_Analysis__c accHasAnalysis) {
        arce__Account_has_Analysis__c ahaGroup = new arce__Account_has_Analysis__c();
        final List<arce__Account_has_Analysis__c> ahaByArce = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{accHasAnalysis.arce__Analysis__c});
        for(arce__Account_has_Analysis__c aha : ahaByArce) {
            if(aha.arce__group_asset_header_type__c == '1') {
              ahaGroup = aha;
            }
        }
        Return ahaGroup;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that calculates the test leveraged
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param LeverageVariables leverage - A wrapper that contains the different variables that will be used in test leveraged
* @param arce__Account_has_Analysis__c analyzedClients for the test leveraged
* @return arce__Account_has_Analysis__c - current record on test leveraged
* @example public static arce__Account_has_Analysis__c calculateLeverage(LeverageVariables leverage,arce__Account_has_Analysis__c analyzedClient)
**/
    public static arce__Account_has_Analysis__c calculateLeverage(LeverageVariables leverage,arce__Account_has_Analysis__c analyzedClients) {
        Arc_Gen_TestLeverage_data locator = new Arc_Gen_TestLeverage_data();
        arce__Account_has_Analysis__c analyzedClient = analyzedClients;
        final Double fiveMillions = 5;
        final Integer four = 4;
        final Integer six = 6;
        final Integer zero = 0;
        if(leverage.risk >= fiveMillions) {
            if(getValidRatings().contains(leverage.rating)) {
                if(leverage.financialSponsor) {
                    analyzedClient = leverageTestTrue(analyzedClient,leverage.calculateType,'FS');
                } else {
                    analyzedClient = leverageTestFalse(analyzedClient,leverage.calculateType);
                }
            } else {
                if(leverage.financialSponsor) {
                    analyzedClient = leverageTestTrue(analyzedClient,leverage.calculateType,'NI');
                } else {
                    if(leverage.smeIndicator) {
                        analyzedClient = leverageTestFalse(analyzedClient,leverage.calculateType);
                    } else {
                        if(leverage.debtOverEbitda > four || leverage.debtOverEbitda < zero || (leverage.debt > zero && leverage.ebitda == zero)) {
                            if(leverage.debtOverEbitda > six || leverage.debtOverEbitda < zero || (leverage.debt > zero && leverage.ebitda == zero)) {
                                analyzedClient = leverageTestTrue(analyzedClient,leverage.calculateType,'R6');
                            } else {
                                analyzedClient = leverageTestTrue(analyzedClient,leverage.calculateType,'R4');
                            }
                        } else {
                            analyzedClient = leverageTestFalse(analyzedClient,leverage.calculateType);
                        }
                    }
                }
            }
        } else {
            analyzedClient = leverageTestFalse(analyzedClient,leverage.calculateType);
        }
        analyzedClient.arce__anlys_wkfl_sbanlys_status_type__c = '3';
        Return analyzedClient;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that change the test leveraged indcator field to YES
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param arce__Account_has_Analysis__c analyzedClient
* @param String calculateType - "Before" or "After"
* @param String leverageType - Classification type of the test leveraged
* @return arce__Account_has_Analysis__c record with arce__ll_before_adj_ind_type__c, arce__ll_before_adj_clsfn_type__c data
* @example public static arce__Account_has_Analysis__c leverageTestTrue(arce__Account_has_Analysis__c analyzedClient,String calculateType,String leverageType)
**/
    public static arce__Account_has_Analysis__c leverageTestTrue(arce__Account_has_Analysis__c analyzedClient,String calculateType,String leverageType) {
        switch on calculateType {
            when 'before' {
                analyzedClient.arce__ll_before_adj_ind_type__c = '1';
                analyzedClient.arce__ll_before_adj_clsfn_type__c = leverageType;
            }
            when 'after' {
                analyzedClient.arce__ll_after_adj_ind_type__c = '1';
                analyzedClient.arce__ll_after_adj_clsfn_type__c = leverageType;
            }
        }
        Return analyzedClient;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that change the test leveraged indcator field to NO
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param arce__Account_has_Analysis__c analyzedClient variable to update
* @param String calculateType - "Before" or "After"
* @return arce__Account_has_Analysis__c object with preset variables
* @example leverageTestFalse(arce__Account_has_Analysis__c analyzedClient,String calculateType) {
**/
    public static arce__Account_has_Analysis__c leverageTestFalse(arce__Account_has_Analysis__c analyzedClient,String calculateType) {
        switch on calculateType {
            when 'before' {
                analyzedClient.arce__ll_before_adj_ind_type__c = '2';
                analyzedClient.arce__ll_before_adj_clsfn_type__c = null;
            }
            when 'after' {
                analyzedClient.arce__ll_after_adj_ind_type__c = '2';
                analyzedClient.arce__ll_after_adj_clsfn_type__c = null;
            }
        }
        Return analyzedClient;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that return a set of all rating values
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param void
* @return Set<String>
* @example  getValidRatings() {
**/
    public static Set<String> getValidRatings() {
        Set<String> validRatings = new Set<String>{'BBB-','BBB','BBB+','A-','A','A+','AA-','AA','AA+','AAA'};
        Return validRatings;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that return the currency rate of the organization
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String currencyIsoCode for the test leveraged
    * @return Double
    * @example getCurrencyRate(String currencyIsoCode) {
    **/
    public static Double getCurrencyRate(String selectedCurrency) {
        Decimal currencyRate;
        final Arc_Gen_TestLeverage_data locator = new Arc_Gen_TestLeverage_data();

        // Obtain currency exchange implementation.
        final String targetCurrency = 'EUR';
        final Arc_Gen_CurrencyExchange_Interface impl = Arc_Gen_GenericUtilitiesInterface.getCurrencyExchangeClass();
        final Arc_Gen_CurrencyExchange_Params params = new Arc_Gen_CurrencyExchange_Params();
        params.baseCurrency = selectedCurrency;
        params.targetCurrency = targetCurrency;
        params.exchangeRateOrigin = 'IRISK';
        params.exchangeRateDate = System.today();

        Arc_Gen_CurrencyExchange_Wrapper result = impl.getCurrencyExchangeInfo(params);
        return result.getCurrencyExchangeRate(targetCurrency);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that manage the leverage persistence service
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param analysisId - Accoun has analysis id object
    * @return Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper - wrapper with the operation status
    * @example leveragePersistence(analysisId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper leveragePersistence(String analysisId) {
        final Map<String,String> configInfoMap = Arc_Gen_ServicePersitence_Locator.retConfigurationInfo('leveragePersistence');
        if (configInfoMap.isEmpty()) {
            throw new ListException(Label.Arc_Gen_EmptyList);
        }
        final List<sObject> objLts = arce.Arc_Gen_AccHasAnalysis_Data.getRelatedData(new List<String>(configInfoMap.keySet()), analysisId);
        return Arc_Gen_Persistence_Leverage_Service.callPersistence(objLts);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that updates the current proposes limit on the group to it's subsidiaries (if applies)
    * ----------------------------------------------------------------------------------------------------
    * @Author cesaroctavio.villanueva.cebal@bbva.com
    * @Date 2020-06-17
    * @param accHasAnalysis - Accoun has analysis object
    * @return void
    * @example updateLimitLeverage(analysisId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void updateLimitLeverage(arce__Account_has_Analysis__c accHasAnalysis){
        final arce.Arc_Gen_RatingGlobal_data res = new arce.Arc_Gen_RatingGlobal_data();
        final Boolean useOwnAnalysis = accHasAnalysis.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER ||
            accHasAnalysis.arce__Analysis__r.arce__analysis_customer_relation_type__c == arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN;
        final arce__Account_has_Analysis__c ahaGroup = useOwnAnalysis ? accHasAnalysis : getAhaGroup(accHasAnalysis);
        arce__limits_exposures__c groupLimits = arce.Arc_Gen_GenericUtilities.getHighestTypLimits(ahaGroup);
        final Decimal realDivFactor = getDivFactor(ahaGroup.arce__magnitude_unit_type__c);
        final decimal newLimit = groupLimits.arce__current_proposed_amount__c / realDivFactor;
        accHasAnalysis.arce__current_proposed_amount__c = newLimit;
        List<sObject> toUpdate = new List<sObject>{};
        toUpdate.add(accHasAnalysis);
        if (accHasAnalysis.arce__group_asset_header_type__c == '1') {
            final List<arce__Account_has_Analysis__c> ahasToUpdate = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{accHasAnalysis.arce__Analysis__c});
            for (arce__Account_has_Analysis__c aha : ahasToUpdate) {
                if (aha.arce__group_asset_header_type__c == '2') {
                    aha.arce__current_proposed_amount__c = newLimit;
                    toUpdate.add(aha);
                }
            }
        }
        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(toUpdate);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that clears the results of the Leveraged Test. To be called when these results
    * become stale due to changes in the analysis.
    * ----------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 2020-06-25
    * @param ahaId - Id of the Account has analysis record
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void clearTestLeveragedResults(String ahaId) {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
            Id = ahaId,
            arce__ll_before_adj_ind_type__c = null,
            arce__ll_before_adj_clsfn_type__c = null,
            arce__ll_after_adj_ind_type__c = null,
            arce__ll_after_adj_clsfn_type__c = null,
            arce__anlys_wkfl_sbanlys_status_type__c = '1'
        );

        arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(aha);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that clears the results of the Leveraged Test for all AHAs of an analysis.
    * ----------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 2020-07-16
    * @param analysisId - Id of the analysis record
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void clearTestLeveragedResultsAnalysis(String analysisId) {
        List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String> { analysisId });

        for (arce__Account_has_Analysis__c aha : ahaList) {
            aha.arce__ll_before_adj_ind_type__c = null;
            aha.arce__ll_before_adj_clsfn_type__c = null;
            aha.arce__ll_after_adj_ind_type__c = null;
            aha.arce__ll_after_adj_clsfn_type__c = null;
            aha.arce__arce_ctmr_flag__c = false;
            aha.arce__anlys_wkfl_sbanlys_status_type__c = '1';
        }

        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(ahaList);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return the multiplication factor to convert the unit selected in units
    * --------------------------------------------------------------------------------------
    * @Author   César Octavio Villanueva Ceballos  cesaroctavio.villanueva.cebal@bbva.com
    * @Date     Created: 14/05/2020
    * @param unitSelected - unit selected in combo box
    * @return divFactor - factor of divition to convert the unit selected in units
    * @example getDivFactor(unitSelected)
    * --------------------------------------------------------------------------------------
    **/
    public static Double getDivFactor(String unitSelected) {
        Double divFactor = 1;
        switch on unitSelected {
            when '1' {
                divFactor = 1000000;
            }
            when '2' {
                divFactor = 1000;
            }
            when '3' {
                divFactor = 1;
            }
        }
        return divFactor;
    }
}