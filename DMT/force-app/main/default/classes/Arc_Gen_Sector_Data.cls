/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Sector_Data
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 24/06/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Data class for object arce__Sector__c
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-12-18 javier.soto.carrascosa@bbva.com
*             Add wrapper
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Modify sector selection logic to take rating tool ID into account.
*             Also allows prioritization and disabling of sectors.
* |2020-05-05 juanignacio.hita.contractor@bbva.com
*             Added getMapTabSet method
* |2020-05-06 joseluis.garcia4.contractor@bbva.com
*             Add arce__anlys_wkfl_cnsld_ffss_type__c to sector selection logic.
* |2020-05-20 joseluis.garcia4.contractor@bbva.com
*             Add arce__group_asset_header_type__c to sector selection logic.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-15 joseluis.garcia4.contractor@bbva.com
*             Add customer relation type to sector selection logic.
* |2021-10-11 juanignacio.hita.contractor@bbva.com
*             Add rar_rating_type__c logic for rating type tool in getSectorAccHasAn method.
* |2021-10-21 juanignacio.hita.contractor@bbva.com
*             Add getDynamicFldAha method and integrate dynamic field with triage custom step config.
* |2021-10-21 juanignacio.hita.contractor@bbva.com
*             Refactoring getSectorAccHasAn method fix code smells sonar, create getSectorFinal, getRatingToolFinal methods
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Sector_Data {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Sector_Data sector = new Arc_Gen_Sector_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Sector_Data() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description sectorWrapper get info about a section to show in the tabset
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-12-18
    * @example sectorWrapper secWrapper = new sectorWrapper();
    **/
    public class SectorWrapper {
        /**
        * @Description: Name of the corresponding Tab
        */
        public string tabName {get; set;}
        /**
        * @Description: DevName for the Tab
        */
        public string tabDevName {get; set;}
        /**
        * @Description: Template developername
        */
        public string templateDevName {get; set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of all fields in arce__Sector__c object
    * -----------------------------------------------------------------------------------------------
    * @param aha Account_has_Analysis__c record
    * @param analysistype with value of the type of analysis
    * @return arce__Sector__c - Screen config to be used in the AHA
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce__Sector__c getSectorAccHasAn(arce__Account_has_Analysis__c aha, String analysisType) {
        final List<arce__Sector__c> candidateSectors = [
                SELECT CreatedById,CurrencyIsoCode,LastModifiedById,OwnerId,RecordTypeId,
                        arce__analysis_template_id__c,Name,arce__analysis_section_type__c,arce__sector_analisis_type__c,
                        arce__analysis_section_list__c,arce__rar_rating_tool_id__c,arce__active_type__c,arce__rar_rating_type__c,
                        arce__order_id__c,arce__anlys_wkfl_cnsld_ffss_type__c,arce__group_asset_header_type__c,
                        arce__analysis_customer_relation_type__c
                FROM arce__Sector__c
                WHERE arce__active_type__c = true and arce__sector_analisis_type__c= :analysisType
                ORDER BY arce__order_id__c];

        arce__Sector__c selectedSector = null;

        final String ahaSectorType = aha.arce__analysis_template_id__c;
        String ahaRatingType = aha.arce__g_rtg_tool_typ_id__c;
        String ahaRatingToolId = aha.arce__RAR_rating_tool_id__c;
        final String ahaCnsldFfssType = aha.arce__anlys_wkfl_cnsld_ffss_type__c;
        final String ahaGroupHeaderType = aha.arce__group_asset_header_type__c;
        final String ahaCustRelation = aha.arce__Analysis__r.arce__analysis_customer_relation_type__c;

        final Boolean triageStepEnable = Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig() == null ? false : true;
        if(triageStepEnable || Test.isRunningTest()) {
            final List<String> lstFieldsDyn = Arc_Gen_RatingAsIndepProcess_service.getIRPTriageSaveCnf();
            final Map<String, Object> mapFldAha = getDynamicFldAha(lstFieldsDyn, (String) aha.get('Id'));
            ahaRatingToolId = (String) mapFldAha.get(lstFieldsDyn[0]);
            ahaRatingType = (String) mapFldAha.get(lstFieldsDyn[1]);
        }

        for (arce__Sector__c sector : candidateSectors) {
            final String sectorDevName = sector.arce__analysis_template_id__c;
            final Map<String, String> objParams = new Map<String, String> {
                'sectorRatingTool' => sector.arce__rar_rating_tool_id__c,
                'sectorRatingType' => sector.arce__rar_rating_type__c,
                'ahaRatingType' => ahaRatingType,
                'ahaRatingToolId' => ahaRatingToolId
            };
            final Map<String, String> sectorParams = new Map<String, String> {
                'sectorCnsldFfssType' => sector.arce__anlys_wkfl_cnsld_ffss_type__c,
                'sectorGroupHeaderType' => sector.arce__group_asset_header_type__c,
                'sectorCustRelation' => sector.arce__analysis_customer_relation_type__c,
                'ahaCnsldFfssType' => ahaCnsldFfssType,
                'ahaGroupHeaderType' => ahaGroupHeaderType,
                'ahaCustRelation' => ahaCustRelation
            };
            final Boolean sectorNameMatches = String.isBlank(sectorDevName) || sectorDevName == ahaSectorType;
            if (sectorNameMatches && getRatingToolFinal(objParams, triageStepEnable) && getSectorFinal(sectorParams)) {
                selectedSector = sector;
                break;
            }
        }

        return selectedSector;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Return boolean decision using sector logic sector fields
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    22/02/2022
    * @param   Map<String, String> objParams
    * @return  Boolean
    * @example Boolean ret = getSectorFinal(sectorParams);
    **/
    private static Boolean getSectorFinal(Map<String, String> sectorParams) {
        final Boolean cnsldFfssTypeMatches = String.isBlank(sectorParams.get('sectorCnsldFfssType')) || sectorParams.get('sectorCnsldFfssType') == sectorParams.get('ahaCnsldFfssType');
        final Boolean sectorHeaderTypeMatches = String.isBlank(sectorParams.get('sectorGroupHeaderType')) || sectorParams.get('sectorGroupHeaderType') == sectorParams.get('ahaGroupHeaderType');
        final Boolean custRelationMatches = String.isBlank(sectorParams.get('sectorCustRelation')) || sectorParams.get('sectorCustRelation') == sectorParams.get('ahaCustRelation');
        return cnsldFfssTypeMatches && sectorHeaderTypeMatches && custRelationMatches;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Return boolean using rating tool final sector
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    22/02/2022
    * @param   Map<String, String> objParams
    * @param   Boolean triageStepEnable
    * @return  Boolean
    * @example Boolean ret = getRatingToolFinal(objParams, triageStepEnable);
    **/
    private static Boolean getRatingToolFinal(Map<String, String> objParams, Boolean triageStepEnable) {
        final String sectorRatingTool = objParams.get('sectorRatingTool');
        final String sectorRatingType = objParams.get('sectorRatingType');
        final Boolean ratingToolEmpty = String.isBlank(sectorRatingTool) && String.isBlank(sectorRatingType);
        final Boolean ratingToolMatches = !String.isBlank(sectorRatingTool) && sectorRatingTool == objParams.get('ahaRatingToolId');
        final Boolean ratingTypeMatches = !String.isBlank(sectorRatingType) && triageStepEnable && sectorRatingType == objParams.get('ahaRatingType');
        return ratingToolEmpty || ratingToolMatches || ratingTypeMatches;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of pick list values from arce__Sector__c object
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return List<Schema.PicklistEntry> - List of PicklistValues
    * @example getPicklistEntryFroAnalysisSectionType()
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<SectorWrapper> getSectionsFromSector(arce__Sector__c sector) {
        final List<String> listTabs = new List<String>();
        final List<String> listTemplates = new List<String>();
        final List<SectorWrapper> listWrappers = new List<SectorWrapper>();
        Integer idx = 0;
        listTabs.addAll(sector.arce__analysis_section_type__c.split(';'));
        listTemplates.addAll(sector.arce__analysis_section_list__c.split(';'));
        final Map<string,string> mapValueLabel = arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels('arce__Sector__c','arce__analysis_section_type__c');
        for(String tab : listTabs) {
            final SectorWrapper wrap = new SectorWrapper();
            wrap.tabName = mapValueLabel.get(tab);
            wrap.tabDevName = tab;
            wrap.templateDevName = listTemplates[idx];
            listWrappers.add(wrap);
            idx += 1;
        }
        return listWrappers;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method get a map with dev name of the template and name section
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 05/05/2020
    * @param arce__Account_has_Analysis__c accHas : name of sector
    * @param String analysisType : name of the template
    * @return Map<String, String> : return a map with the sector name and the template name
    * @example Map<String, String> map = getMapTabSet(sector, templateName);
    **/
    public static Map<String, String> getMapTabSet(arce__Account_has_Analysis__c accHas, String analysisType) {
        final Map<String, String> mapTabset = new Map<String, String>();
        final arce__Sector__c sector = getSectorAccHasAn(accHas, analysisType);
        final List<SectorWrapper> lstSectorWrp = getSectionsFromSector(sector);
        if (!lstSectorWrp.isEmpty()) {
            for (SectorWrapper wrp : lstSectorWrp) {
                mapTabset.put(wrp.templateDevName, wrp.tabName);
            }
        }
        return mapTabset;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that retrieves template for a given tab from a sector record
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 05/05/2020
    * @param arce__sector__c sector
    * @param String tab developername
    * @return String: template name asociated with the tab
    * @example String template = getTemplateFromSector(sector, templateName)
    **/
    public static String getTemplateFromSector(arce__sector__c sector, String templateName) {
        String finalTemplate = '';
        final List<String> listTabs = new List<String>();
        final List<String> listTemplates = new List<String>();
        Integer idx = 0;
        listTabs.addAll(sector.arce__analysis_section_type__c.split(';'));
        listTemplates.addAll(sector.arce__analysis_section_list__c.split(';'));
        for(String tab : listTabs) {
            if(tab == templateName) {
                finalTemplate = listTemplates[idx];
                break;
            }
            idx += 1;
        }
        return finalTemplate;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets data map of the specific fields of "account_has_analysis" object
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    22/10/2021
    * @param   List<String> lstFields : fields list to query
    * @param   String ahaId : account has analysis id
    * @return  Map<String, Object> map with key and value of each field
    * @example Map<String, Object> mapRet = getDynamicFldAha(lstFields, ahaId);
    **/
    public static Map<String, Object> getDynamicFldAha(List<String> lstFields, String ahaId) {
        Map<String, Object> mapRet = new Map<String, Object>();
        if (!lstFields.isEmpty()) {
            final List<arce__Account_has_Analysis__c> ahaDynamic = arce.Arc_Gen_AccHasAnalysis_Data.getRelatedData(lstFields, ahaId);
            mapRet = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(ahaDynamic[0]));
        }
        return mapRet;
    }

}