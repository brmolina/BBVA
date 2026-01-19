/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TableContentPerAnalysis_Data
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data Service for arce__Table_Content_per_Analysis__c object
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2019-08-26 eduardoefrain.hernandez.contractor@bbva.com
*             Update execRepGetTblsRelatedArce method
* |2019-11-04 javier.soto.carrascosa@@bbva.com
*             Add new methods
* |2020-01-30 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add missing custom labels
* |2020-03-31 juanignacio.hita.contractor@bbva.com
*             Update sonar changes required
* |2020-04-15 mariohumberto.ramirez.contractor@bbva.com
*             Added getTableContentPrevValidByCode and getFITableStructure methods
* |2020-07-27 mariohumberto.ramirez.contractor@bbva.com
*             Added getColumnsOfGeoActTb and getGeoActRowStructure methods
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-12 joseluis.garcia4.contractor@bbva.com
*             Group Activities/Geographies rows in executive summary.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public without sharing class Arc_Gen_TableContentPerAnalysis_Data {
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain an error message
    * -----------------------------------------------------------------------------------------------
    * @param - void
    * @return - String with an error message
    * @example responseWrapperMnBanks wrapper = new responseWrapperMnBanks()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapperCntntAnaly {
        /**
        * @Description: String with an error message
        */
        @AuraEnabled public String gblErrorResponse {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Insert arce__Table_Content_per_Analysis__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toIns array of objects to insert
    * @return   ResponseWrapperCntntAnaly object with string in case of error
    * @example  insertTableContent(toIns)
    * */
    public static ResponseWrapperCntntAnaly insertTableContent(arce__Table_Content_per_Analysis__c[] toIns) {
        final ResponseWrapperCntntAnaly wrapper = new ResponseWrapperCntntAnaly();
        try{
            if(toIns.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Insert toIns;
        } catch (DmlException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Update arce__Table_Content_per_Analysis__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toUpd array of objects to insert
    * @return   ResponseWrapperCntntAnaly object with string in case of error
    * @example  updateTableContent(toUpd)
    * */
    public static ResponseWrapperCntntAnaly updateTableContent(arce__Table_Content_per_Analysis__c[] toUpd) {
        final ResponseWrapperCntntAnaly wrapper = new ResponseWrapperCntntAnaly();
        try{
            if(toUpd.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Update toUpd;
        } catch (DmlException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Delte arce__Table_Content_per_Analysis__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toDel array of objects to insert
    * @return   ResponseWrapperCntntAnaly object with string in case of error
    * @example  deleteTableContent(toDel)
    * */
    public static ResponseWrapperCntntAnaly deleteTableContent(arce__Table_Content_per_Analysis__c[] toDel) {
        final ResponseWrapperCntntAnaly wrapper = new ResponseWrapperCntntAnaly();
        try{
            if(toDel.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Delete toDel;
        } catch (DmlException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__Table_Content_per_Analysis__c related to arce__account_has_analysis_id__c and grouped
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   AggregateResult[] array with arce__Table_Content_per_Analysis__c grouped related
    * @example  execRepGetFnHighlights(rid)
    * */
    public static AggregateResult[] execRepGetFnHighlights(Id rid) {
        List<String> tblscpa = Label.Arc_Gen_ExecRepDtlCllHigh.split(',');
        return [Select arce__table_content_year__c, arce__collection_order_type__c, MIN(arce__Data_collection_name__c) data, SUM(arce__table_content_percentage__c) val1, SUM(arce__table_content_value__c) val2 from arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_order_type__c in :tblscpa group by arce__table_content_year__c, arce__collection_order_type__c order by arce__collection_order_type__c asc];
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__Table_Content_per_Analysis__c related to arce__account_has_analysis_id__c and grouped with a custom where
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-17
    * @param    rid id related to arce__account_has_analysis_id__c
    * @param    typ to get diferent werys where greatert than arce__arce_collection_order_number__c
    * lesser than arce__arce_collection_order_number__c or without comparision with arce__arce_collection_order_number__c
    * @param	arcColltbl value to compare to arce__collection_table__c
    * @param	arcCollNumb value to compare to arce__arce_collection_order_number__c
    * @return   AggregateResult[] array with arce__Table_Content_per_Analysis__c grouped related
    * @example  execRepGetFnHighlights(rid)
    * */
    public static AggregateResult[] execRepGetTblsRelatedArce(Id rid,String typ,String arcColltbl,Decimal arcCollNumb) {
        AggregateResult[] ret;
        switch on typ{
            when 'gtt'{
                ret = [Select arce__table_content_year__c, arce__collection_order_type__c, MIN(arce__Data_collection_name__c) data, SUM(arce__table_content_percentage__c) val1, SUM(arce__table_content_value__c) val2 from arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_table__c = :arcColltbl and arce__arce_collection_order_number__c > :arcCollNumb group by arce__table_content_year__c, arce__collection_order_type__c order by arce__collection_order_type__c asc];
            }
            when 'ltt'{
                ret = [Select arce__table_content_year__c, arce__collection_order_type__c, MIN(arce__Data_collection_name__c) data, SUM(arce__table_content_percentage__c) val1, SUM(arce__table_content_value__c) val2 from arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_table__c = :arcColltbl and arce__arce_collection_order_number__c < :arcCollNumb group by arce__table_content_year__c, arce__collection_order_type__c order by arce__collection_order_type__c asc];
            }
            when 'non'{
                ret = [Select arce__table_content_year__c, arce__collection_order_type__c, MIN(arce__Data_collection_name__c) data, SUM(arce__table_content_percentage__c) val1, SUM(arce__table_content_value__c) val2 from arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_table__c = :arcColltbl group by arce__table_content_year__c, arce__collection_order_type__c order by arce__collection_order_type__c asc];
            }
            when 'mat'{
                List<arce__Account_has_Analysis__c> lstAccAnlsys = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{rid});
                if (lstAccAnlsys.isEmpty()) {
                    ret = new List<AggregateResult>();
                } else {
                    if (lstAccAnlsys[0].arce__debt_maturity_available_type__c == '1') {
                        ret = [Select arce__table_content_year__c, arce__Data_Collection_Id__r.Name, MIN(arce__Data_collection_name__c) data, SUM(arce__table_content_percentage__c) val1, SUM(arce__table_content_value__c) val2 from arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_table__c = :arcColltbl group by arce__table_content_year__c, arce__Data_Collection_Id__r.Name order by arce__Data_Collection_Id__r.Name  asc];
                    }
                    else {
                        ret = new List<AggregateResult>();
                    }
                }
            }
            when else{
                ret = new List<AggregateResult>();
            }
        }
        return ret;
    }
/**
*-------------------------------------------------------------------------------
* @description getRecordsYears gets the info to build charts in the front.
*--------------------------------------------------------------------------------
* @author  luisruben.quinto.munoz@bbva.com
* @date     11/04/2019
* @param collectionType type of collection.
* @param  recordId Id of the record.
* @return List<arce__Table_Content_per_Analysis__c>
**/
  public List<arce__Table_Content_per_Analysis__c> getRecordsYears(String collectionType, String recordId) {
    Id idRT = arce.Arc_Gen_GenericUtilities.getRecType('arce__Table_Content_per_Analysis__c', collectionType);
    return [SELECT arce__table_content_year__c From arce__Table_Content_per_Analysis__c WHERE arce__account_has_analysis_id__c = :recordId and recordTypeId =: idRT order by arce__table_content_year__c DESC ];
  }
/**
*-------------------------------------------------------------------------------
* @description getRecordsYears gets the info to build charts in the front.
*--------------------------------------------------------------------------------
* @author  ricardo.almanza.contractor@bbva.com
* @date     21/01/2020
* @param collectionType type of collection.
* @param  recordId Id of the record.
* @return List<arce__Table_Content_per_Analysis__c>
**/
  public static List<arce__Table_Content_per_Analysis__c> getRecordsbyArcAcc(String collectionType,List<String> recordId) {
    Id idRT = arce.Arc_Gen_GenericUtilities.getRecType('arce__Table_Content_per_Analysis__c', collectionType);
    return [SELECT Id,Name,arce__table_content_year__c,arce__table_content_percentage__c,arce__Data_Collection_Id__r.Name From arce__Table_Content_per_Analysis__c WHERE arce__account_has_analysis_id__c = :recordId and recordTypeId =: idRT order by arce__table_content_year__c DESC ];
  }

  /**
  *-------------------------------------------------------------------------------
  * @description getRecordsCollectionTable gets the collection Table to build charts in the front.
  *--------------------------------------------------------------------------------
  * @author manuelhugo.castillo.contractor@bbva.com
  * @date   17/10/2019
  * @param  Collection of collection Table
  * @param  recordId Id of the record.
  * @return List<arce__Table_Content_per_Analysis__c>
  **/
  public List<arce__Table_Content_per_Analysis__c> getRecordsCollectionTable(String collectionType, String recordId) {
    Id idRT = arce.Arc_Gen_GenericUtilities.getRecType('arce__Table_Content_per_Analysis__c', collectionType);
    return [SELECT arce__collection_table__c From arce__Table_Content_per_Analysis__c WHERE arce__account_has_analysis_id__c = :recordId and recordTypeId =: idRT order by arce__table_content_year__c DESC];
  }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get records of arce__Table_Content_per_Analysis__c related to code terms of arce__Data_Collection__c
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   15/04/2020
    * @param  accHasAnIdLts ids of arce__account_has_analysis__c
    * @param  codeTermLts List of data collection code terms
    * @return Map<String,Map<String,Double>>
    * @example getTableContentValidByCode(accHasAnIdLts,codeTermLts)
    *------------------------------------------------------------------------------------------------
    **/
    public static Map<Id,Map<String,Double>> getTableContentValidByCode(List<Id> accHasAnIdLts, List<String> codeTermLts) {
        List<arce__Table_Content_per_Analysis__c> tableCntData = [SELECT Id,arce__account_has_analysis_id__c,arce__account_has_analysis_id__r.arce__participant_name__c,arce__account_has_analysis_id__r.arce__long_rating_value_id__c,
                                                                        arce__Data_Collection_Id__r.arce__collection_code_term__c,arce__table_content_value__c,arce__table_content_percentage__c,arce__table_content_year__c
                                                                    FROM arce__Table_Content_per_Analysis__c
                                                                    WHERE arce__account_has_analysis_id__c = :accHasAnIdLts
                                                                    AND arce__Data_Collection_Id__r.arce__collection_code_term__c = :codeTermLts
                                                                    AND arce__valid_fin_statement__c = true
                                                                    ORDER BY arce__account_has_analysis_id__r.arce__participant_name__c];
        return getFITableStructure(tableCntData);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get records of arce__Table_Content_per_Analysis__c related to code terms of arce__Data_Collection__c
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   15/04/2020
    * @param  accHasAnIdLts ids of arce__account_has_analysis__c
    * @param  codeTermLts List of data collection code terms
    * @return Map<String,Map<String,Double>>
    * @example getTableContentValidByCode(accHasAnIdLts,codeTermLts)
    *------------------------------------------------------------------------------------------------
    **/
    public static Map<Id,Map<String,Double>> getTableContentPrevValidByCode(List<Id> accHasAnIdLts, List<String> codeTermLts) {
        List<arce__Table_Content_per_Analysis__c> tableCntData = [SELECT Id,arce__account_has_analysis_id__c,arce__account_has_analysis_id__r.arce__participant_name__c,arce__account_has_analysis_id__r.arce__long_rating_value_id__c,
                                                                        arce__Data_Collection_Id__r.arce__collection_code_term__c,arce__table_content_value__c,arce__table_content_percentage__c,arce__table_content_year__c
                                                                    FROM arce__Table_Content_per_Analysis__c
                                                                    WHERE arce__account_has_analysis_id__c = :accHasAnIdLts
                                                                    AND arce__Data_Collection_Id__r.arce__collection_code_term__c = :codeTermLts
                                                                    AND arce__previous_valid__c = true
                                                                    ORDER BY arce__account_has_analysis_id__r.arce__participant_name__c, arce__table_content_year__c];
        return getFITableStructure(tableCntData);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get a data structure to build the financial information table
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   15/04/2020
    * @param  tableCntData - table content per analysis object
    * @return Map<String,Map<String,Double>>
    * @example getFITableStructure(tableCntData)
    *------------------------------------------------------------------------------------------------
    **/
    private static Map<Id,Map<String,Double>> getFITableStructure(List<arce__Table_Content_per_Analysis__c> tableCntData) {
        Map<Id,Map<String,Double>> mapRet = new Map<Id,Map<String,Double>>();
        Map<String,Double> mapAux = new Map<String,Double>();
        if (!tableCntData.isEmpty()) {
            Id tempAccHasId = tableCntData[0].arce__account_has_analysis_id__c;
            integer ite = 0;
            String year = '';
            Double yearValue = 0;
            for (arce__Table_Content_per_Analysis__c tableCnt: tableCntData) {
                year = tableCnt.arce__table_content_year__c.left(4);
                yearValue = Double.valueOf(year);
                if (tempAccHasId == tableCnt.arce__account_has_analysis_id__c) {
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c, tableCnt.arce__table_content_value__c);
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c + '_per', tableCnt.arce__table_content_percentage__c);
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c + '_year', yearValue);
                    ite++;
                } else {
                    mapRet.put(tempAccHasId, mapAux);
                    tempAccHasId = tableCnt.arce__account_has_analysis_id__c;
                    mapAux = new Map<String,Double>();
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c, tableCnt.arce__table_content_value__c);
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c + '_per', tableCnt.arce__table_content_percentage__c);
                    mapAux.put(tableCnt.arce__Data_Collection_Id__r.arce__collection_code_term__c + '_year', yearValue);
                    ite++;
                }
                if(ite == tableCntData.size() - 1) {
                    mapRet.put(tempAccHasId, mapAux);
                }
            }
        }
        return mapRet;
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get the columns to build the geography and activity table
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param  recordId - id of the account has analysis object
    * @param  type - table type
    * @return List<String>
    * @example getColumnsOfGeoActTb(recordId, type)
    *------------------------------------------------------------------------------------------------
    **/
    public static List<String> getColumnsOfGeoActTb(Id recordId, String type) {
        final List<AggregateResult> col = [SELECT arce__table_content_year__c
                                                                FROM arce__Table_Content_per_Analysis__c
                                                                WHERE arce__account_has_analysis_id__c = :recordId
                                                                AND arce__collection_table__c = :type
                                                                GROUP BY arce__table_content_year__c
                                                                ORDER BY arce__table_content_year__c DESC];
        final List<String> columns = new List<String>();
        for (AggregateResult colData: col) {
            columns.add(String.valueOf(colData.get('arce__table_content_year__c')));
        }
        return columns;
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get the rows to build the geography and activity table
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param  recordId - id of the account has analysis object
    * @param  type - table type
    * @param  columns - columns of the table
    * @return List<Map<String,String>>
    * @example getGeoActRowStructure(recordId, type, columns)
    *------------------------------------------------------------------------------------------------
    **/
    public static List<Map<String,String>> getGeoActRowStructure(Id recordId, String type, List<String> columns) {
        final List<arce__Table_Content_per_Analysis__c> data = [SELECT Id, arce__Data_collection_name__c, arce__table_content_year__c, arce__table_content_percentage__c
                                                                FROM arce__Table_Content_per_Analysis__c
                                                                WHERE arce__account_has_analysis_id__c = :recordId
                                                                AND arce__collection_table__c = :type
                                                                ORDER BY arce__Data_collection_name__c, arce__table_content_year__c DESC];
        final Map<String, Map<String, Decimal>> groupedRes = getGroupedGeoAct(data);

        List<Map<String,String>> geoActMapLts = new List<Map<String,String>>();
        for (String geoActName : groupedRes.keySet()) {
            final Map<String, String> geoActData = new Map<String, String>();
            geoActData.put('geoAct', geoActName);

            final Map<String, Decimal> geoActYearData = groupedRes.get(geoActName);
            for (String year: columns) {
                if (geoActYearData.containsKey(year)) {
                    geoActData.put(year, String.valueOf(geoActYearData.get(year)) + '%');
                } else {
                    geoActData.put(year, '-');
                }
            }
            geoActMapLts.add(geoActData);
        }
        return geoActMapLts;
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get the rows to build the geography and activity table
    *------------------------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @date   2020-11-12
    * @param  data - list of data for geographies/activities
    * @return Map<String, Map<String, Decimal>> grouped info for geographies/activities per year
    *------------------------------------------------------------------------------------------------
    **/
    private static Map<String, Map<String, Decimal>> getGroupedGeoAct(List<arce__Table_Content_per_Analysis__c> data) {
        final Map<String, Map<String, Decimal>> groupedRes = new Map<String, Map<String, Decimal>>();
        for (arce__Table_Content_per_Analysis__c geoAct : data) {
            final String geoActYear = geoAct.arce__table_content_year__c;
            final String geoActName = geoAct.arce__Data_collection_name__c;
            final Decimal geoActPer = geoAct.arce__table_content_percentage__c;
            if (groupedRes.containsKey(geoActName)) {
                final Map<String, Decimal> geoActMap = groupedRes.get(geoActName);
                if (geoActMap.containsKey(geoActYear)) {
                    geoActMap.put(geoActYear, geoActMap.get(geoActYear) + geoActPer);
                } else {
                    geoActMap.put(geoActYear, geoActPer);
                }
            } else {
                final Map<String, Decimal> initialMap = new Map<String, Decimal>();
                initialMap.put(geoActYear, geoActPer);
                groupedRes.put(geoActName, initialMap);
            }
        }

        return groupedRes;
    }
}