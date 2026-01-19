/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_BasicData_Pers_service
* @Author   Javier Soto Carrascosa
* @Date     Created: 04/042020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages save for Basic Data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-04 Javier Soto Carrascosa
*             Class creation.
* |2020-09-02 Javier Soto Carrascosa
*             Update from release 3 testing
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-22 Juan Ignacio Hita Manso
*             Add updateComplexityPath that update complexity path of analysis
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__sector_desc__c and arce__subsector_desc__c for arce__sector_id__c and arce__subsector_id__c
* |2021-05-18 Juan Manuel Perez Ortiz
*             Modified updateComplexityPath to control decimals
* |2021-06-17 Juan Ignacio Hita Manso
*             Rollback 2020-03-12 commit (PR: 1231)
* |2021-06-14 juanignacio.hita.contractor@bbva.com
*             Changes field that mapping HAS_PREVIOUS_LEVERAGE param
* |2021-06-28 juanignacio.hita.contractor@bbva.com
*             Adds validation for save only AHA objects in save method
* |2021-06-29 juanignacio.hita.contractor@bbva.com
*             Refactoring save method to call the common BusinessRisk build request method. Remove unused methods
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_BasicData_Pers_service implements dyfr.Save_Interface {//NOSONAR
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param listObject - List of the account has analisys object
    * @return String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String save(List<sObject> listObject) {
        Boolean hasPermission = Arc_Gen_TabSet_service.hasPermissionToEdit(listObject);

        String retValue;
        if (hasPermission) {
            final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
            final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String>{accHasAnalysis.arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(listacc.get(accHasAnalysis.arce__Customer__c).accNumber);
            final Boolean basicInfo = Arc_Gen_OraclePers_service.basicInfoWS(participantId, accHasAnalysis.Name, basicInfoJSON(ahaData));
            final Boolean businessRisk = Arc_Gen_OraclePers_service.businessRiskWS(participantId, accHasAnalysis.Name, managementRiskJson(ahaData));
            if (basicInfo && businessRisk) {
                updateComplexityPath(accHasAnalysis, ahaData);
            }
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_BasicData_Pers_service.class.getName()));
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(basicInfo&&businessRisk, Label.Arc_Gen_Toast_Success_Title,listObject));
        } else {
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(false, Label.Arc_Gen_Generic_NotAllowed, listObject));
        }
        return retValue;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info indicators Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @return List<Map<String, Object>> with WS structure
    * @example addIndicators(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, Object>> addIndicators(arce__Account_has_Analysis__c ahaData) {
        List<Map<String, Object>> listMapIndicators = new List<Map<String, Object>>();
        final Map<String, String> mapIndicators = new Map<String,String>{'arce__enterprise_group_type__c'=>'BELONGS_TO_ECONOMIC_GROUP', 'arce__ll_previous_anlys_ind_type__c'=>'HAS_PREVIOUS_LEVERAGE', 'arce__client_refinanced_type__c'=>'IS_REFINANCED'};
        Map<String, String> indicatorsComments = new Map<String,String>{'arce__enterprise_group_type__c'=>'arce__enterprise_group_desc__c', 'arce__client_refinanced_type__c'=>'arce__client_refinanced_desc__c'};
        for (string element : mapIndicators.keyset()) {
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(element))) {
                Map<String, Object> indicatorMap = new Map<String, Object>();
                indicatorMap.put('id',mapIndicators.get(element));
                indicatorMap.put('isActive',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get(element)));
                if (arce.Arc_Gen_ValidateInfo_utils.isFilled(indicatorsComments.get(element))) {
                    indicatorMap.put('description',ahaData.get(indicatorsComments.get(element)));
                }
                listMapIndicators.add(indicatorMap);
            }
        }
        return listMapIndicators;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info indicators Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> addSector(arce__Account_has_Analysis__c ahaData, String key) {
        final Map<String, String> assetMap = new Map<String,String>{'sector'=>'arce__sector_desc__c', 'subsector'=>'arce__subsector_desc__c', 'economicActivity' => 'arce__economic_activity_sector_desc__c'};
        Map<String, Object> idMap =  new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(assetMap.get(key)))) {
            idMap.put('id',Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get(assetMap.get(key))));
        }
        return idMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info economic Activity
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> addEconom(arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> idMap =  new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__economic_activity_sector_desc__c')) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__rating_econ_sector_tmpl_id__c'))) {
            idMap.put('id',Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get('arce__economic_activity_sector_desc__c')));
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__rating_econ_sector_tmpl_id__c'))) {
                idMap.put('assetTemplate',ahaData.get('arce__rating_econ_sector_tmpl_id__c'));
            }
        }
        return idMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for basic-info WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for Basic Info WS
    * @example basicInfoJSON(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> basicInfoJSON (arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> finalWSMap = new Map<String, Object>();
        final List<Map<String, Object>> indicators = addIndicators(ahaData);
        final Map<String, Object> sector = addSector(ahaData, 'sector');
        final Map<String, Object> subsector = addSector(ahaData, 'subsector');
        final Map<String, Object> economicActivity = addEconom(ahaData);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilled(finalWsMap,'economicActivity',economicActivity);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilled(finalWsMap,'subsector',subsector);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilledList(finalWsMap,'indicators',indicators);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilled(finalWsMap,'sector',sector);
        return finalWSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Updates the complexity value of the path for analysis
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 22/02/2021
    * @param   arce__Account_has_Analysis__c ahaOld
    * @param   arce__Account_has_Analysis__c ahaNew
    * @return  void
    * @example updateComplexityPath(listObject, ahaOld, ahaNew);
    * -----------------------------------------------------------------------------------------------
    **/
    public static void updateComplexityPath(arce__Account_has_Analysis__c ahaOld, arce__Account_has_Analysis__c ahaNew) {
        Integer averagePath;
        List<arce__Account_has_Analysis__c> lstAccHas = new List<arce__Account_has_Analysis__c>();
        if (ahaOld.arce__path__c != ahaNew.arce__path__c && ahaNew.arce__path__c != null) {
            final Map<String, Integer> complexityPath = arce.Arc_Gen_GenericUtilities.getConfigComplexityPath();
            Integer complexAha = 0;
            // Update path complexity of the analysis
            lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{ahaOld.arce__Analysis__r.Id});
            for (arce__Account_has_Analysis__c aha : lstAccHas) {
                if (aha.arce__path__c != null && aha.arce__path__c != '') {
                    if (aha.Id == ahaOld.Id) {
                        // Update value complexity path
                        aha.arce__complexity_path_id__c = complexityPath.get(ahaNew.arce__path__c);
                        complexAha += complexityPath.get(ahaNew.arce__path__c);
                    } else {
                        complexAha += complexityPath.get(aha.arce__path__c);
                    }
                }
            }
            final Double calcAverage = getCalcAverage(complexAha, lstAccHas);
            averagePath = Math.round(calcAverage);
        }
        final Map<String, Object> fieldValueMap = new Map<String, Object> {
            'arce__gf_destination_path_id__c' => String.valueOf(averagePath)
        };
        // Update AHA
        update(lstAccHas);

        // Update ARCE
        arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(ahaOld.arce__Analysis__c, fieldValueMap);
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that calculate average path complexity
    * -----------------------------------------------------------------------------------------------
    * @Author  Juan Manuel Perez Ortiz
    * @Date     Created: 18/05/2021
    * @param Integer - complexAha
    * @param List<arce__Account_has_Analysis__c> - lstAccHas
    * @return Double - with average path complexity
    * @example getCalcAverage(complexAha, lstAccHas)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Double getCalcAverage (Integer complexAha, List<arce__Account_has_Analysis__c> lstAccHas) {
        Double calcAverage = complexAha > 0 ? (Double) complexAha / lstAccHas.size() : 0.0;
            if (calcAverage > 0.0 && calcAverage < 1.0) {
                calcAverage = 1.0;
            }
        return calcAverage;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for basic-info WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for Basic Info WS
    * @example businessRiskJSON(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> managementRiskJson (arce__Account_has_Analysis__c ahaData) {
      Map<String, Object> finalManagementMap = new Map<String, Object>();
      Map<String, Object> finalWSMap = new Map<String, Object>();
      final Map<String, Object> managementExperience = addManagementSub(ahaData, 'managementExperience');
      if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(managementExperience)) {
          final Map<String, Object> riskProfile = addManagementSub(ahaData, 'riskProfile');
          final Map<String, Object> managementStyle = addManagementSub(ahaData, 'managementStyle');
          finalManagementMap = Arc_Gen_Persistence_Utils.addifFilled(finalManagementMap,'managementExperience',managementExperience);
          finalManagementMap = Arc_Gen_Persistence_Utils.addifFilled(finalManagementMap,'riskProfile',riskProfile);
          finalManagementMap = Arc_Gen_Persistence_Utils.addifFilled(finalManagementMap,'managementStyle',managementStyle);
      }
      if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(finalManagementMap)) {
          finalWSMap.put('management',finalManagementMap);
      }
      return finalWSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info indicators Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> addManagementSub (arce__Account_has_Analysis__c ahaData, String key) {
        Map<String, String> managementMap = new Map<String,String>{'managementExperience'=>'arce__years_experience_mngmt_type__c', 'riskProfile'=>'arce__mngmt_aggressiveness_type__c', 'managementStyle' => 'arce__management_style_type__c'};
        Map<String, String> commentsMap = new Map<String,String>{'managementExperience' => 'arce__years_experience_mngmt_desc__c','riskProfile' => 'arce__fin_aggressiveness_mngmt_desc__c','managementStyle' => 'arce__management_style_desc__c'};
        Map<String, Object> idMap =  new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(managementMap.get(key)))) {
            String enumValue = managementEnum((String)ahaData.get(managementMap.get(key)),key);
            idMap.put('id',enumValue);
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(commentsMap.get(key)))) {
                idMap.put('comments',ahaData.get(commentsMap.get(key)));
            }
        }
        return idMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for basic-info WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param String - value
    * @param string - key
    * @return Map<String, Object> with WS structure for Basic Info WS
    * @example managementEnum(value, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String managementEnum (String value, String key) {
        final Map<String, String> experience = new Map<String, String>{'1'=>'FROM_0_TO_5','2'=>'FROM_6_TO_10','3'=>'MORE_THAN_10'};
        final Map<String, String> aggressiveness = new Map<String, String>{'1'=>'AGGRESSIVE','2'=>'MEDIUM','3'=>'CONSERVATIVE'};
        final Map<String, String> profileInvestor = new Map<String, String>{'1'=>'PERSONALIST','2'=>'PROFESSIONAL','3'=>'FAMILIAR'};
        final Map<String, Map<String, String>> enumMaps = new Map<String, Map<String, String>>{'managementStyle'=>profileInvestor,'managementExperience'=>experience,'riskProfile'=>aggressiveness};
        final Map<String, String> mapForKey = enumMaps.get(key);
        return Arc_Gen_Persistence_Utils.getEnumFromMap(value, mapForKey);
    }
}