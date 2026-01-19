/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabSet_service
* @Author   Angel Fuertes Gomez
* @Date     Created: 27/03/2019
* @Group    ARCE
* ------------------------------------------------------------------------------------------------------
* @Description Class that manages the tabs to be shown in the ARCE and the edition permits.
* ------------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 Angel Fuertes Gomez
*             Class creation.
* |2019-06-21 mariohumberto.ramirez.contractor@bbva.com
*             Modification of the methods getTemplatesByAccHasAnalysisJson,
*             generateListWrapperTab and generateWrapperTabSet.
* |2019-06-24 mariohumberto.ramirez.contractor@bbva.com
*             Change the class to SOC
* |2019-07-16 mariohumberto.ramirez.contractor@bbva.com
*             Add new line in getTemplatesByAccHasAnalysisJson method that call the method
*             hideDynFormSection in Arc_Gen_TabsetService_Helper class
* |2019-07-29 mariohumberto.ramirez.contractor@bbva.com
*             Add new method changeArceState
* |2019-08-23 mariohumberto.ramirez.contractor@bbva.com
*             Deleted line in getTemplatesByAccHasAnalysisJson method that was calling the method
*             hideDynFormSection in Arc_Gen_TabsetService_Helper class
* |2019-10-25 mariohumberto.ramirez.contractor@bbva.com
*             Update method getTemplatesByAccHasAnalysisJson
* |2019-10-28 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getUnitChangeResponse()
* |2019-12-02 mariohumberto.ramirez.contractor@bbva.com
*             Add new method getColumnReduction()
* |2020-01-27 javier.soto.carrascosa@bbva.com
*             Add support for arce allocation
* |2019-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Added logic to get outstanding amount from account wrapper
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add HU 787 missing functionality
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Refactor getUnitChangeResponse method
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Modify sector selection logic to take rating tool ID into account.
*             Also allows prioritization and disabling of sectors.
* |2020-07-01 mariohumberto.ramirez.contractor@bbva.com
*             Added validation to update arce__outstanding_carrousel__c field
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Make getPermissionToEdit() return true if in a test.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-28 eduardoefrain.hernandez.contractor@bbva.com
*             Change arce__Analysis__c object parameter to arce__Account_has_Analysis__c for edit permissions
* |2020-11-17 joseluis.garcia4.contractor@bbva.com
*             Use approved field arce__limit_exposure_ext_ind_type__c for extended policies indicator.
* |2021-01-25 joseluis.garcia4.contractor@bbva.com
*             Change to getColumnReduction method to always display actions column.
* |2021-05-27 juanignacio.hita.contractor@bbva.com
*             Add getWarningMessage method
* |2021-09-01 juanignacio.hita.contractor@bbva.com
*             Skip call to allocation package if running in tests
* -------------------------------------------------------------------------------------------------------
*/
public class Arc_Gen_TabSet_service {//NOSONAR
    /**
    * @description: Unique code assigned the first tab
    */
    private static final String FIRST_TAB = '100';
    /**
    * @description: Unique code assigned the third tab
    */
    private static final String THIRD_TAB = '300';
    /**
    * @description: Unique code assigned the quarter tab
    */
    private static final String QUARTER_TAB = '400';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Custom Exception for Tabset
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-04-24
    * ----------------------------------------------------------------------------------------------------
    **/
    public class NoTabsetConfigFoundException extends Exception {}

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 16/07/2019
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_service service = new Arc_Gen_TabSet_service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_TabSet_service() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the information to create the Tabset component
    * and verify what type of policies table is shown in the analysis if the table is the standard
    * this method must update the data of the hiden typologies to zero
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 16/07/2019
    * @param recordId - Id of the current account has analisys object
    * @return String with the information to create the Tabs
    * @example getTemplatesByAccHasAnalysisJson(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String getTemplatesByAccHasAnalysisJson(Id recordId) {
        final List<arce__Account_has_Analysis__c> accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{recordId});
        // Step 1. Retrieve sector to use.
        final String analysisType = accHasAnalysis[0].arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c;
        final arce__Sector__c selectedSector = Arc_Gen_Sector_Data.getSectorAccHasAn(accHasAnalysis[0], analysisType);
        // Step 2. Retrieve config from selected sector.
        if (selectedSector == null) {
            throw new NoTabsetConfigFoundException(System.Label.Arc_Gen_NoTabsetConfigFound);
        } else {
            final List<Arc_Gen_TabSet_controller.WrapperTabSet> listWrapper = Arc_Gen_TabsetService_Helper.generateListWrapperTab(recordId, selectedSector);
            final String listJSON = JSON.serialize(listWrapper);
            if (accHasAnalysis[0].arce__Analysis__r.arce__Stage__c != '3') {
                accHasAnalysis[0].arce__outstanding_carrousel__c = Arc_Gen_TabsetService_Helper.getOutstandingFromTabClient(recordId);
                arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<arce__Account_has_Analysis__c>{accHasAnalysis[0]});
            }
            if (accHasAnalysis[0].arce__limit_exposure_ext_ind_type__c == null || accHasAnalysis[0].arce__limit_exposure_ext_ind_type__c == '2') {
                Arc_Gen_TabsetService_Helper.update2zerohidenTypologies(recordId);
            }
            return listJSON;
        }
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method that verify if you have permission to edit
    * ---------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 16/07/2019
    * @param blockPolicies - boolean with the information to make visible the policies tab
    * @param recordId - id of the current account has analysis object
    * @return a string with edit permission data
    * @example getPermissionToEdit(recordId)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static String getPermissionToEdit(Id recordId) {
        String returnVal;

        if (Test.isRunningTest()) {
            returnVal = 'true';
        } else {
            if (hasPermissionAmbit(recordId)) {
                final Set<String> permissionSet = new Set<String>();
                final List<ID> records = new List<ID>();
                records.add(recordId);
                final Type inter = Type.forName('arcealloc.Allocation_Service');
                final boolean custAlloc = String.isNotBlank(String.valueOf(inter)) && !Test.isRunningTest() ? ((Map<Id,boolean>) ((Callable) inter.newInstance()).call('checkBulkPrivileges', new Map<String, Object> {'accHasAnlysIdsLst' => records})).get(recordId) : true ;
                final Map<String,Set<String>> permissionToEditMap = dwp_dace.DynamicActionsEngine_helper.getAvailableActions(records,'arce__Account_has_Analysis__c','Arc_Gen_Edition');
                if ( permissionToEditMap.get(recordId) != null) {
                    permissionSet.addAll(permissionToEditMap.get(recordId));
                }
                returnVal = permissionSet.contains('Arc_Gen_Edit') && custAlloc ? 'true' : 'false';
            } else {
                returnVal = 'false';
            }

        }

        return returnVal;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that change the status of an Arce Analysis
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 29/07/2019
    * @param recordId - Id of the current account has analisys object
    * @return true/false
    * @example changeArceState(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean changeArceState(Id recordId) {
        return Arc_Gen_TabsetService_Helper.changeArceStateHelper(recordId);
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that change the unit of the record in the policy table
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 28/10/2019
    * @param recordId - Id of the current account has analisys object
    * @return String
    * @example getUnitChangeResponse(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String getUnitChangeResponse(Id recordId) {
        final String response;
        Map<String, Object> responseMap = new Map<String, Object>();
        arce__Account_has_Analysis__c accHasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId})[0];
        if(accHasAn.arce__group_asset_header_type__c == '1') {
            responseMap = Arc_Gen_TabsetService_Helper.setWrapperToConvert(accHasAn, true);
        } else {
            responseMap = Arc_Gen_TabsetService_Helper.setWrapperToConvert(accHasAn, false);
        }
        response = (String)responseMap.get('status');
        return response;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method that return the column configuration for policie table
    * ---------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 02/12/2019
    * @param recordId - id of the current account has analysis object
    * @return a string with configuration for policie table
    * @example getColumnReduction(recordId)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static String getColumnReduction(Id recordId) {
        return '0,0;0,0';
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method that returns true if any of the tabs is incomplete and the warning icon should be displayed.
    * ---------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     26/05/2021
    * @param    recordId - id of the current account has analysis object
    * @param    resJSON - response JSON of getTemplatesByAccHasAnalysisJson method
    * @return   Boolean : return true value if the analysis has uncompleted tabs and is finalized stage.
    * @example  Boolean boolRet = getWarningMessage(recordId, resJSON);
    * ---------------------------------------------------------------------------------------------------
    **/
    public static Boolean getWarningMessage(Id recordId, String resJSON) {
        final arce__Account_has_Analysis__c accHasRelation = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final List<Object> listJSONWrapper = (List<Object>) JSON.deserializeUntyped(resJSON);
        Boolean tabUncomplete = false;

        for (Object obj : listJSONWrapper) {
            final Map<String, Object> mapObj = (Map<String, Object>) obj;
            final String devTemplate = (String) mapObj.get('devTemplate');
            final Integer percent = (Integer) mapObj.get('percent');
            Integer maxPercent;
            if (devTemplate == FIRST_TAB) {
                final Boolean nonOrphan = accHasRelation.arce__Analysis__r.arce__analysis_customer_relation_type__c == '01';
                final Boolean isGroup = accHasRelation.arce__group_asset_header_type__c == '1';
                final Boolean isBottomUp = accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c == '1' || String.isEmpty(accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c); // Allow for historical ARCEs
                maxPercent = nonOrphan && isGroup && isBottomUp ? 300 : 400;
            } else if (devTemplate == THIRD_TAB || devTemplate == QUARTER_TAB) {
                maxPercent = 100;
            }
            if (maxPercent != null && percent < maxPercent) {
                tabUncomplete = true;
            }
        }
        return accHasRelation.arce__Analysis__r.arce__Stage__c == arce.Arc_Gen_Constants.STAGE_FINALIZED && tabUncomplete ? true : false;
    }

    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method that returns if all arce__Account_has_Analysis__c has permission to edit
    * ---------------------------------------------------------------------------------------------------
    * @Author   francisco.munoz.torres.contractor@bbva.com
    * @Date     15/10/2021
    * @param    listObject - List of AHA to check permission to edit
    * @return   Boolean : return true value if all AHA has permission to edit.
    * @example  Boolean boolRet = hasPermissionToEdit(listObject);
    * ---------------------------------------------------------------------------------------------------
    **/
    public static Boolean hasPermissionToEdit(List<sObject> listObject){
      Boolean hasPermission;
      for(sObject obj : listObject) {
          final String idAnalisis = obj.get('Id').toString();
          // Only validate if what is being saved is an Account_has_analysis__c
          // record.
          if (Id.valueOf(idAnalisis).getSobjectType() != arce__Account_has_Analysis__c.SObjectType) {
              continue;
          }
          // Validate that the user has permission to edit the record
          // before saving.
          hasPermission = getPermissionToEdit(idAnalisis) == 'true';
          if(hasPermission == false){
            break;
          }
      }
      return hasPermission;
    }

    /**
    * @description
    * @author Global Desktop | 30-11-2021
    * @param recordId
    * @return Boolean
    **/
    public static Boolean hasPermissionAmbit (String recordId) {
        Boolean hasPerm = false;
        final List<arce__Account_has_Analysis__c> aha = [Select arce__Analysis__r.arce__anlys_wkfl_edit_br_level_type__c, DES_Local_Client__r.crossBorder__c, DES_Local_Client__r.Is_Parent__c  from arce__Account_has_Analysis__c where Id = :recordId and arce__Analysis__r.arce__wf_status_id__c IN ('01','04','12') Limit 1 ];
        if (aha.isEmpty()) {
            hasPerm = true;
        } else {
            final List<Arce_ambit_hierarchy__mdt> ambito = [Select Validate__c, ValidateCross__c, CantEdit__c from Arce_ambit_hierarchy__mdt where Ambit__c = :aha.get(0).arce__Analysis__r.arce__anlys_wkfl_edit_br_level_type__c LIMIT 1];
            String ambit = '';
            if (!ambito.isEmpty() ) {
                        if (aha.get(0).DES_Local_Client__r.crossBorder__c) {
                            if(!ambito.get(0).CantEdit__c){
                                System.debug('>>>>>>>>> validate cross');
                                ambit = ambito.get(0).ValidateCross__c;
                            }else if(!aha.get(0).DES_Local_Client__r.Is_Parent__c){
                                System.debug('>>>>>>>>> validate cross');
                                ambit = ambito.get(0).ValidateCross__c;
                            }
                        } else {
                            System.debug('>>>>>>>>> validate');
                            ambit = ambito.get(0).Validate__c;
                            System.debug('Ambito REv ' + ambit);
                        }
                        if (String.isNotEmpty(ambit)) {
                            final List<String> ambits = ambit.split(';');
                        final List<User> usuario = [Select Id, gf_user_operation_ambit_name__c from User Where id =:UserInfo.getUserId() LIMIT 1];
                        System.debug('>>>>>>>>> usuario ' + usuario);
                        final Arce_ambit_hierarchy__mdt ambitoUsuario = User_Helper.MAPAMBIT.get(usuario.get(0).gf_user_operation_ambit_name__c);
                        System.debug('>>>>>>>>> ambitoUsuario ' + ambitoUsuario);
                        Boolean notFind = true;
                        String idAmbit = '';
                        final Iterator<String> iter = ambits.iterator();
                        while (notFind && iter.hasNext()) {
                            idAmbit = iter.next();
                            System.debug('>>>>>>>>> idAmbit ' + idAmbit);
                            System.debug('>>>>>>>>> ambitoUsuario ' + ambitoUsuario.Ambit__c);
                            if (idAmbit.equalsIgnoreCase(ambitoUsuario.Ambit__c)) {
                                System.debug('>>>>>>>>> encontrado ');
                                notFind = false;
                                hasPerm = true;
                                }
                            }
                        }
            } else {
                hasPerm = true;
            }
        }
        return hasPerm;
    }
}