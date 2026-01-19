/**
* @Name          : Arc_Gen_Charts_service.cls
* @Description        : Class for the Dynamic Chart component
* @Project:      	    ARCE - BBVA Bancomer
* @Author             : luisruben.quinto.munoz@bbva.com
* @Date     Created: 2019-11-04
* @Group              : ARCE
* @Changes :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    3/5/2019 20:53:04   luisruben.quinto.munoz@bbva.com     Initial Version
* 1.1  17/10/2019 18:29:00   manuelhugo.castillo.contractor@bbva.com  Add getCollection method
* 1.2  04/11/2019 18:29:00   javier.soto.carrascosa@bbva.com  add link to locator
**/
public with sharing class Arc_Gen_Charts_service {
/**
*-------------------------------------------------------------------------------
* @description getChartsData gets the info to build charts in the front.
*--------------------------------------------------------------------------------
* @author  luisruben.quinto.munoz@bbva.com
* @date     11/04/2019
* @param collectionType type of collection.
* @param  recordId Id of the record.
* @return String resultsList
**/
  public List<String> getChartsData (String collectionType, String recordId) {
    Set<String> dataSet = new Set<String>();
    Arc_Gen_TableContentPerAnalysis_Data dataList = new Arc_Gen_TableContentPerAnalysis_Data();
    for(arce__Table_Content_per_Analysis__c data: dataList.getRecordsYears(collectionType, recordId)) {
      dataSet.add(data.arce__table_content_year__c);
    }
    List<String> resultsList = new List<String>(dataSet);
    return resultsList;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description getCollection gets label value FROM a picklist.
  *--------------------------------------------------------------------------------
  * @author manuelhugo.castillo.contractor@bbva.com
  * @date   17/10/2019
  * @param collectionType type of collection.
  * @param  recordId Id of the record.
  * @return String valueLabelMap
  **/
  public String getCollection (String collectionType, String recordId) {
    Set<String> setStrCollection = new Set<String>();
    Arc_Gen_TableContentPerAnalysis_Data collectionsTable = new Arc_Gen_TableContentPerAnalysis_Data();
    for(arce__Table_Content_per_Analysis__c arceTCA : collectionsTable.getRecordsCollectionTable(collectionType, recordId)) {
      setStrCollection.add(arceTCA.arce__collection_table__c);
    }
    String collection = null;
    if(!setStrCollection.isEmpty()) {
      collection =new List<String>(setStrCollection)[0];
    }
    return collection;
  }
}