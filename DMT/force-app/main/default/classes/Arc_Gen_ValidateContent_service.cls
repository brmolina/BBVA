/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Content
* @Author   Juan Ignacio Hita
* @Date     Created: 2019-10-27
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2019-10-27 juanignacio.hita.contractor@bbva.com@bbva.com
*             Class creation.
* |2019-11-20 javier.soto.carrascosa@bbva.com@bbva.com
*             Fix sum percentage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-03 joseluis.garcia4.contractor@bbva.com
*             Fix year input (discard blank spaces at beginning/end of input).
* |2020-11-12 joseluis.garcia4.contractor@bbva.com@bbva.com
*             Add validation to check that no two different geographies/activities with the
*             same name are added.
* |2020-11-16 joseluis.garcia4.contractor@bbva.com@bbva.com
*             Add validation to check that no two rows are added for the same year-geography/activity.
* |2021-01-28 joseluis.garcia4.contractor@bbva.com@bbva.com
*             Fixes NullPointerException when the user leaves the year field blank.
* |2021-06-23 juanignacio.hita.contractor@bbva.com@bbva.com
*             Add format validation for year column.
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateContent_service implements rrtm.RelatedManager_Interface {
    /**
        * @Description: integer with maxYears
    */
    static Integer maxYears = 2;
    /**
        * @Description: integer with maximum percentage
    */
    static Integer maxPercent = 100;
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates the info coming from some tables
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param    List<Object> lstRecords for wrapper detail
    * @return   JSON String with validation result and messages updated
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';
        Map<String, Decimal> mapYearPercent = new Map<String, Decimal>();
        final Map<String, Set<String>> yearsByRecord = new Map<String, Set<String>>();
        set<String> arcAcc = new Set<String>();
        final Set<String> dataCollectionIds = new Set<String>();

        if(!lstRecords.isEmpty()) {
            Integer ite = 0;
            for (Object obj : lstRecords) {
                String strJson = JSON.serialize(obj);
                Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                ite++;
                arcAcc.add(String.valueOf(mapObj.get('arce__account_has_analysis_id__c')));
                final String geoActId = String.valueOf(mapObj.get('Seeker'));
                dataCollectionIds.add(geoActId);

                String percent = String.valueOf(mapObj.get('arce__table_content_percentage__c'));
                String year = getTrimmedYear(mapObj.get('arce__table_content_year__c'));

                validateRecordAndYear(wrapper, yearsByRecord, geoActId, year);
                if (arce.Arc_Gen_ValidateInfo_utils.isFilled(percent)) {
                    mapYearPercent = arce.Arc_Gen_ValidateInfo_utils.sumMapMethod(mapYearPercent,year,percent);
                } else {
                    wrapper.msgInfo += string.format(Label.Arc_Gen_CompleteField_Per, new List<String>{String.valueOf(ite)});
                    wrapper.validation = false;
                }
                if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(year)) {
                    wrapper.msgInfo += string.format(Label.Arc_Gen_CompleteField_Year, new List<String>{String.valueOf(ite)});
                    wrapper.validation = false;
                }
            }
        }

        // Check names of geographies/activities are not repeated in data collection records.
        final List<arce__Data_Collections__c> geoActs = Arc_Gen_Balance_Tables_data.getDataCollectionsById(dataCollectionIds);
        final String repeatedName = checkNamesRepeated(geoActs);

        // Check edit permission on Account_has_Analysis__c record.
        validatePermissionToEdit(arcAcc, wrapper);
        final Boolean hasRepeatedName = repeatedName != null;
        if (hasRepeatedName) {
            wrapper.msgInfo += String.format(Label.Arc_Gen_InsertGeoAct_ErrorMultipleRecord, new List<String> { repeatedName });
            wrapper.validation = false;
        } else if (mapYearPercent.size() <= maxYears ) {
            for(String key : mapYearPercent.keySet()) {
                if(mapYearPercent.get(key) != maxPercent) {
                    wrapper.validation = false;
                    wrapper.msgInfo += string.format(Label.Arc_Gen_InsertGeoAct_ErrorSumPercent, new List<String>{key});
                }
            }
        } else {
            wrapper.msgInfo += Label.Arc_Gen_InsertGeoAct_Error2years;
            wrapper.validation = false;
        }
        return JSON.serialize(wrapper);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Obtains the year introduced by the user, checking for nulls.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2021-01-28
    * @param    input raw input introduced by the user
    * @return   trimmed year
    */
    private static String getTrimmedYear(Object input) {
        return input == null ? null : ((String)input).trim();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Check that no geography is used twice for the same year.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-11-16
    * @param    wrapper - Wrapper to save validation errors to.
    * @param    yearsByRecord - Used years per record.
    * @param    recordId - Record to check
    * @param    year - Year to check
    * @return   void
    * --------------------------------------------------------------------------------------
    */
    private static void validateRecordAndYear(Wrapper wrapper, Map<String, Set<String>> yearsByRecord, String recordId, String year) {
        if (!yearsByRecord.containsKey(recordId)) {
            yearsByRecord.put(recordId, new Set<String>());
        }

        final Set<String> years = yearsByRecord.get(recordId);
        if (years.contains(year)) {
            wrapper.msgInfo = String.format(System.Label.Arc_Gen_InsertGeoAct_MoreOneRecord, new List<String> { year });
            wrapper.validation = false;
        } else {
            years.add(year);
            if (year.length() > 4 || !year.isNumeric()) {
                wrapper.msgInfo = String.format(System.Label.Arc_Gen_InsertGeoAct_FormatYear, new List<String> { year });
                wrapper.validation = false;
            }
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Checks edit permission on set of Account_has_Analysis__c records
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-03-11
    * @param arcAcc - List of Account_has_Analysis__c record IDs
    * @param wrapper - Result wrapper to populate in case of error.
    * --------------------------------------------------------------------------------------
    **/
    private static void validatePermissionToEdit(Set<String> arcAcc, Wrapper wrapper) {
        // Check edit permission on Account_has_Analysis__c record.
        for (String accHasId : arcAcc) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
                return;
            }
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Checks that no different records are used for the same geography.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param geoActs - Records for the selected geographies/activities
    * --------------------------------------------------------------------------------------
    **/
    private static String checkNamesRepeated(List<arce__Data_Collections__c> geoActs) {
        final Set<String> names = new Set<String>();
        Boolean namesRepeated = false;
        String repeatedName = null; // NOSONAR
        Integer idx = 0;
        while (!namesRepeated && idx < geoActs.size()) {
            final String name = geoActs[idx].Name;
            if (names.contains(name)) {
                namesRepeated = true;
                repeatedName = name;
            }
            names.add(name);
            idx++;
        }

        return repeatedName;
    }
}