/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_controller
* @Author   saimassimilianno.jordana.contractor@bbva.com
* @Date     Created: 07-03-2022
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller of renewal process for corporate.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |07-03-2022 saimassimilianno.jordana.contractor@bbva.com
*             Class creation.
* |07-03-2022 amunguia.contractor@bbva.com
*             dynamic update and insertion of all the changes involved
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_CorpRenewAnalysis extends Arc_Gen_Renew_Abstract { 
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		07/03/2022
    * @author	saimassimilianno.jordana.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_CorpRenewAnalysis() {
        super();
    }

    /** ----------------------------------------------------------------------------------------------------
    * @Description Leveraged Type Literal.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String PRE_LEVERAGED = 'PRE_LEVERAGED';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Arce config for corp renwal activation.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String RENEW_CONFIG = 'ArceRenewalCorp';

    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__Account_has_Analysis__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String AHAOBJ = 'arce__Account_has_Analysis__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__Overlay__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String OVEROBJ = 'arce__Overlay__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__Activity_Split__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String ACCTYOBJ = 'arce__Activity_Split__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__gf_subactivity_id__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String SUBACT_LIT = 'arce__gf_subactivity_id__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__template_type__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String TEMPTYPE_LIT = 'arce__template_type__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__gf_subindustry_weight_per__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String SUBINDWEI_LIT = 'arce__gf_subindustry_weight_per__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__country_2012__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String COUN2012_LIT = 'arce__country_2012__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__sector_id__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String SECTORID_LIT = 'arce__sector_id__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__MulltitemplateCallOK__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String MULTITEMPCALL_LIT = 'arce__MulltitemplateCallOK__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description RENEW_ON.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final Boolean RENEW_ON = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(RENEW_CONFIG)[0].arce__Value1__c);
    /** ----------------------------------------------------------------------------------------------------
    * @Description toInsert.
    * ---------------------------------------------------------------------------------------------------- **/
    private static List<SObject> toInsert = new List<SObject>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description toInsertDiff.
    * ---------------------------------------------------------------------------------------------------- **/
    private static List<SObject> toInsertDiff = new List<SObject>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description toUpdate.
    * ---------------------------------------------------------------------------------------------------- **/
    private static List<SObject> toUpdate = new List<SObject>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, List<String>> fieldsMap = new Map<String, List<String>>{AHAOBJ => new List<String>{'arce__IRP_Workflow__c'}};

    /** ----------------------------------------------------------------------------------------------------
    * @Description YEAR.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final Integer YEAR = 12;
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, String> ratingToolMap = new Map<String, String>{'2012P1IRP' => '2012IRP'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, String> correctActSplit = new Map<String, String>{'arce__Activity_Splits_2012__r' => 'arce__Activity_Splits__r'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, String> relationSObject = new Map<String, String>{'arce__Activity_Splits_2012__r' => 'arce__Activity_Split_2012__c', 'arce__Activity_Splits__r' => 'arce__Activity_Split__c'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, String> sObjectRelation = new Map<String, String>{'arce__Activity_Split_2012__c' => 'arce__Activity_Splits_2012__r', 'arce__Activity_Split__c' => 'arce__Activity_Splits__r'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description noDuplicates.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Set<String> noDuplicates = new Set<String>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description weightMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, Decimal> weightMap = new Map<String, Decimal>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description weightMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, SObject> maxWeightMap = new Map<String, SObject>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description acctyMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<Id, String> acctyMap = new Map<Id, String>();
    /** ----------------------------------------------------------------------------------------------------
    * @Description acctyMapDiff.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<Id, String> acctyMapDiff = new Map<Id, String>();

    /**
    *-------------------------------------------------------------------------------
    * @description method to get analysis which were created with the same structure.
    *--------------------------------------------------------------------------------
    * @author saimassimilianno.jordana.contractor@bbva.com
    * @date xx-03-2022
    * @param type rating or prerating.
    * @param clientId recordId for the account.
    * @param ratingTool Model+Flow selected.
    * @return JSON as String.
    * @example public static String fetchAnalysis(String varRecord) {
    **/
    @AuraEnabled
    public static String fetchAnalysis(String type, String clientId, String ratingTool) {
        String jsonToRtrn;
        List<arce__Account_has_Analysis__c> ahas = arce.Arc_Gen_AccHasAnalysis_Data.getAhaToRenew(type, clientId, ratingTool);
        if(ahas.isEmpty() && ratingTool =='2012P1IRP') {
            ahas = arce.Arc_Gen_AccHasAnalysis_Data.getAhaToRenew(type, clientId, ratingToolMap.get(ratingTool));
        }
        final Boolean isRenew = Test.isRunningTest() || RENEW_ON;
        final JSONGenerator data = JSON.createGenerator(false);

        if(ahas.isEmpty() || !isRenew) {
            data.writeStartObject();
            data.writeBooleanField('renew', false);
            data.writeEndObject();
            jsonToRtrn = data.getAsString();
        } else {
            data.writeStartObject();
            data.writeBooleanField('renew', true);
            data.writeStringField('Name', ahas[0].arce__Analysis__r.Name);
            data.writeStringField('Type', ahas[0].arce__Analysis__r.arce__rating_prerating_type__c);
            data.writeStringField('id', string.valueOf(ahas[0].arce__Analysis__c));
            data.writeStringField('ahaId', string.valueOf(ahas[0].Id));
            data.writeDateField('finalDate', getValidtdDate(ahas[0]));
            data.writeEndObject();
            jsonToRtrn = data.getAsString();
        }

        return jsonToRtrn;
    }

    /**
    * @description get valid end date
    * @author jordana@bbva.com | 19-07-2022
    * @param arce.arce__Account_has_Analysis__c ahas
    * @return Validation Date
    **/
    public static Date getValidtdDate(arce__Account_has_Analysis__c ahas) {
        Date toRtrn;
        if (ahas.arce__Analysis__r.arce__end_date__c == null) {
            final String analysisId = ahas.arce__Analysis__r.Id;
            final arce__Traceability_Event__c trcEvnt = [select arce__audit_date__c, arce__current_event__c  from arce__Traceability_Event__c where arce__account_has_analysis_id__r.arce__Analysis__c = :analysisId AND arce__current_event__c = true LIMIT 1];
            toRtrn = trcEvnt.arce__audit_date__c;
        } else {
            toRtrn = ahas.arce__Analysis__r.arce__end_date__c;
        }

        return toRtrn;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method to get all data needed to clone.
    *--------------------------------------------------------------------------------
    * @author saimassimilianno.jordana.contractor@bbva.com
    * @date xx-03-2022
    * @param ratingTool recordId of the account_has_analysis.
    * @return NONE
    * @example public static getAllToClone(String ratingTool) {
    **/
    @AuraEnabled
    public static void getAllToClone(String currAha, String data, String ratingTool) {
        final Map<String,Object> jsonCorp = (Map<String,Object>) JSON.deserializeUntyped(data);
        final String oldAha = (String) jsonCorp.get('ahaId');
        final Date finalDate = Date.valueOf((String) jsonCorp.get('finalDate'));
        final Integer monthsBetween = finalDate.monthsBetween(Date.today());
        final Set<String> ahasId = new Set<String>{currAha, oldAha}; //NOSONAR
        //get sections SOQL to Sectors.
        final List<String> bigSections = [SELECT arce__rar_rating_tool_id__c, arce__analysis_section_list__c FROM arce__Sector__c WHERE arce__rar_rating_tool_id__c = :ratingTool LIMIT 1].arce__analysis_section_list__c.split(';');
        if (ratingTool.containsIgnoreCase('2012P1')) {
            bigSections.add('SP2-IRP-01-100-FR-2012P1');
        }
        //get tabs related to previous sector.
        final Map<String, String > tabsToGet = new Map<String, String>();
        for(dyfr__Tab__c currtab : [SELECT id, dyfr__Tab_Code__c, renewal_attributes__c FROM dyfr__Tab__c WHERE dyfr__Template__r.name IN :bigSections]) {
            if(String.isNotBlank(currtab.renewal_attributes__c)) {
                tabsToGet.put(currtab.dyfr__Tab_Code__c, currtab.renewal_attributes__c);
            }
        }
        //get Map with TabCode -> List of sections obtained from JSON attr on tab.
        final Map<String, List<String>> sectionConfigs = getTabConfig(tabsToGet.values(), monthsBetween);

        //get all fields configs related to the previuos tabs.
        final List<dyfr__Field_Config__c> allFieldConfgs = getFieldConfigs(tabsToGet.keySet(), sectionConfigs);

        for(dyfr__Field_Config__c currentFC : allFieldConfgs) {
            final String relationObject = currentFC.dyfr__Relationship_Object_Name__c;
            final String finalObject = String.isEmpty(relationObject) ? AHAOBJ : relationObject ;
            if(fieldsMap.containsKey(finalObject)) {
                fieldsMap.get(finalObject).add(currentFC.dyfr__Map_field__c);
            } else {
                fieldsMap.put(finalObject, new List<String>{currentFC.dyfr__Map_field__c});
            }
        }
        if(RENEW_ON) {
            queryActivities(monthsBetween, fieldsMap);
        }
        String query = 'SELECT arce__RAR_rating_tool_id__c,';
        final List<String> queryAll = new List<String>();
        for(String field : fieldsMap.keySet()) {
            final Set<String> removeFields = new Set<String>();
            removeFields.addAll(fieldsMap.get(field));
            fieldsMap.put(field, new List<String>(removeFields));
            if (field == AHAOBJ) {
                queryAll.add(String.join(fieldsMap.get(field),','));
            } else {
                queryAll.add('(SELECT '+ String.join(fieldsMap.get(field),',') + ' FROM ' + field + ')');
            }
        }
        query += String.join(queryAll, ',') + ', arce__AHA_Extension__c' + ' FROM arce__Account_has_Analysis__c WHERE Id IN :ahasId';
        final Map<Id,SObject> lstMod = new Map<Id,SObject>(Database.query(String.escapeSingleQuotes(query)));
        final arce__Analysis__c arceObj = arce.Arc_Gen_ArceAnalysis_Data.gerArce(currAha);
        arceObj.arce__Is_RAIP_Renewal__c = true;
        toUpdate.add(arceObj);
        cloneSObjects(lstMod.get(currAha), lstMod.get(oldAha),fieldsMap,ratingTool);
        cloneAhaExtension((arce__Account_has_Analysis__c) lstMod.get(currAha), (arce__Account_has_Analysis__c) lstMod.get(oldAha));
        if (ratingTool.contains('2012P1')) {
            cloneLeveraged((arce__Account_has_Analysis__c) lstMod.get(currAha), (arce__Account_has_Analysis__c) lstMod.get(oldAha));
        }
    }
    /**
    * @description cloneExtension Camn values
    * @author joseluis.miralles.contractor@bbva.com | 06-27-2024
    * @param arce__Account_has_Analysis__c currAha
    * @param arce__Account_has_Analysis__c oldAha
    **/
    private static void cloneAhaExtension (arce__Account_has_Analysis__c currAha, arce__Account_has_Analysis__c oldAha) {
        final arce__AHA_Extension__c ahaExtCurrent = (arce__AHA_Extension__c) getSObjectInfo('arce__AHA_Extension__c', currAha.arce__AHA_Extension__c, null);
        final arce__AHA_Extension__c ahaExtOld = (arce__AHA_Extension__c) getSObjectInfo('arce__AHA_Extension__c', oldAha.arce__AHA_Extension__c, null);
        if (ahaExtOld.arce__Camn_API_Value__c != null) {
            ahaExtCurrent.arce__Camn_Label_Value__c = ahaExtOld.arce__Camn_Label_Value__c;
            ahaExtCurrent.arce__Camn_API_Value__c = ahaExtOld.arce__Camn_API_Value__c;
            Database.update(ahaExtCurrent, AccessLevel.SYSTEM_MODE);
        }
    }
    /**
    * @description getObject Info
    * @author joseluis.miralles.contractor@bbva.com | 06-27-2024
    * @param (String objectName
    * @param String recordId
    * @param List<String> moreFields
    **/
    public static SObject getSObjectInfo(String objectName, String recordId, List<String> moreFields) {
        String queryString = 'SELECT ' + arce.Arc_Gen_GenericUtilities.getAllFields(objectName).remove(',lastvieweddate').remove(',lastreferenceddate');
        queryString += moreFields == null ? '' : ',' + String.join(moreFields, ',');
        queryString += ' FROM ' + objectName + ' WHERE Id =: recordId';
        return Database.query(String.escapeSingleQuotes(queryString));
    }
    /**
    * @description cloneLeveraged values (financial sponsor)
    * @author joseluis.miralles.tech@bbva.com | 08-23-2024
    * @param arce__Account_has_Analysis__c currAha
    * @param arce__Account_has_Analysis__c oldAha
    **/
    private static void cloneLeveraged (arce__Account_has_Analysis__c currAha, arce__Account_has_Analysis__c oldAha) {
        final List<arce__Leveraged__c> leveragedtCurrent = getLeveragedData(currAha.Id);
        final List<arce__Leveraged__c> leveragedtOld = getLeveragedData(oldAha.Id);
        if (!leveragedtOld.isEmpty() && !leveragedtCurrent.isEmpty()) {
            leveragedtCurrent[0].arce__AL_Financial_Sponsor__c =  leveragedtOld[0].arce__AL_Financial_Sponsor__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Group_Name__c = leveragedtOld[0].arce__MG_Leveraged_Group_Name__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Id__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Id__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Name__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Name__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Group_Name2__c = leveragedtOld[0].arce__MG_Leveraged_Group_Name__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Id2__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Id__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Name2__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Name__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Group_Name3__c = leveragedtOld[0].arce__MG_Leveraged_Group_Name__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Id3__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Id__c;
            leveragedtCurrent[0].arce__MG_Leveraged_Parent_Name3__c = leveragedtOld[0].arce__MG_Leveraged_Parent_Name__c;
            leveragedtCurrent[0].arce__GN_Leveraged_EBITDA__c = leveragedtOld[0].arce__GN_Leveraged_EBITDA__c;
            leveragedtCurrent[0].arce__GN_Leveraged_Gross_Debt__c = leveragedtOld[0].arce__GN_Leveraged_Gross_Debt__c;
            leveragedtCurrent[0].arce__Ratio_Calculated_Value__c = leveragedtOld[0].arce__Ratio_Calculated_Value__c;
            Database.update(leveragedtCurrent, AccessLevel.SYSTEM_MODE);
        }
    }
    /**
    * @description cloneSObjects
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param SObject currAha
    * @param SObject oldAha
    * @param Map<String List<String>> fieldsMap
    **/
    private static void cloneSObjects (SObject currAha, SObject oldAha, Map<String, List<String>> fieldsMap, String currRatingTool) {
        for(String relationField : fieldsMap.keySet()) {
            if(relationField == AHAOBJ) {
                toUpdate.add(mergeRecords(currAha, oldAha, fieldsMap.get(relationField)));
            } else {
                final List<SObject> oldList = oldAha.getSObjects(relationField);
                // check if there are duplicates in activity splits and remove them
                if (relationField.contains('Activity_Splits') && oldList != null) {
                    final Set<String> keysList = new Set<String>();
                    for (Integer i = 0; i < oldList.size(); i++) {
                        if (!keysList.add(acttiKeyBuilder(oldList[i]))) {
                            System.debug(LoggingLevel.INFO, 'Duplicate activity split found: ' + oldList[i]);
                            oldList.remove(i);
                        }
                    }
                }
                final Boolean isDiff = oldAha.get('arce__RAR_rating_tool_id__c') != currRatingTool && relationField.contains('Activity_Splits') && currRatingTool == '2012P1IRP';
                relationField = isDiff ? correctActSplit.get(relationField) : relationField;
                if(oldList != null) {
                    fillSubindMaps(isDiff, oldList);
                    for(SObject objRelOld :oldList) {
                        upsertRecords(relationField, objRelOld, currAha, isDiff);
                    }
                }
            }
        }
        processRecords();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description build key to verify duplicity of activity splits
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param inputSObject SObject
    * @return String
    * @example acttiKeyBuilder(inputSObject)
    **/
    private static String acttiKeyBuilder(SObject inputSObject) {
        return String.isNotBlank((String) inputSObject.get('arce__Template_type_2012__c'))
        ? (String) inputSObject.get(SECTORID_LIT)
        + (String) inputSObject.get('arce__Subsector_id_2012__c')
        + (String) inputSObject.get('arce__gf_company_economic_actvy_id_2012__c')
        + (String) inputSObject.get('arce__gf_subactivity_id_2012__c')
        + (String) inputSObject.get('arce__Template_type_2012__c')
        : (String) inputSObject.get(SECTORID_LIT)
        + (String) inputSObject.get('arce__Subsector_id__c')
        + (String) inputSObject.get('arce__gf_company_economic_actvy_id__c')
        + (String) inputSObject.get(SUBACT_LIT)
        + (String) inputSObject.get(TEMPTYPE_LIT);
    }

    /**
    * @description getFieldConfigs
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param Set<String> tabs
    * @param Map<String List<String>> sections
    * @return List<dyfr__Field_Config__c>
    **/
    private static void upsertRecords(String relationField, SObject objRelOld, SObject currAha, Boolean isDifferent) {//NOSONAR
        final List<SObject> currList = currAha.getSObjects(relationField);
        final Schema.sObjectType type = isDifferent ? Schema.getGlobalDescribe().get(relationSObject.get(relationField)) : objRelOld.getSObjectType();
        final SObject currObj = currList == null ? type.newSObject(null, true) : currList[0];//NOSONAR
        if(objRelOld.getSObjectType().getDescribe().getName() == ACCTYOBJ) {
            acctyMap.put((Id)objRelOld.get('Id'), getCorrectValMap(objRelOld));
        }
        if(currList == null && type.getDescribe().getName() != OVEROBJ) {
            List<String> lstFields = fieldsMap.get(relationField);
            if(objRelOld.getSObjectType().getDescribe().getName() == currObj.getSObjectType().getDescribe().getName()) {
                objRelOld.put(AHAOBJ, currAha.Id);
                toInsert.add(mergeRecords(currObj, objRelOld, lstFields));
            } else {
                lstFields = getCorrectListFields(currObj.getSObjectType().getDescribe().getName(), objRelOld.getSObjectType().getDescribe().getName());
                final String key = (String)objRelOld.get(SECTORID_LIT) + (String)objRelOld.get(SUBACT_LIT) + (String)objRelOld.get(TEMPTYPE_LIT);
                acctyMapDiff.put((Id)objRelOld.get('Id'), key);
                if(noDuplicates.add(key) == true) {
                    final SObject sObjToInsert = mergeRecords(currObj, maxWeightMap.get(key), lstFields);
                    sObjToInsert.put(AHAOBJ, currAha.Id);
                    sObjToInsert.put(SUBINDWEI_LIT, weightMap.get(key));
                    sObjToInsert.put(MULTITEMPCALL_LIT, 'YES');
                    toInsertDiff.add(sObjToInsert);
                }
            }
        } else {
            SObject sobj = mergeRecords(currObj, objRelOld, fieldsMap.get(relationField));
            if(!String.isBlank((String)sobj.get('Id'))){
                toUpdate.add(sobj);
            }
        }
    }

    /**
    * @description createEEFF
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param String currAha
    * @param String data
    * @param String ratingTool
    **/
    @AuraEnabled
    public static void createEEFF(String currAha, String data, String ratingTool) {
        final Map<String,Object> jsonCorp = (Map<String,Object>) JSON.deserializeUntyped(data);
        final Date finalDate = Date.valueOf((String) jsonCorp.get('finalDate'));
        final Integer monthsBetween = finalDate.monthsBetween(Date.today());
        final String oldAha = (String) jsonCorp.get('ahaId');
        final Set<Id> ahaIds = new Set<Id>{currAha,oldAha};
        final Map<Id,arce__Account_has_Analysis__c> lstMod = new Map<Id,arce__Account_has_Analysis__c>([SELECT Id, arce__ffss_for_rating_id__c FROM arce__Account_has_Analysis__c WHERE Id IN :ahaIds]);
        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
        final List<arce__Financial_Statements__c> ffssList = dataAccess.getFinancialStatements(new List<String>{lstMod.get(oldAha).arce__ffss_for_rating_id__c});
        if(!ffssList.isEmpty() && monthsBetween < YEAR) {
            for(arce__Financial_Statements__c ffss : ffssList) {
                makeTheCallout(lstMod.get(currAha).Id, new List<arce__Financial_Statements__c>{ffss}, new List<String>{ffss.arce__financial_statement_id__c});
            }
        }
    }

    /**
    * @description createGeographies
    * @author amunguia.contractor@bbva.com | 04-25-2022
    * @param Map<Id String> acctyMap
    * @param List<SObject> toInsert
    **/
    private static void createGeographies(Map<Id, String> acctyMap) {

        final Set<Id> acctyId = acctyMap.keySet();//NOSONAR
        final List<SObject> geoInsert = new List<SObject>();
        final List<String> geoFields = new List<String>{'Id', ACCTYOBJ, 'arce__Country__c', COUN2012_LIT, 'arce__gf_geography_split_per_type__c', 'arce__gf_geography_weight_per__c'};
        final String queryQ = 'SELECT ' + String.join(geoFields, ',')
            + ' FROM arce__Geographic_Split__c WHERE arce__Activity_Split__c IN :acctyId';
            final Map<String, List<SObject>> geographyMap = new Map<String,List<SObject>>();
        for(SObject aux : Database.query(String.escapeSingleQuotes(queryQ))) {
            final String key = acctyMap.get((Id) aux.get(ACCTYOBJ));
            if(geographyMap.containsKey(key)) {
                geographyMap.get(key).add(aux);
            } else {
                geographyMap.put(key, new List<SObject>{aux});
            }
        }
        for(SObject aux :toInsert) {
            if(aux.getSObjectType().getDescribe().getName() == ACCTYOBJ) {
                final String key = getCorrectValMap(aux);
                final List<SObject> geoList = geographyMap.get(key);
                for(SObject geoSplit : geoList) {
                    geoSplit.put(ACCTYOBJ, aux.Id);
                    geoInsert.add(mergeRecords(geoSplit.getSObjectType().newSObject(null, true), geoSplit, geoFields));
                }
            }
        }
        if(!geoInsert.isEmpty()) {
            insert geoInsert;
        }
    }

    /**
    * @description abstractMethod
    * @author amunguia.contractor@bbva.com | 04-25-2022
    * @return Integer
    **/
    public override Integer abstractMethod() {
        return 12;
    }

    /**
    * @description createGeographies
    * @author alberto.martinez.carrero.contractor@bbva.com | 07-12-2022
    * @param Map<String, List<String>> fldsMap
    * @param String newObjName
    * @param String currentObjName
    * @return List<String> lstToRet
    **/
    @TestVisible
    private static List<String> getCorrectListFields(String newObjName, String currentObjName) {
        final List<String> lstCurrent = fieldsMap.get(sObjectRelation.get(currentObjName));
        final List<String> lstNew = fieldsMap.get(sObjectRelation.get(newObjName));
        final List<String> lstToRet= new List<String>();
        for(String field: lstCurrent) {
            if(lstNew.contains(field)) {
                lstToRet.add(field);
            }
        }
        return lstToRet;
    }
    /**
    * @description getCorrectValMap
    * @author alberto.martinez.carrero.contractor@bbva.com | 13-12-2022
    * @param SObject objRelOld  
    * @return String strToRet
    **/
    @TestVisible
    private static String getCorrectValMap(SObject objRelOld) {
        String strToRet = (String)objRelOld.get(SECTORID_LIT);
        if(String.isBlank((String)objRelOld.get(SUBACT_LIT)) && String.isBlank((String)objRelOld.get(TEMPTYPE_LIT))) {
            strToRet += (String)objRelOld.get('arce__gf_subactivity_id_2012__c') + (String)objRelOld.get('arce__Template_type_2012__c');
        } else {
            strToRet += (String)objRelOld.get(SUBACT_LIT) + (String)objRelOld.get(TEMPTYPE_LIT);
        }
        return strToRet;
    }
    /**
    * @description createGeographies
    * @author alberto.martinez.carrero.contractor@bbva.com | 13-12-2022
    * @param Map<Id String> acctyMapDiff
    **/
    @TestVisible
    private static void createGeographiesDiff(Map<Id, String> acctyMapDiff) {
        Decimal percSub = 0;
        final Set<Id> acctyId = acctyMapDiff.keySet();//NOSONAR
        final List<String> geoFields = new List<String>{'Id', SECTORID_LIT,'arce__Subsector_id__c', 'arce__gf_company_economic_actvy_id__c', SUBACT_LIT, TEMPTYPE_LIT, COUN2012_LIT, SUBINDWEI_LIT}; 
        final String queryQ = 'SELECT ' + String.join(geoFields, ',')
            + ' FROM arce__Activity_Split_2012__c WHERE Id IN :acctyId';
        final Map<String, List<SObject>> actSplit2012Map = new Map<String,List<SObject>>();
        final Map<String, Decimal> weightMap = new Map<String, Decimal>();
        for(SObject aux : Database.query(String.escapeSingleQuotes(queryQ))) {
            final String key = acctyMapDiff.get((Id) aux.get('Id'));
            if(actSplit2012Map.containsKey(key)) {
                percSub = weightMap.get(key) + (Decimal) aux.get(SUBINDWEI_LIT);
                weightMap.put(key,percSub);
                actSplit2012Map.get(key).add(aux);
            } else {
                percSub = (Decimal) aux.get(SUBINDWEI_LIT);
                weightMap.put(key,percSub);
                actSplit2012Map.put(key, new List<SObject>{aux});
            }
        }
        final List<SObject> lstGeo = new List<SObject>();
        for(SObject aux :toInsertDiff) {
            if(aux.getSObjectType().getDescribe().getName() == ACCTYOBJ) {
                final String key = getCorrectValMap(aux);
                final List<SObject> lstAux = actSplit2012Map.get(key);
                for(SObject obj : lstAux) {
                    final String key2 = acctyMapDiff.get((Id) obj.get('Id'));
                    final Schema.sObjectType type = Schema.getGlobalDescribe().get('arce__Geographic_Split__c');
                    final SObject geoSplit = type.newSObject(null, true);
                    geoSplit.put('arce__Activity_Split__c', (Id) aux.get('Id'));
                    geoSplit.put(COUN2012_LIT, (String) obj.get(COUN2012_LIT));
                    geoSplit.put('arce__gf_geography_weight_per__c', calculateGeoWeight((Decimal) obj.get(SUBINDWEI_LIT), weightMap.get(key2)));
                    lstGeo.add(geoSplit);
                }
            }
        }
        if(!lstGeo.isEmpty()) {
            insert lstGeo;
        }
    }
    /**
    * @description calculateGeoWeight
    * @author alberto.martinez.carrero.contractor@bbva.com | 13-12-2022
    * @param Decimal subWeight
    * @param Decimal totalWeight
    * @return Decimal
    **/
    @TestVisible
    private static Decimal calculateGeoWeight(Decimal subWeight, Decimal totalWeight) {
        return subWeight * 100 / totalWeight;
    }
    /**
    * @description getCorrectListAct
    * @author alberto.martinez.carrero.contractor@bbva.com | 14-12-2022
    * @param Decimal subWeight
    * @param Decimal totalWeight
    * @return Decimal
    **/
    @TestVisible
    private static void fillSubindMaps(Boolean isDiff, List<sObject> oldList) {
        Decimal percSub = 0;
        Decimal maxPerc = 0;
        if(isDiff) {
            for(SObject obj : oldList) {
                final String key = getCorrectValMap(obj);
                if(weightMap.containsKey(key)) {
                    percSub = weightMap.get(key) + (Decimal) obj.get(SUBINDWEI_LIT);
                    weightMap.put(key,percSub);
                    if((Decimal) obj.get(SUBINDWEI_LIT) > maxPerc) {
                        maxWeightMap.put(key, obj);
                    }
                } else {
                    percSub = (Decimal) obj.get(SUBINDWEI_LIT);
                    weightMap.put(key,percSub);
                    maxPerc = percSub;
                    maxWeightMap.put(key, obj);
                }
            }
        }
    }
    /**
    * @description getCorrectListAct
    * @author alberto.martinez.carrero.contractor@bbva.com | 14-12-2022
    * @param Decimal subWeight
    * @param Decimal totalWeight
    * @return Decimal
    **/
    @TestVisible
    private static void processRecords() {
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if(!toInsert.isEmpty()) {
            insert toInsert;
        }
        if(!toInsertDiff.isEmpty()) {
            insert toInsertDiff;
        }
        if(!acctyMap.isEmpty() && !toInsert.isEmpty()) {
            createGeographies(acctyMap);
        }
        if(!acctyMapDiff.isEmpty() && !toInsertDiff.isEmpty()) {
            createGeographiesDiff(acctyMapDiff);
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a List Leveraged record related to aha
    * -----------------------------------------------------------------------------------------------
    * @param   Id recordId
    * @return  List<arce_Leveraged__c>
    * @example List<arce_Leveraged__c> leveragedList = getLeveragedData(recordId);
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__Leveraged__c> getLeveragedData(String recordId) {
        List<arce__Leveraged__c> leveragedList = new List<arce__Leveraged__c>();
        if (Schema.sObjectType.arce__Leveraged__c.isAccessible()) {
            leveragedList = [
                SELECT Id,arce__GN_Leveraged_Tier__c, arce__GN_Leveraged_EBITDA__c,arce__GN_Leveraged_Policy__c,arce__GN_Leveraged_Id__c, arce__GN_Leveraged_Gross_Debt__c,arce__AL_Adjusted_Ebitda_Value__c, arce__AL_Adjusted_Ebitda_comments__c, arce__AL_Adjusted_GD_Value__c, arce__AL_Adjusted_GD_comments__c, arce__AL_Ebitda_Adjusted_Reason__c, arce__AL_Financial_Sponsor__c, arce__AL_GD_Adjusted_Reason__c, arce__AL_Pretest_adjustments__c, arce__AL_Pyme_BCE__c, arce__AL_Ratio_Debt_Ebitda_Leveraged__c, arce__Account_has_Analysis_Id__c, arce__Arc_Gen_Leveraged_Record_Type__c, arce__Arc_Gen_Type__c, arce__LE_Leveraged_Entity_Excluded__c, arce__LE_Leveraged_Excluded_Reason__c, arce__LI_Acquisition_Options__c, arce__LI_Indicator__c, arce__LI_Leveraged_Adjusted_Reason__c, arce__LI_Leveraged_type__c, arce__Leveraged_ExtId__c, arce__Ratio_Calculated_Value__c,
                arce__MG_Leveraged_Parent_Name__c,
                arce__MG_Leveraged_Parent_Id__c,
                arce__MG_Leveraged_Group_Name__c,
                arce__MG_Leveraged_Parent_Name2__c,
                arce__MG_Leveraged_Parent_Id2__c,
                arce__MG_Leveraged_Group_Name2__c,
                arce__MG_Leveraged_Parent_Name3__c,
                arce__MG_Leveraged_Parent_Id3__c,
                arce__MG_Leveraged_Group_Name3__c
                FROM arce__Leveraged__c
                WHERE arce__Account_has_Analysis_Id__c =: recordId
                AND arce__Arc_Gen_Leveraged_Record_Type__c =: PRE_LEVERAGED];
        }

        return leveragedList;
    }
}