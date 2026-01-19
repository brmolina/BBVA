/**
* @File Name          : Arc_Gen_Charts_controller.cls
* @Description        :
* @Author             : luisruben.quinto.munoz@bbva.com
* @Group              :
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 26/8/2019 13:00:40
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    4/7/2019 11:35:48   luisruben.quinto.munoz@bbva.com     Initial Version
* 1.1    4/7/2019 17:00:13   luisruben.quinto.munoz@bbva.com     fix in filter for chart
* 1.2  17/10/2019 18:23:00   manuelhugo.castillo.contractor@bbva.com  Fix CollectionType and get collection
**/
public with sharing class Arc_Gen_Charts_controller {
/**
*-------------------------------------------------------------------------------
* @description getChartsJsonComponent gets the info to build charts in the front.
*--------------------------------------------------------------------------------
* @author  luisruben.quinto.munoz@bbva.com
* @date     11/04/2019
* @param collectionType type of collection.
* @param  recordId Id of the record.
* @return String charts
**/
  public String getChartsJsonComponent(String collectionType, String recordId) {
    Arc_Gen_Charts_service service = new Arc_Gen_Charts_service();
    List<String> dataList = new List<String>();
    if (collectionType == 'Geographies' || collectionType == 'Activities') {
      dataList = service.getChartsData(collectionType, recordId);
    }
    String collection = service.getCollection(collectionType, recordId);
    List<String> chartJsonList = buildJson(recordId,dataList,collection);
    String charts = '';
    for(String jsonChart: chartJsonList) {
      charts += '{"name":"chgn:Chart_Generator","attributes":{"RecordId":"'+ recordId +'","JSON_Chart":"'+jsonChart+'"}},';
    }
    return charts;
  }
  /**
*-------------------------------------------------------------------------------
* @description buildJson build the jsonthe component interpretes in the front
*--------------------------------------------------------------------------------
* @author  luisruben.quinto.munoz@bbva.com
* @date     11/04/2019
* @param collectionType type of collection.
* @param List<String> dataList elements to build.
* @param  recordId Id of the record.
* @return String charts
**/
  public List<String> buildJson(Id recordId, List<String> dataList, String collectionType ){
    List<String> jsonList = new List<String>();
    for(String element : dataList) {
      String json = '{'+
                    '\\"JSON_Setup\\":{'+
                    '\\"enableButton\\":\\"false\\",'+
                    '\\"canvas_ID\\":\\"'+element+'\\",'+
                    '\\"config\\":{'+
                    '\\"type\\":\\"doughnut\\",'+
                    '\\"options\\":{'+
                    '\\"legend\\":{'+
                    '\\"display\\":true,'+
                    '\\"position\\":\\"right\\"'+
                    '},'+
                    '\\"maintainAspectRatio\\":\\"true\\",'+
                    '\\"responsive\\":\\"false\\",'+
                    '\\"scales\\":{'+
                    '\\"yAxes\\":['+
                    '{'+
                    '\\"display\\":false'+
                    '}'+
                    '],'+
                    '\\"xAxes\\":['+
                    '{'+
                    '\\"display\\":false'+
                    '}'+
                    ']'+
                    '},'+
                    '\\"title\\":{'+
                    '\\"display\\":\\"true\\",'+
                    '\\"fontSize\\":\\"12\\",'+
                    '\\"text\\":\\"'+element+'\\"'+
                    '}'+
                    '}'+
                    '}'+
                    '},'+
                    '\\"JSON_Query\\":{'+
                    '\\"labels\\":['+
                    '\\"query0:DCName\\"'+
                    '],'+
                    '\\"querys\\":['+
                    '{  '+
                    '\\"queryObject\\":\\"arce__Table_Content_per_Analysis__c\\",'+
                    '\\"queryFields\\":['+
                    '\\"sum(arce__table_content_percentage__c)\\",'+
                    '\\"max(arce__Data_collection_name__c) DCName\\",'+
                    '\\"arce__Data_Collection_Id__c\\"'+
                    '],'+
                    '\\"filters\\":['+
                    '{  '+
                    '\\"name\\":\\"filter1\\",'+
                    '\\"field\\":\\"arce__account_has_analysis_id__c\\",'+
                    '\\"operator\\":\\"=\\",'+
                    '\\"value\\":\\"\''+ String.valueof(recordId) +'\'\\"'+
                    '},'+
                    '{'+
                    '\\"name\\":\\"filter2\\",'+
                    '\\"field\\":\\"arce__table_content_year__c\\",'+
                    '\\"operator\\":\\"=\\",'+
                    '\\"value\\":\\"'+element+'\\"'+
                    '},'+
                    '{'+
                    '\\"name\\":\\"filter3\\",'+
                    '\\"field\\":\\"arce__collection_table__c\\",'+
                    '\\"operator\\":\\"=\\",'+
                    '\\"value\\":\\"'+collectionType+'\\"'+
                    '}'+
                    '],'+
                    '\\"filterStructure\\":\\"filter1 AND filter2 AND filter3\\",'+
                    '\\"groupBy\\":['+'\\"arce__Data_Collection_Id__c\\"'+'],'+
                    '\\"orderBy\\":[],'+
                    '\\"borderColor\\":[],'+
                    '\\"backgroundColor\\":['+
                    '\\"#D8BE75\\",'+
                    '\\"#2DCCCD\\",'+
                    '\\"#1973B8\\",'+
                    '\\"#F35E61\\",'+
                    '\\"#5BBEFF\\",'+
                    '\\"#48AE64\\",'+
                    '\\"#F78BE8\\",'+
                    '\\"#004481\\"'+
                    '],'+
                    '\\"legendLabel\\":\\"'+element+'\\",'+
                    '\\"data\\":\\"sum(arce__table_content_percentage__c)\\"'+
                    '}'+
                    ']'+
                    '}'+
                    '}';
          jsonList.add(json);
        }
    return jsonList;
  }
}