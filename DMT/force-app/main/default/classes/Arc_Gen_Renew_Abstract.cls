/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Renew_Abstract
* @Author   amunguia.contractor@bbva.com
* @Date     Created: 25/04/2022
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class "Arc_Gen_Renew_Abstract"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2022-04-25 amunguia.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public with sharing abstract class Arc_Gen_Renew_Abstract {
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__Activity_Split__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String ACCTYOBJ = 'arce__Activity_Split__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description arce__Activity_Split__c.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String ACCTY2012OBJ = 'arce__Activity_Split_2012__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description YEAR.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final Integer YEAR = 12;
    /** ----------------------------------------------------------------------------------------------------
    * @Description fieldsMap.
    * ---------------------------------------------------------------------------------------------------- **/
    private static Map<String, String> mapFields2012 = new Map<String, String>{'arce__gf_subactivity_id__c'=>'arce__gf_subactivity_id_2012__c',
                                                                            'arce__template_type__c'=>'arce__Template_type_2012__c',
                                                                            'arce__subsector_id__c'=>'arce__Subsector_id_2012__c',
                                                                            'arce__gf_company_economic_actvy_id__c'=>'arce__gf_company_economic_actvy_id_2012__c',
                                                                            'arce__Order_Subactivity__c'=>'arce__Order_Subactivity_2012__c'};

    /**
    * @description makeTheCallout
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param String currId
    * @param List<arce__Financial_Statements__c> ffeeList
    * @param List<String> ffeeIds
    **/
    public static void makeTheCallout(String currId, List<arce__Financial_Statements__c> ffeeList, List<String> ffeeIds) {
        Arc_Gen_ModalFinanStatemController.callEngineFinancialState(currId, ffeeList, ffeeIds, true, false, null, null);
    }

    /**
    * @description SObject with the merge fields
    * @author amunguia.contractor@bbva.com | 09-08-2021
    * @param SObject updatedRecord
    * @param SObject currentRecord
    * @param String objectName
    * @return SObject
    **/
    public static SObject mergeRecords(SObject updatedRecord, SObject currentRecord, List<String> fields) {
        final Boolean isRen2012to2012P = checkIsRen2012to2012P(updatedRecord, currentRecord);
        for (String field : fields) {
            String field2;
            if(!field.contains('__r.') && field != 'Id') {
                if(isRen2012to2012P && mapFields2012.containsKey(field)) {
                    field2 = mapFields2012.get(field);
                }
                final String fieldToRet = String.isBlank(field2) ? field : field2;
                if(currentRecord.get(field) != null) {
                    updatedRecord.put(fieldToRet, currentRecord.get(field));
                }
            }
        }
        return updatedRecord;
    }

    /**
    * @description SObject with the merge fields
    * @author amunguia.contractor@bbva.com | 09-08-2021
    * @param SObject updatedRecord
    * @param SObject currentRecord
    * @param String objectName
    * @return SObject
    **/
    public static void queryActivities(Integer monthsBtwe, Map<String, List<String>> fieldsMap) {
        fieldsMap.put('arce__Activity_Splits__r',getFields(ACCTYOBJ));
        fieldsMap.put('arce__Activity_Splits_2012__r',getFields(ACCTY2012OBJ));
    }

    /**
    * @description getFields
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param String sObjectType
    * @return List<String>
    **/
    private static List<String> getFields(String sObjectType) {
        final List<String> returnedFields = new List<String>();
        final Map<String, SObjectField> fields = Schema.getGlobalDescribe().get(sObjectType).getDescribe().Fields.getMap();
        for(String field : fields.keySet()) {
            final Schema.DescribeFieldResult result = fields.get(field).getDescribe();
            if(result.isUpdateable()) {
                returnedFields.add(field);
            }
        }
        return returnedFields;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method to get all data needed to clone.
    *--------------------------------------------------------------------------------
    * @author saimassimilianno.jordana.contractor@bbva.com
    * @date xx-03-2022
    * @param varRecord recordId of the account_has_analysis.
    * @return Map<String(tabCode), tabAttributes(tabConfigAttr)> tabsConfigs
    * @example public static Map<String, List<Section>> getTabConfig(gotTabs, monthsBtwe)
    **/
    public static Map<String, List<String>> getTabConfig(List<String > gotTabs, Integer monthsBtwe) {
        final Map<String, List<String>> toReturn = new Map<String, List<String>>();
        final String configtoGet = monthsBtwe <= 5 ? 'sections5' : monthsBtwe >= YEAR ? 'sections12' : 'sections512';
        for(String renew : gotTabs) {
                final Map<String,Map<String, List<String>>> tabAttr = (Map<String,Map<String, List<String>>>)JSON.deserialize(renew, Map<String,Map<String, List<String>>>.class);
                if(tabAttr.containsKey(configtoGet)) {
                    toReturn.putAll(tabAttr.get(configtoGet));
                }
        }
        return toReturn;
    }

    /**
    * @description getFieldConfigs
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param Set<String> tabs
    * @param Map<String List<String>> sections
    * @return List<dyfr__Field_Config__c>
    **/
    public static List<dyfr__Field_Config__c> getFieldConfigs(Set<String> tabs, Map<String,List<String>> sections) {//NOSONAR
        final List<dyfr__Field_Config__c> result = new List<dyfr__Field_Config__c>();
        final Set<String> currSections = sections.keySet();//NOSONAR
        String query = 'SELECT dyfr__Relationship_Object_Name__c, dyfr__Map_field__c, dyfr__Section_name__c, dyfr__Tab__r.dyfr__Tab_Code__c, dyfr__Subsection_name__c FROM dyfr__Field_Config__c ';
        final List<String> conditions = new List<String>{'dyfr__Section_name__c != null', 'dyfr__Map_field__c != null', 'exclude_from_renewal__c = false', 'dyfr__Tab__r.dyfr__Tab_Code__c IN :tabs', 'dyfr__Section_name__c IN :currSections', 'dyfr__Read_only__c = false'};
        query += ' WHERE ' + String.join(conditions, ' AND ');
        for(dyfr__Field_Config__c field : Database.query(String.escapeSingleQuotes(query))) {
            if(!sections.get(field.dyfr__Section_name__c).isEmpty() && sections.get(field.dyfr__Section_name__c).contains(field.dyfr__Subsection_name__c)) {
                result.add(field);
            } else {
                result.add(field);
            }
        }
        return result;
    }

    /**
    * @description checkIsRen2012to2012P
    * @author alberto.martinez.carrero.contractor@bbva.com | 09-12-2022
    * @param SObject updatedRecord
    * @param SObject currentRecor
    * @return Boolean
    **/
    @TestVisible
    private static Boolean checkIsRen2012to2012P (SObject updatedRecord, SObject currentRecord) {
        return currentRecord.getSObjectType().getDescribe().getName() == 'arce__Activity_Split_2012__c' && updatedRecord.getSObjectType().getDescribe().getName() == 'arce__Activity_Split__c';
    }

    /**
    * @description abstractMethod
    * @author amunguia.contractor@bbva.com | 04-25-2022
    * @param ;
    * @return abstract
    **/
    public abstract Integer abstractMethod();
}