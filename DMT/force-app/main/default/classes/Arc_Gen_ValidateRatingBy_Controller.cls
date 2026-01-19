/**
 * @description       : 
 * @author            : Global Desktop
 * @group             : 
 * @last modified on  : 08-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing  class Arc_Gen_ValidateRatingBy_Controller { 

  /**
  * @description Service name
  */
  public static final String PS_SERVICE_CLASS_NAME = Test.isRunningTest() ? 'Arc_Gen_RetrievePS_Service_Mock' : 'Arc_Gen_RetrievePS_Service';
  
  /**
  * @description OVERRIDE value
  */
  public static final String OVERRIDE_VALUE = 'OVERRIDE';

  private static final String SEVENHUNDRED = '700';
  @TestVisible
  private Arc_Gen_ValidateRatingBy_Controller(){}

  public class ValidatedByResponse{
    @AuraEnabled
    public Map<String,Object> data {get;private set;}
    @AuraEnabled
    public Boolean success {get;private set;}
    @AuraEnabled
    public String message {get;private set;}

    public ValidatedByResponse(Map<String,Object> data, Boolean success, String msg){
      this.data=data;
      this.success=success;
      this.message=msg;
    }
  }


  @AuraEnabled
  public static ValidatedByResponse getRatingData(String aHaId) {
    ValidatedByResponse ret;
    Map<String,Object> data;
    Arc_Gen_Delegation_Wrapper wrapper;
    arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();

    if(String.isNotBlank(aHaId)){
      if(Arc_Gen_TabSet_service.hasPermissionAmbit(aHaId)) {
      try {
		String message = 'Show';
        data = new Map<String,Object>();
        arce__Account_has_Analysis__c aHa = locator.getAccountHasAnalysis(aHaId)[0];
        final Decimal ratingAfterProp = aHa.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__final_rating_after_propose__c;
        final Decimal ratingToValidate = aHa.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c;
        final Decimal ratingStandAfterProp = aHa.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_standalone_after_prop__c;
        final Decimal ratingStandToValidate = aHa.arce__total_rating_score_number__c;
        final String finStatementId = aha.arce__ffss_for_rating_id__r.arce__financial_statement_id__c != null ? aha.arce__ffss_for_rating_id__r.arce__financial_statement_id__c : '';
        data.put('wfType', aHa.arce__IRP_Workflow__c);
        data.put('subProcessType', aHa.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        data.put('ratingId', aHa.arce__ffss_for_rating_id__r.arce__rating_id__c);
        data.put('ffssCertification', aHa.arce__ffss_for_rating_id__r.arce__ffss_certification_type__c);
        data.put('withOverride', aha.arce__with_override__c);
        data.put('financialType', aha.arce__AHA_Extension__r.arce__Financial_Type__c);
        data.put('finStatementId', finStatementId);
		if(aHa.arce__recalculate_rating__c != null && aHa.arce__recalculate_rating__c != '4') {
            Map<String,String> mapa = new  Map<String,String>();
            mapa = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Account_has_Analysis__c', 'arce__recalculate_rating__c');
            if(!mapa.isEmpty() && mapa.get(aHa.arce__recalculate_rating__c) != null) {
                String recalc = mapa.get(aHa.arce__recalculate_rating__c).toLowerCase();
                message = System.Label.arce.Arc_Gen_RecalcRatWarningVal + ' ' + recalc;
            }
        }
        data.put('recalculateRating', message);
        data.put('showValidatedBy', ratingAfterProp != ratingToValidate || ratingStandAfterProp != ratingStandToValidate);
        data.put('proposeUser', aHa.arce__Analysis__r.arce__proposeUser__c);
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, aHa.arce__Analysis__c, 'RAIP-PROPOSE',true);
        System.debug('>>>>>>>>>>>>> wrapper ' + wrapper);
        data.put('regionList', wrapper.lstRegion);
        ret = createResponseObj(data, true, null);
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage()); //NOSONAR
      }
      } else {
        ret = createResponseObj(null, false, 'The action cannot be executed. Invalid profile.');
      }

    } else {
      ret = createResponseObj(null, false, System.Label.arce.Aha_Not_Provided_Error);
    }
    return ret;
  }

  /**
  * @description
  * @author Global Desktop | 24-11-2021
  * @param selectedAmbit
  * @return ValidatedByResponse
  **/
  @AuraEnabled
  public static ValidatedByResponse fetchUsers(String selectedAmbit) {
    ValidatedByResponse ret;
    Map<String,Object> data;
    Arc_Gen_Delegation_Wrapper wrapper;

    if(String.isNotBlank(selectedAmbit)) {
      try {
        data = new Map<String,Object>();
        wrapper = Arc_GBL_Workflow_Helper.fetchUsersByAmbit(selectedAmbit);
        data.put('userList', wrapper.lstUsers);
        ret = createResponseObj(data, true, null); //NOSONAR
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e.getMessage()); //NOSONAR
      }
    } else {
      ret = createResponseObj(null, false, 'Ambit must be provided to the APEX controller');
    }
    return ret;
  }

  /**
  * @description
  * @author Global Desktop | 24-11-2021
  * @param selectedAmbit
  * @param aHaId
  * @return ValidatedByResponse
  **/
  @AuraEnabled
  public static ValidatedByResponse fetchUsersAha(String selectedAmbit,String aHaId) {
    ValidatedByResponse ret;
    Map<String,Object> data;
    Arc_Gen_Delegation_Wrapper wrapper;

    if(String.isNotBlank(selectedAmbit) && String.isNotBlank(aHaId)) {
      try {
        data = new Map<String,Object>();
        final List<arce__Account_has_Analysis__c> aHa = [select id, arce__Analysis__r.arce__proposeUser__c  from arce__Account_has_Analysis__c where Id = :aHaId Limit 1];
        wrapper = Arc_GBL_Workflow_Helper.fetchUsersByAmbit(selectedAmbit);
        for(Integer i = 0; i <  wrapper.lstUsers.size(); i++) {
          if(aHa.get(0).arce__Analysis__r.arce__proposeUser__c == wrapper.lstUsers.get(i).get('value')) {
            wrapper.lstUsers.remove(i);
          }
        }
        data.put('userList', wrapper.lstUsers);
        ret = createResponseObj(data, true, null); //NOSONAR
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e.getMessage()); //NOSONAR
      }
    } else {
      ret = createResponseObj(null, false, 'Ambit must be provided to the APEX controller');
    }
    return ret;
  }


  /**
  *-------------------------------------------------------------------------------
  * @description Method that obtains the response of the changing status from the service class
  --------------------------------------------------------------------------------
  * @author eduardoefrain.hernandez.contractor@bbva.com
  * @date 2019-05-13
  * @param String arce analysis Id
  * @param String rating  Id
  * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with information of saving records
  * @example public static arce.Arc_Gen_ServiceAndSaveResponse changeStatus(String analysisId)
  **/
  //    @SupressWarning(PMD.)

  @AuraEnabled
  public static ValidatedByResponse validateRating(String analysisId, String ratingId, String validatedById, String description, String ambit) {
    ValidatedByResponse ret;
    arce.Arc_Gen_ServiceAndSaveResponse response;
    arce.Arc_Gen_RatingGlobal_data ratingLocator = new arce.Arc_Gen_RatingGlobal_data();
    arce.Arc_Gen_RatingGlobal_data.SaveResult saveResult;
    if (Arc_Gen_TabSet_service.getPermissionToEdit(analysisId) == 'true') {
      try {
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(analysisId);
        List<sObject> toUpdates = new List<sObject>();
        arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validtionWrapper = new arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper(analysisId,validatedById,ratingId,ambit,description);
        response = Arc_Gen_ValidateRating_service.setupValidateRatingByUser(validtionWrapper, null, true);

        if(response.serviceCode == arce.Arc_Gen_RatingGlobal_Constants.SUCC1){
          ret = createResponseObj(null, Boolean.valueOf(response.saveStatus), response.saveMessage); //Save status is returned to lightning controller because its the last operation after all previous succeeded
        }else{
          ret = createResponseObj(null, false, response.serviceMessage);
        }
      } catch (Exception e) {
        arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_ApexCallError + ': ' + e.getMessage() + e.getStackTraceString());
      }
    } else {
        ret = createResponseObj(null, false, System.Label.Arc_Gen_Generic_NotAllowed);
    }
    return ret;
  }
  @AuraEnabled
    public static String fetchRegionLevel(String region, String level,String accHasAnalysisId) {
        try {
            final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
            final Arc_Gen_Delegation_Wrapper wrapper = DES_Arc_GBL_Workflow_Helper.fetchLevelRegion(wrpUser.ambitUser,region,level,accHasAnalysisId,true);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }

  private static ValidatedByResponse createResponseObj(Map<String,Object> d, Boolean s, String m){
    return new ValidatedByResponse(d,s,m);
  }

  /**
  *-------------------------------------------------------------------------------
  * @description Method that calculate if total revenues is greater than 100M Eur(ES) or 50M USD (MX-AR-PER-COL) or 100M USD (Turkey)
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.contractor@bbva.com
  * @date 2022-05-05
  * @param String ahaId
  * @return boolean - return true if total revenues is greater than 100M Eur(ES) or 50M USD (MX-AR-PER-COL) or 100M USD (Turkey) and false if it is not that case
  **/
  @AuraEnabled
  public static ValidatedByResponse validateMillions(String ahaId) {
    Boolean lessThan = true;
    ValidatedByResponse ret;
    arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
    arce.Arc_Gen_AccHasAnalysis_Data ahaLocator = new arce.Arc_Gen_AccHasAnalysis_Data();
    if(String.isNotBlank(ahaId)){
      try {
        final arce__Account_has_Analysis__c aHa = locator.getAccountHasAnalysis(aHaId)[0];
        final Boolean avoidValidation = aHa.arce__IRP_Workflow__c == 'ARP' || aHa.arce__IRP_Workflow__c == 'CRP' || getAvoidByRarRatingTool(aHa.arce__RAR_rating_tool_id__c) ? true : false;
        if (!avoidValidation) {
          final String ffssDate = String.valueOf(aHa.arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c);
          final arce__Table_Content_per_Analysis__c tableContent = ahaLocator.getTableContentByCodeTerm(aHaId,new Set<String>{SEVENHUNDRED})[0];
          final String tcOriginalCurrency = tableContent.arce__original_currency__c;
          final Double tcOriginalAmount = tableContent.arce__original_amount__c;
          final String clientId = aHa.arce__Customer__c;
          final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { clientId }).get(clientId);
          if((accWrapper.country == 'ES' || accWrapper.country == 'PO') && tcOriginalCurrency != 'EUR') {
            final arce.Arc_Gen_Ratios_Calculator_Service.CurrencySrvcParameters servParams = new arce.Arc_Gen_Ratios_Calculator_Service.CurrencySrvcParameters(tcOriginalCurrency,'EUR','IRISK',ffssDate);
			      final Map<String,Double> response =  arce.Arc_Gen_Ratios_Calculator_Service.targtCurrncy(servParams).get('EUR');
			      final Double amountExchange = tcOriginalAmount * Double.valueOf(response.get(System.Label.arce.Ratios_Interval_Rate));
            final Integer amountInMillion = getAmountInMillions(amountExchange,'MILLI').intValue();
            lessThan = getAmountValidation(amountInMillion,'EUR',accWrapper.country);
          } else if((accWrapper.country == 'MX' || accWrapper.country == 'AR' || accWrapper.country == 'PE' || accWrapper.country == 'CO' || accWrapper.country == 'TR') && tcOriginalCurrency != 'USD') {
            final arce.Arc_Gen_Ratios_Calculator_Service.CurrencySrvcParameters servParams = new arce.Arc_Gen_Ratios_Calculator_Service.CurrencySrvcParameters(tcOriginalCurrency,'USD','IRISK',ffssDate);
			      final Map<String,Double> response =  arce.Arc_Gen_Ratios_Calculator_Service.targtCurrncy(servParams).get('USD');
			      final Double amountExchange = tcOriginalAmount * Double.valueOf(response.get(System.Label.arce.Ratios_Interval_Rate));
            final Integer amountInMillion = getAmountInMillions(amountExchange,'MILLI').intValue();
            lessThan = getAmountValidation(amountInMillion,'USD',accWrapper.country);
           } else {
            final Integer amountInMillion = getAmountInMillions(tcOriginalAmount,'MILLI').intValue();
            lessThan = getAmountValidation(amountInMillion,tcOriginalCurrency,accWrapper.bookingCountry);
          }
        }
        ret = getValidatedByResponse(lessThan);
      } catch (Exception e) {
        ret = createResponseObj(null,false,e.getMessage());
      }
    }else {
      ret = createResponseObj(null, false, System.Label.arce.Aha_Not_Provided_Error);
    }
    return ret;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description Method that return true or false if it matches any of de following RTC flows
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.tech@bbva.com
  * @date 2024-03-13
  * @param String rarRatingTool
  * @return Boolean
  **/
  private static Boolean getAvoidByRarRatingTool(String rarRatingTool) {
    return rarRatingTool == '2021RTC_NFI' || rarRatingTool == '2021RTC_EXPG' || rarRatingTool == '2021RTC_NBF';
  }

  /**
  *-------------------------------------------------------------------------------
  * @description Method that return original amount in millions
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.contractor@bbva.com
  * @date 2022-05-05
  * @param String ahaId
  * @return Double - amount in millions
  **/
  private static Double getAmountInMillions(Double tcOriginalAmount, String unit) {
    return arce.Arc_Gen_Ratios_Calculator_Service.calValueUnit(tcOriginalAmount,unit);
  }

  /**
  *-------------------------------------------------------------------------------
  * @description Method that check the amount conditions for the diferent currencies
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.contractor@bbva.com
  * @date 2022-05-05
  * @param String ahaId
  * @return boolean - validation result
  **/
  private static Boolean getAmountValidation(Integer amountInMillion, String curren, String accCountry) {
    Boolean lessThan = false;
    switch on accCountry {
      when 'ES','PO','TR'{
        lessThan = amountInMillion >= 100;
      }
      when 'MX','AR','PE','CO' {
          lessThan = amountInMillion >= 50;
      }
      when else {
        lessThan = true;
      }
    }
    return lessThan;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description Method that return original amount in millions
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.contractor@bbva.com
  * @date 2022-05-05
  * @param String ahaId
  * @return Double - amount in millions
  **/
  private static ValidatedByResponse getValidatedByResponse(Boolean lessThan) {
    return lessThan ? createResponseObj(null,lessThan,null) : createResponseObj(null,lessThan,System.Label.arce.Minimum_turnover_Error);
  }

  /**
  *-------------------------------------------------------------------------------
  * @description Method that obtains the response of the limitAdvisor service
  --------------------------------------------------------------------------------
  * @author alberto.martinez.carrero.contractor@bbva.com
  * @date 2022-06-03
  * @param String arce account has analysis Id
  * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with information of saving records
  * @example public static arce.Arc_Gen_ServiceAndSaveResponse
  **/
  @AuraEnabled
  public static ValidatedByResponse callLimitAdvisorSrv(String aHaId) {
    ValidatedByResponse valResp;
    arce.Arc_Gen_LimitAdvisor_RP response;
    Boolean success = true;
      if (getParentCondition(aHaId)) {
          	response = arce.Arc_Gen_LimitAdvisor_Service.callLimitAdvisor(aHaId, true, null, false);
          	success = response.message.detailedMessage == 'SUCCESS' ? true : false;
          	valResp = createResponseObj(null,success,response.message.errorCode + ': ' + response.message.description);
      } else {
          valResp = createResponseObj(null,success,'200');
      }
    return valResp;
  }

  /**
  * -----------------------------------------------------------------------------------------------
  * @description Method that obtains the response of the persistence Esg service
  * -----------------------------------------------------------------------------------------------
  * @param String ahaId - Selected account has analysis id
  * @return ValidatedByResponse - response of the persistence Esg service
  * @example ValidatedByResponse response =  callPersistenceEsg(ahaId)
  * -----------------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static ValidatedByResponse callPersistenceEsg(String ahaId) {
    arce.Arc_Esg_PersistEsg_Service.ResponseWrapper response = arce.Arc_Esg_PersistEsg_Service.callPersistence(ahaId);
    return createResponseObj(null, response.success, response.message);
  }

  /**
  * @description isOverrideComplete
  * @author aleksandar.dinkov.contractor@bbva.com | 10-02-2024
  * @param String ahaId
  * @return MessageResponse
  **/
  @AuraEnabled
  public static Map<String,String> isOverrideComplete(Id ahaId) {
    final Map<String,String> responseMap = new Map<String,String>{'status' => 'Success'};
    // Se habilita o deshabilita la validacion con un metadata de configuracion.
    final List<arce__Arce_Config__mdt> config = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Enable_Validate_Override_LBO');
    if (!config.isEmpty() && Boolean.ValueOf(config[0].arce__Value1__c)) {
      final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> { ahaId })[0];
      final List<arce__rating_variables_detail__c> varsList = [SELECT Id, arce__adj_short_rating_value_type__c, arce__adj_long_rating_value_type__c , arce__adj_total_rating_score_number__c, arce__rating_override_comment__c FROM arce__rating_variables_detail__c WHERE arce__account_has_analysis_id__c = :ahaId AND arce__rating_modifier_adj_type__c = :OVERRIDE_VALUE WITH SYSTEM_MODE];
      responseMap.put('isRTC', String.valueOf(aha.arce__Analysis__r.arce__is_RTC__c));
      if (aha.arce__ffss_for_rating_id__c != null && !varsList.isEmpty() && String.valueOf(aha.arce__RAR_rating_tool_id__c).equalsIgnoreCase('2021RTC_GEN') && String.valueOf(aha.arce__ffss_for_rating_id__r.arce__ffss_certification_type__c).equalsIgnoreCase(arce.Arc_Gen_ffssAutomaticCorporate.CERTIFICATION_LBO)) {
        if (String.isBlank(varsList[0].arce__rating_override_comment__c) || (String.isBlank(varsList[0].arce__adj_long_rating_value_type__c) && String.isBlank(varsList[0].arce__adj_short_rating_value_type__c))) {
          responseMap.put('status', 'Error');
          responseMap.put('message', System.Label.arce.Arc_Gen_LBO_Override_Mandatory);
        }
      }
    }
    return responseMap;
  }

  /**
  * -----------------------------------------------------------------------------------------------
  * @description Method that obtains the response of the persistence Data Esg service
  * -----------------------------------------------------------------------------------------------
  * @param String ahaId - Selected account has analysis id
  * @return ValidatedByResponse - response of the persistence Esg service
  * @example ValidatedByResponse response =  callPersistenceDataEsg(ahaId)
  * -----------------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static ValidatedByResponse callPersistenceDataEsg(String ahaId) {
    arce.Arc_esg_ToolkitWrapper.ResposeWrapper response = new arce.Arc_esg_ToolkitWrapper.ResposeWrapper();

    if (ahaId == 'test') {
      response.success = false;
      response.message = 'No exist this account has analysis';
    } else {
      //Get aha information
      final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> { ahaId })[0];
      final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(aha);
      final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> {clientId}).get(clientId);
      final String corrctAccNum = accWrapper.accNumber;

      final String toolkitId = arce.Arc_Gen_Account_Locator.getToolkitId(corrctAccNum);
      response = arce.Arc_esg_Toolkit.getToolkit(toolkitId, ahaId);
    }

    return createResponseObj(null, response.success, response.message);
  }

  /**
  * -----------------------------------------------------------------------------------------------
  * @description Method that obtains the metadata to know if the persistance is active
  * -----------------------------------------------------------------------------------------------
  * @return isPersistanceActive - Boolean if is active
  * @example Boolean isPersistanceActive =  isPersistanceActive()
  * -----------------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Boolean isPersistanceESGActive() {
    final Boolean isPersistanceActive = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ArceEsgActivated')[0].arce__Value1__c);

    return isPersistanceActive;
  }

  /**
  * @description validates Parent Subsidiary data from web service
  * @author aleksandar.dinkov.contractor@bbva.com | 10-02-2024
  * @param String ahaId
  * @return MessageResponse
  **/
  @AuraEnabled
  public static Arc_Gen_ValidatePS.MessageResponse validateParentSubsidiary(Id ahaId, Boolean isTest) {
    return Arc_Gen_ValidatePS.callParentSubsidiary(ahaId, isTest);
  }

  /**
    * @description Refresh Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static Map<String, Object> refreshParentSubsidiary(Id ahaId, Boolean isTest) {
      Callable serviceClass = (Callable) Type.forName(PS_SERVICE_CLASS_NAME).newInstance();
      final Object callableResponse = serviceClass.call('callParentSubsidiary', new Map<String, Object> {'ahaId' => ahaId});
      return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(callableResponse));
  }


    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get the configuration values to use in the component
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        22-05-2024
    * @return      Serialized JSON with the configuration values
    * @example     String configValues = getArceConfigs()
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getArceConfigs() {
        final List<String> configNames = new List<String>{ 'EnableRatingSystem','Enable_Validate_Override_LBO' };

        final Map<String, String> arceConfMap = new Map<String, String>();
        for (String configName : configNames) {
            final List<arce__Arce_Config__mdt> arceConfList = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(
                configName
            );
            for (arce__Arce_Config__mdt arceConf : arceConfList) {
                arceConfMap.put(arceConf.arce__Config_Name__c, arceConf.arce__Value1__c);
            }
        }

        return JSON.serialize(arceConfMap);
    }
    /**
    * @description Execute Data Quality validations
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static Map<String,Object> dataQuality(Id ahaId) {
      Map<String,Object> response = new Map<String,Object> {'status' => 'Success', 'message' => 'OK'};
      final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId });
      if (!ahaList.isEmpty() && ahaList[0].arce__RAR_rating_tool_id__c != '2021RTC_EXPG') {
        arce.Arc_Gen_DataQuality dataQuality = new arce.Arc_Gen_DataQuality();
        response = (Map<String,Object>) JSON.deserializeUntyped(dataQuality.executeDataQuality(ahaId));
      }
      return response;
    }

    /**
    * @description Refresh Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static Map<String,Object> refreshParentRating(Id ahaId, Boolean isTest) { 
      arce.Arc_Gen_DataQuality dataQuality = new arce.Arc_Gen_DataQuality();
      return (Map<String,Object>) JSON.deserializeUntyped(dataQuality.refreshParentRating(ahaId));
    }


    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the sale engine and retrieve true o false
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @param recordId - Id of the account_has_analysis
    * @return Boolean - result of the services
    * @example getSalesEngine(recordId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_gen_Sales_Service.ResponseWrapper getSalesEngine(String ahaId) {
      final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
      final Arc_gen_Sales_Service.ResponseWrapper response;
      final Boolean avoidSales = ahaList[0].arce__IRP_Workflow__c == 'ARP' || ahaList[0].arce__IRP_Workflow__c == 'CRP' || ahaList[0].arce__RAR_rating_tool_id__c.contains('2021') ? true : false;      if(Arc_Gen_RatingAsIndepProcess_controller.isSalesEngineConfig() && !avoidSales) {
        response = Arc_Gen_RatingAsIndepProcess_controller.getSalesEngine(ahaId, ahaList[0].arce__Analysis__r.arce__rating_prerating_type__c);
      } else {
        response = new Arc_gen_Sales_Service.ResponseWrapper(false, 'Config Deactive', ahaId, null);
      }
      System.debug(response);

      return response;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that return flag if LA is needed
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.tech@bbva.com
    * @Date     Created: 2025-02-11
    * @param ahaId - Id of the account_has_analysis
    * @return Boolean - result of flag
    * @example getParentCondition(ahaId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/

    public static Boolean getParentCondition(String ahaId) {
      final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
      final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasAnalysis);
      final arce.Arc_Gen_Account_Wrapper actualClient = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String> { clientId }).get(clientId);
      Boolean resultFlag = false;
      final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
      resultFlag =  actualClient.entityType == 'ENTITY' ? false : true;
      return resultFlag;
    }
}