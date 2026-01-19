/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Customer_Data
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class for Arc_Gen_Validate_Customer_Service.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-10-03 mariohumberto.ramirez.contractor@bbva.com
*             Change the method checkCustomerFlag, now return a List<arce__Account_has_Analysis__c>
* |2019-12-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getFieldStageControl
* |2019-12-04 manuelhugo.castillo.contractor@bbva.com
*             Modify method 'getNameClient' replace Account to AccountWrapper
* |2020-17-01 mariohumberto.ramirez.contractor@bbva.com
*             Change arce__Customer__r.ParentId for arce__group_asset_header_type__c in queries
* |2020-17-06 mariohumberto.ramirez.contractor@bbva.com
*             Add state 06 to match 08 functionalities in changeStatusArce method
* |2020-08-12 antonio.munoz.perez.contractor@bbva.com
*             Added new getIdsOfAHA method
* |2020-08-11 juanignacio.hita.contractor@bbva.com
*             Add checkCurrencyAHA method
* |2020-08-27 joseluis.garcia4.contractor@bbva.com
*             Add getAhaWithLeveragedInfo method
* |2020-11-17 juanignacio.hita.contractor@bbva.com
*             Add getConfSectionName method
* |2021-02-08 mariohumberto.ramirez.contractor@bbva.com
*             Fixed error caused by hidden fields
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |2021-03-15 juanignacio.hita.contractor@bbva.com
*             Add arce__status_limit_pers_service__c field in checkCustomerFlag
* |2021-06-07 mariohumberto.ramirez.contractor@@bbva.com
*             Added new filter in the method getFieldsBySection
* |2021-06-15 mariohumberto.ramirez.contractor@@bbva.com
*             Added getGroupControl method
* |2021-08-20 juanignacio.hita.contractor@bbva.com
*             Adds ORDER BY condition in query of getExposures method
* |2021-10-18 juanignacio.hita.contractor@bbva.com
*             Invokes traceability event creation in thje changeStatusArce method
* |2022-10-18 juanignacio.hita.contractor@bbva.com
*             Add field query to getAhaWithLeveragedInfo method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidSoqlWithNegativeLogic,sf:TooManyMethods')
public without sharing class Arc_Gen_Validate_Customer_Data {

    /**
    * @Description: string with the value of preparing analysis status
    */
    static final string PENDING_SANCTION = '08';
    /**
    * @Description: string with value of contrasting analysis status
    */
    static final string IN_SANCTION = '2';
    /**
        * @Description: Validation section custom metadata name config
    */
    static final string VAL_CONFIGNAME = 'ValidateCustomer_SectionsDyfr';
    /**
        * @Description: 'Active' literal
    */
    static final string ACTIVE_LIT = 'Active';
    /**
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Data data = new Arc_Gen_Validate_Customer_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Validate_Customer_Data() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns the import of the typologies.
    * --------------------------------------------------------------------------------------
    * @param accHasAId - Ids of the object arce__Account_has_Analysis__c
    * @return a List<arce__limits_exposures__c> that contain the import of the typologies
    * @example getImport(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__limits_exposures__c> getExposures(List<string> accHasAId) {
        return [SELECT arce__limits_typology_id__c,arce__limits_typology_id__r.Name, arce__limits_typology_id__r.arce__risk_typology_parent_id__c, arce__limits_typology_id__r.arce__risk_typology_level_id__c, arce__Product_id__c, arce__Product_id__r.Name, arce__limits_exposures_parent_id__c, Id,  arce__account_has_analysis_id__r.arce__Customer__r.Name, arce__current_approved_amount__c, arce__curr_apprv_uncommited_amount__c, arce__curr_approved_commited_amount__c, arce__current_formalized_amount__c, arce__outstanding_amount__c, arce__current_proposed_amount__c, arce__last_approved_amount__c, arce__curr_apprv_deleg_rm_amount__c, arce__current_apprv_limit_term_id__c
        FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :accHasAId AND arce__account_Id__c = null ORDER BY arce__Product_id__c];
    }
    /**
    * -----------------------------------------------------------------------------------------
    * @Description check how many clients exist in the arce Analisys
    * -----------------------------------------------------------------------------------------
    * @param accHasAId Id of the object arce__Account_has_Analysis__c
    * @return a List<arce__Account_has_Analysis__c> that contain the id of the filial clients
    * @example checkGroup(accHasAId)
    * -----------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c checkGroup(string accHasAId) {
        return [SELECT arce__Customer__c, arce__anlys_wkfl_cnsld_ffss_type__c, arce__Customer__r.Name,arce__Customer__r.ParentId, arce__Analysis__c, arce__Analysis__r.arce__Group__c, arce__Analysis__r.arce__Group__r.Name FROM arce__Account_has_Analysis__c WHERE Id = :accHasAId];
    }

    /**
    * -----------------------------------------------------------------------------------------
    * @Description get AHA with Leveraged Test fields to check.
    * -----------------------------------------------------------------------------------------
    * @param accHasAId Id of the object arce__Account_has_Analysis__c
    * @return a arce__Account_has_Analysis__c that contain the AHA info
    * @example getAhaWithLeveragedInfo(accHasAId)
    * -----------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAhaWithLeveragedInfo(string accHasAId) {
        return [SELECT arce__anlys_wkfl_cnsld_ffss_type__c, arce__ll_test_scope_ind_type__c, arce__ll_before_adj_ind_type__c,
        arce__ll_after_adj_ind_type__c, arce__entity_covenants_type__c, arce__fin_covenants_breach_type__c, arce__fin_covenants_breach_desc__c FROM arce__Account_has_Analysis__c WHERE Id = :accHasAId];
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return the map fields of the policy tab
    * --------------------------------------------------------------------------------------
    * @param section contains the name of the section in dynamic form
    * @return a List<dyfr__Field_Config__c> that contain the map fields of the policy tab
    * @example getFieldsBySection(accHasAId, section)
    * --------------------------------------------------------------------------------------
    **/
    public static List<dyfr__Field_Config__c> getFieldsBySection(List<string> section , String templateName) {
        return [SELECT Id, dyfr__Section_name__c, dyfr__DeveloperName__c, dyfr__Map_field__c, dyfr__Label__c, dyfr__Visibility_control_field__c, dyfr__Visibility_control_value__c, dyfr__Visibility_condition__c FROM dyfr__Field_Config__c WHERE dyfr__Section_name__c = :section AND dyfr__Tab__r.dyfr__Template__r.Name = :templateName AND dyfr__Type__c != 'lightning component' AND dyfr__Read_only__c = false AND dyfr__Type__c != 'blank' AND dyfr__Hidden__c = false AND dyfr__Important__c = true];
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return the data of the stage control field
    * --------------------------------------------------------------------------------------
    * @param mapfield - api name of the field
    * @return a dyfr__Field_Config__c object
    * @example getFieldStageControl(accHasAId, section)
    * --------------------------------------------------------------------------------------
    **/
    public static dyfr__Field_Config__c getFieldStageControl(String mapField, String templateName) {
        return [SELECT Id, dyfr__Section_name__c, dyfr__DeveloperName__c, dyfr__Map_field__c, dyfr__Label__c, dyfr__Visibility_control_field__c, dyfr__Visibility_control_value__c, dyfr__Visibility_condition__c FROM dyfr__Field_Config__c WHERE dyfr__Map_field__c = :mapField AND dyfr__Tab__r.dyfr__Template__r.Name = :templateName AND dyfr__Type__c != 'lightning component' AND dyfr__Type__c != 'blank'];
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * @Description return the real values in some fields of the policy tab
    * ----------------------------------------------------------------------------------------------
    * @param accHasAId Id of the object arce__Account_has_Analysis__c
    * @param mapfields contains the name of the map fields in dynamic form
    * @return a List<arce__Account_has_Analysis__c> that contains the real values in some fields of
    * the policy tab
    * @example getValues(accHasAId, mapfields)
    * ----------------------------------------------------------------------------------------------
    **/
    public static List<arce__Account_has_Analysis__c> getValues(string accHasAId, string mapfields) {
        final string query = String.escapeSingleQuotes('SELECT ' + mapfields + ' FROM arce__Account_has_Analysis__c WHERE Id = :accHasAId');
        return Database.query(query);
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * @Description return the ids of child accounts
    * ----------------------------------------------------------------------------------------------
    * @param parenId Account
    * @return a List<arce__Account_has_Analysis__c> that contains the child ids of a parent account
    * @example getIdsOfChildAccount(parenId)
    * ----------------------------------------------------------------------------------------------
    */
    public static List<arce__Analysis__c> getIdsOfChildAccount(Id groupId, Id arceId) {
        return [SELECT Id, (SELECT Id, arce__Customer__c, arce__Customer__r.Name From arce__Account_has_Analysis__r WHERE arce__InReview__c = true AND arce__group_asset_header_type__c = '2') FROM arce__Analysis__c WHERE arce__Group__c = :groupId AND Id = :arceId];
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * @Description return the ids of related accounts
    * ----------------------------------------------------------------------------------------------
    * @param groupId Account
    * @param arceId arce__Analysis__c
    * @return a List<arce__Analysis__c> that contains the data from arce__Account_has_Analysis__r childs of an analysis given the related group ID
    * @example getIdsOfAHA(groupId, arceId)
    * ----------------------------------------------------------------------------------------------
    */
    public static List<arce__Analysis__c> getIdsOfAHA(Id groupId, Id arceId) {
        return [SELECT Id, (SELECT Id, arce__Customer__c, arce__Customer__r.Name From arce__Account_has_Analysis__r WHERE arce__InReview__c = true) FROM arce__Analysis__c WHERE arce__Group__c = :groupId AND Id = :arceId];
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return the name of an account
    * --------------------------------------------------------------------------------------
    * @param id of arce__account_has_analysis_id__c
    * @return a string that contains the name of an account
    * @example getNameClient(id)
    * --------------------------------------------------------------------------------------
    **/
    public static string getNameClient(string idAha) {
        final arce__Account_has_Analysis__c customer = [SELECT arce__Customer__c FROM arce__Account_has_Analysis__c WHERE Id = :idAha];
        final List<Id> lstIds = new List<Id>{customer.arce__Customer__c};
        final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrap = arce.Arc_Gen_Account_Locator.getAccountInfoById(lstIds);
        return accWrap.get(customer.arce__Customer__c).name;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that active a customer Flag
    * --------------------------------------------------------------------------------------
    * @param recordId Id of arce__account_has_analysis_id__c
    * @return void
    * @example activeCustomerFlag(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static void activeCustomerFlag(string recordId, string cases) {
        if (cases == ACTIVE_LIT) {
            final arce__Account_has_Analysis__c arceAccHasAn = [SELECT id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE Id = :recordId];
            arceAccHasAn.arce__arce_ctmr_flag__c = true;
            upsert arceAccHasAn;
        } else {
            final arce__Account_has_Analysis__c arceAccHasAn = [SELECT id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE Id = :recordId];
            arceAccHasAn.arce__arce_ctmr_flag__c = false;
            upsert arceAccHasAn;
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to consult the field arce__arce_ctmr_flag__c
    * --------------------------------------------------------------------------------------
    * @param ids - List<Id> of arce__account_has_analysis_id__c
    * @return List<arce__Account_has_Analysis__c>
    * @example checkCustomerFlag(ids)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__Account_has_Analysis__c> checkCustomerFlag(List<Id> ids) {
        return [SELECT id, arce__arce_ctmr_flag__c, arce__Customer__r.Name, arce__status_limit_pers_service__c FROM arce__Account_has_Analysis__c WHERE Id = :ids];
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that change the status of an Arce Analysis
    * --------------------------------------------------------------------------------------
    * @param recordId Id of arce__account_has_analysis_id__c
    * @return void
    * @example changeStatusArce(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static void changeStatusArce(string recordId) {
        final Id arceId = [SELECT arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE Id = :recordId].arce__Analysis__c;
        final List<arce__Account_has_Analysis__c> accHasAnLts = arce.Arc_Gen_GenericUtilities.getAccHasAnalysis(arceId);
        for (arce__Account_has_Analysis__c acchasAn: accHasAnLts) {
            acchasAn.arce__arce_ctmr_flag__c = false;
            acchasAn.arce__anlys_wkfl_sbanlys_status_type__c = '3';
        }
        final arce__Analysis__c analysis = [SELECT id,arce__wf_status_id__c,arce__Stage__c,arce__Temporal_status__c FROM arce__Analysis__c WHERE id=:arceId];
        if(analysis.arce__wf_status_id__c == PENDING_SANCTION && analysis.arce__Stage__c == IN_SANCTION) {
            analysis.arce__wf_status_id__c = '08';
        } else if(analysis.arce__wf_status_id__c == '06' && analysis.arce__Stage__c == IN_SANCTION) {
            analysis.arce__wf_status_id__c = '06';
        } else {
            analysis.arce__wf_status_id__c = '03';
        }
        analysis.arce__Temporal_status__c = true;

        // Create current action traceability event record
        final arce__Analysis__c arceAnalysisPost = arce.Arc_Gen_ArceAnalysis_Data.gerArce(recordId);
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(recordId, new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });
        Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, accHasAnalysis, arceAnalysisPost, 'VALIDATE');
        wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

        // Insert new trace record and last update
        Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);

        upsert analysis;
        upsert accHasAnLts;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that get the currency of the AHA
    * --------------------------------------------------------------------------------------
    * @param ids - List<Id> of arce__account_has_analysis_id__c
    * @return List<arce__Account_has_Analysis__c>
    * @example checkCurrencyAHA(ids)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__Account_has_Analysis__c> checkCurrencyAHA(List<Id> ids) {
        return [SELECT Id, Name, arce__currency_id__c FROM arce__Account_has_Analysis__c WHERE Id = :ids];
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that get the configuration for validation section configurated a DynForm_ValidateSections
    *              and from a templateName
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 16/11/2020
    * @param    templateName - Name of the template
    * @return   List<String> - returns a list of string with the section names
    * @example  List<String> lstStr = getConfSectionName(templateName);
    * --------------------------------------------------------------------------------------
    **/
    public static List<String> getConfSectionName(String templateName) {
        final List<arce__Arce_Config__mdt> configValidation = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(VAL_CONFIGNAME);
        final Map<String, Object> mapObjConf = (Map<String, Object>) System.JSON.deserializeUntyped(configValidation[0].arce__Value1__c);
        final List<String> lstSections = new List<String>();
        List<Object> lstObj = new List<Object>();

        for (String key: mapObjConf.keySet()) {
            final List<String> lstTemplKey = key.split(',');
            if (lstTemplKey.contains(templateName)) {
                lstObj = (List<Object>) mapObjConf.get(key);
            }
        }
        for (Object key: lstObj) {
            lstSections.add((String) key);
        }
        return lstSections;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Desactivate the status limit persistence service flag of aha
    * --------------------------------------------------------------------------------------
    * @param String recordId : Account has analysis id
    * @return void
    * @example updateStatusLimitPers(recordId);
    * --------------------------------------------------------------------------------------
    **/
    public static void updateStatusLimitPers(String recordId, Boolean callout) {
        final arce__Account_has_Analysis__c accHas = [SELECT id, arce__status_limit_pers_service__c FROM arce__Account_has_Analysis__c WHERE Id = :recordId];
        accHas.arce__status_limit_pers_service__c = callout;
        upsert accHas;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the info of the group control field
    * --------------------------------------------------------------------------------------
    * @param mapfield - api name of the field
    * @param templateName - name of the template
    * @param sectionName - name of the section
    * @return a dyfr__Field_Config__c object
    * @example getGroupControl(mapField, templateName)
    * --------------------------------------------------------------------------------------
    **/
    public static dyfr__Field_Config__c getGroupControl(String mapField, String templateName, String sectionName) {
        return [SELECT Id, dyfr__Section_name__c, dyfr__DeveloperName__c, dyfr__Map_field__c, dyfr__Label__c, dyfr__Visibility_control_field__c, dyfr__Visibility_control_value__c, dyfr__Visibility_condition__c
                FROM dyfr__Field_Config__c
                WHERE dyfr__Map_field__c = :mapField
                    AND dyfr__Tab__r.dyfr__Template__r.Name = :templateName
                    AND dyfr__Section_name__c = :sectionName
                    AND dyfr__Type__c != 'lightning component'
                    AND dyfr__Type__c != 'blank'];
    }
}