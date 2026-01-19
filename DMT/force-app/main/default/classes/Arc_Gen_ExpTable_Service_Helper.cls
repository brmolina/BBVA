/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExpTable_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_Policies_Controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-07-26 mariohumberto.ramirez.contractor@bbva.com
*             Add new method "hasChildren" that evals if the typology can has a child
* |2019-08-09 mariohumberto.ramirez.contractor@bbva.com
*             Add new method "deleteDuplicatesValues" that evals if the typology is duplicated
*             and delete duplicated record
* |2019-08-14 mariohumberto.ramirez.contractor@bbva.com
*             Deleted the method "deleteDuplicatesValues"
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new line that call the method getTypeOfCustomer in order to know the type of
*             customer to analyze
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new method sumTypologies
* |2019-10-04 mariohumberto.ramirez.contractor@bbva.com
*             Added new logic to change the name of the typology TOTAL GROUP when a subsidiary
*             customer is analyzed
* |2019-10-24 mariohumberto.ramirez.contractor@bbva.com
*             Added new Constant SUCCESS
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Update method sumTypologies()
* |2020-03-09 mariohumberto.ramirez.contractor@bbva.com
*             fix too many queries
* |2020-06-05 mariohumberto.ramirez.contractor@bbva.com
*             Added the subsidiary layout for the policy table to the orphan analysis
* |2020-08-12 antonio.munoz.perez.contractor@bbva.com
*             TOP DOWN Completion validations
* |2020-09-07 mariohumberto.ramirez.contractor@bbva.com
*             Added getMultiFactor method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-22 juanignacio.hita.contractor@bbva.com
*             Add name of the product in fillRow method
* |2021-03-18 juanignacio.hita.contractor@bbva.com
*             Change sumTypologies method for return exposure id record updated
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ExpTable_Service_Helper {
    /**
        * @Description: string with value SUCCESS
    */
    static final string SUCCESS = 'SUCCESS';
    /**
        * @Description: String with value "Group"
    */
    static final string S_GROUP = 'Group';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_ExpTable_Service_Helper serviceHelper = new Arc_Gen_ExpTable_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ExpTable_Service_Helper() {

    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that insert records in arce__limits_exposures__c
    * ----------------------------------------------------------------------------------------------------
    * @param recordId - Id of the account has analysis object
    * @return void
    * @example insertTypologies()
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void insertTypologies(Id recordId) {
        final List<arce__limits_exposures__c> exposureDatalvl1 = new List<arce__limits_exposures__c>();
        final List<arce__limits_exposures__c> exposureDatalvl2 = new List<arce__limits_exposures__c>();
        final Map<Id,arce__limits_exposures__c> parenExposureMap = new Map<Id,arce__limits_exposures__c>();
        final List<arce__limits_typology__c> limitsTypologyData = Arc_Gen_LimitsTypologies_Data.getTypologiesData();
        final String typeOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId);
        for (arce__limits_typology__c limitsTypo: limitsTypologyData) {
            if (limitsTypo.arce__risk_typology_level_type__c == '1') {
                final Id elementRecordTypeId = typeOfCustomer == S_GROUP ? arce.Arc_Gen_GenericUtilities.getRecordTypeLimExp((String)limitsTypo.arce__risk_typology_level_id__c + 'G') : arce.Arc_Gen_GenericUtilities.getRecordTypeLimExp(limitsTypo.arce__risk_typology_level_id__c);
                arce__limits_exposures__c limitExpdata = new arce__limits_exposures__c();
                limitExpdata.arce__account_has_analysis_id__c = recordId;
                limitExpdata.arce__limits_typology_id__c = limitsTypo.Id;
                limitExpdata.recordTypeId = elementRecordTypeId;
                limitExpdata.arce__last_approved_amount__c = 0;
                limitExpdata.arce__curr_approved_commited_amount__c = 0;
                limitExpdata.arce__curr_apprv_uncommited_amount__c = 0;
                limitExpdata.arce__current_formalized_amount__c = 0;
                limitExpdata.arce__outstanding_amount__c = 0;
                limitExpdata.arce__current_proposed_amount__c = 0;
                limitExpdata.arce__current_approved_amount__c = 0;
                exposureDatalvl1.add(limitExpdata);
                parenExposureMap.put(limitExpdata.arce__limits_typology_id__c, limitExpdata);
            }
        }
        arce.Arc_Gen_LimitsExposures_Data.insertExposureData(exposureDatalvl1);
        arce__limits_exposures__c limitExpdata;
        for (arce__limits_typology__c limitypo: limitsTypologyData) {
            if (limitypo.arce__risk_typology_level_type__c == '2') {
                final Id elementRecordTypeId2 = typeOfCustomer == S_GROUP ? arce.Arc_Gen_GenericUtilities.getRecordTypeLimExp(limitypo.arce__risk_typology_level_id__c + 'G') : arce.Arc_Gen_GenericUtilities.getRecordTypeLimExp(limitypo.arce__risk_typology_level_id__c);
                limitExpdata = new arce__limits_exposures__c();
                limitExpdata.arce__account_has_analysis_id__c = recordId;
                limitExpdata.arce__limits_typology_id__c = limitypo.Id;
                limitExpdata.recordTypeId = elementRecordTypeId2;
                limitExpdata.arce__last_approved_amount__c = 0;
                limitExpdata.arce__curr_approved_commited_amount__c = 0;
                limitExpdata.arce__curr_apprv_uncommited_amount__c = 0;
                limitExpdata.arce__current_formalized_amount__c = 0;
                limitExpdata.arce__outstanding_amount__c = 0;
                limitExpdata.arce__current_proposed_amount__c = 0;
                limitExpdata.arce__current_approved_amount__c = 0;
                limitExpdata.arce__limits_exposures_parent_id__c = parenExposureMap.get(limitypo.arce__risk_typology_parent_id__c).id;
                exposureDatalvl2.add(limitExpdata);
            }
            arce.Arc_Gen_LimitsExposures_Data.insertExposureData(exposureDatalvl2);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the data needed to create the policy table
    * --------------------------------------------------------------------------------------
    * @param recordId - id of the account_has_analysis.
    * @return ordenatedList a  List<Arc_Gen_TableRow> that contain the data to create the
    * policy table.
    * @example getNestedData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getNestedData(Id recordId) {
        List<Arc_Gen_TableRow> topRecords = new List<Arc_Gen_TableRow>();
        Map<String,List<Arc_Gen_TableRow>> recordsMap = new Map<String,List<Arc_Gen_TableRow>>();
        Arc_Gen_TableRow row;
        List<Arc_Gen_TableRow> elementList,recordsList;
        final Map <String,String> typeParams = new Map <String,String>();
        typeParams.put('typeClient',arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId));
        typeParams.put('consolidatedType',arce.Arc_Gen_GenericUtilities.getConsolidatedType(recordId));
        for(arce__limits_exposures__c record : arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId})) {
            row = new Arc_Gen_TableRow();
            row = fillRow(row,record,typeParams);
            if(record.arce__limits_exposures_parent_id__c == null) {
                topRecords.add(row);
            } else {
                elementList = new List<Arc_Gen_TableRow>();
                elementList = recordsMap.get(record.arce__limits_exposures_parent_id__c);
                if(elementList == null) {
                    elementList = new List<Arc_Gen_TableRow>();
                }
                elementList.add(row);
                recordsMap.put(record.arce__limits_exposures_parent_id__c,elementList);
            }
        }
        for(String key : recordsMap.keyset()) {
            recordsList = new List<Arc_Gen_TableRow>();
            recordsList = relateChilds(recordsMap.get(key),recordsMap);
            recordsMap.put(key,recordsList);
        }
        topRecords = relateChilds(topRecords,recordsMap);
        final List<Arc_Gen_TableRow> ordenatedList = new List<Arc_Gen_TableRow>();
        ordenatedList.addAll(orderList(topRecords));
        return ordenatedList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the childs of some typologies
    * --------------------------------------------------------------------------------------
    * @param recordsList a List<Arc_Gen_TableRow>
    * @param recordsMap al map with information of the table
    * @return ordenatedList a  List<Arc_Gen_TableRow> that contain the data to create the
    * policy table.
    * @example relateChilds(recordsList,recordsMap)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> relateChilds (List<Arc_Gen_TableRow> recordsList, Map<String,List<Arc_Gen_TableRow>> recordsMap) {
        final List<Arc_Gen_TableRow> newRecordsList = new List<Arc_Gen_TableRow>();
        for(Arc_Gen_TableRow element : recordsList) {
            List<Arc_Gen_TableRow> childsList = new List<Arc_Gen_TableRow>();
            childsList = recordsMap.get(element.name);
            if(childsList != null) {
                element.children = childsList;
            }
            newRecordsList.add(element);
        }
        return newRecordsList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the policy table
    * --------------------------------------------------------------------------------------
    * @param row an Arc_Gen_TableRow object that contain the info of the row of the policy
    * table
    * @param record an arce__limits_exposures__c object
    * @return row information of the policy table
    * @example fillRow(row,record)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_TableRow fillRow(Arc_Gen_TableRow row, arce__limits_exposures__c record, Map<String,String> typeParams) {
        final String typeClient = typeParams.get('typeClient');
        final String consolidatedType = typeParams.get('consolidatedType');
        Map<String,String> info = new Map<String,String>();
        Map<String,Decimal> order = new Map<String,Decimal>();
        row.name = record.Id;
        if (String.isNotBlank(record.arce__limits_typology_id__r.Name)) {
            row.tipology = (typeClient != 'Group' && record.arce__limits_typology_id__r.arce__risk_typology_level_id__c == System.Label.Arc_Gen_Typologic_TG_Id) ? System.Label.Arc_Gen_TotalSubsidiaryRisk : record.arce__limits_typology_id__r.Name;
        }
        if (String.isNotBlank(record.arce__Product_id__c)) {
            row.tipology = record.arce__Product_id__r.Name;
        }
        row.lastApproved = record.arce__last_approved_amount__c;
        row.commited = record.arce__curr_approved_commited_amount__c;
        row.uncommited = record.arce__curr_apprv_uncommited_amount__c;
        row.currentLimit = record.arce__current_formalized_amount__c;
        row.outstanding = record.arce__outstanding_amount__c;
        row.limitProposed = record.arce__current_proposed_amount__c;
        row.proposedApproved = record.arce__current_approved_amount__c;
        order.put('order',record.arce__limits_typology_id__r.arce__Typology_Order__c);
        info.put('typologyId',record.arce__limits_typology_id__c);
        info.put('typologyCode',record.arce__limits_typology_id__r.arce__risk_typology_level_id__c);
        info.put('recordtypeid',record.recordTypeId);
        if (record.arce__limits_exposures_parent_id__c == null) {
            info.put('level', '1');
        } else if (record.arce__limits_exposures_parent_id__r.arce__limits_exposures_parent_id__c == null) {
            info.put('level', '2');
        } else {
            info.put('level', '3');
        }
        info.put('clientType', typeClient);
        info.put('consolidatedType', consolidatedType);
        row.hasChild = hasChildren(record, info);
        row.info = info;
        row.order = order;
        return row;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description returns true if the typology can has a child
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-26
    * @param record - arce__limits_exposures__c object
    * @param info - map with some typology data
    * @return Boolean - true if the typology can has a child
    * @example hasChildren(record)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean hasChildren(arce__limits_exposures__c record, Map<String,String> info) {
        Boolean hasChild = false;
        final String typologyCode = info.get('typologyCode');
        switch on typologyCode {
            when 'TP_0002', 'TP_0008', 'TP_0010', 'TP_0011', 'TP_0012', 'TP_0014' {
                hasChild = true;
            }
            when else {
                hasChild = false;
            }
        }
        return hasChild;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return the a list of order elements for the policy table
    * --------------------------------------------------------------------------------------
    * @param newRecordsList records to ordenate
    * @return ordenatedList a list of order elements for the policy table
    * @example orderList(newRecordsList)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> orderList(List<Arc_Gen_TableRow> newRecordsList) {
        List<Arc_Gen_TableRow> ordenatedList = new List<Arc_Gen_TableRow>();
        for (Integer i = 1; i <= newRecordsList.size(); i++) {
            for(Arc_Gen_TableRow elemntToIterate : newRecordsList) {
                if (elemntToIterate.order.get('order') == i) {
                    ordenatedList.add(elemntToIterate);
                }
            }
        }
        return ordenatedList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Delete records
    * --------------------------------------------------------------------------------------
    * @param recordId - id of the account_has_analysis.
    * @return response.
    * @example deleteRecordTable(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,String> deleteRecordTable(Id recordId) {
        Map<String,String> response = new Map<String,String>();
        final List<arce__limits_exposures__c> listToDelete = arce.Arc_Gen_LimitsExposures_Data.conRecord2Delete(recordId);
        if(listToDelete.size() > 0) {
            arce.Arc_Gen_LimitsExposures_Data.deleteExpRecord(listToDelete);
        }
        response.put('response', SUCCESS);
        response.put('message', System.Label.Arc_Gen_Registros_eliminados_con_exito);
        return response;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that sum typologies
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2019-09-30
    * @param recordId - Id of the account has analysis object
    * @return String
    * @example String ret = sumTypologies(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String sumTypologies(Id recordId) {
        double limitProposed = 0;
        String exposureId;
        final List<arce__limits_exposures__c> exposureData = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId});
        for (arce__limits_exposures__c exposure: exposureData) {
            if (exposure.arce__limits_typology_id__r.arce__risk_typology_level_id__c == System.Label.Arc_Gen_ProjectFinance || exposure.arce__limits_typology_id__r.arce__risk_typology_level_id__c == System.Label.Arc_Gen_TOTAL_CORPORATE_RISK) {
                limitProposed += exposure.arce__current_proposed_amount__c;
            }
        }
        for (arce__limits_exposures__c exposure: exposureData) {
            if (exposure.arce__limits_typology_id__r.arce__risk_typology_level_id__c == System.Label.Arc_Gen_TOTAL_CREDIT_RISK) {
                exposureId = exposure.Id;
                exposure.arce__current_proposed_amount__c = limitProposed;
            }
        }
        arce.Arc_Gen_LimitsExposures_Data.updateExposureData(exposureData);
        return exposureId;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - get the multiplication factor
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-09-07
    * @param prevLimExpLts - previuos arce__limits_exposures__c
    * @param currLimExpInf - current arce__limits_exposures__c
    * @return Double - multiplication factor
    * @example getMultiFactor(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Double getMultiFactor(List<arce__limits_exposures__c> prevLimExpLts, List<arce__limits_exposures__c> currLimExpInf) {
        if (String.isBlank(currLimExpInf[0].arce__account_has_analysis_id__r.arce__magnitude_unit_type__c)) {
                throw new AuraHandledException(Label.Arc_Gen_FillDataIn);
            }
            final arce__Account_has_Analysis__c accHasDummy = new arce__Account_has_Analysis__c();
            accHasDummy.arce__magnitude_unit_type__c = currLimExpInf[0].arce__account_has_analysis_id__r.arce__magnitude_unit_type__c;
            accHasDummy.arce__prev_magnitude_unit_type__c = prevLimExpLts[0].arce__account_has_analysis_id__r.arce__magnitude_unit_type__c;
            return arce.Arc_Gen_GenericUtilities.getMultiplicationFactor('arce__magnitude_unit_type__c', 'arce__prev_magnitude_unit_type__c', accHasDummy);
    }
}