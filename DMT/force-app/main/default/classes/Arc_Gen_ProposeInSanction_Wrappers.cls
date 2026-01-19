/**
  * @File Name : Arc_Gen_ProposeInSanction_Wrappers.cls
  * @Description : Wrapper utility to Propose In Saction component
  * @Author : juanignacio.hita.contractor@bbva.com
  * @Group : ARCE - BBVA
  * @Last Modified By : juanignacio.hita.contractor@bbva.com
  * @Last Modified On : 07/11/2019 17:59
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 07/11/2019 ARCE TEAM Creation file
  **/
public with sharing class Arc_Gen_ProposeInSanction_Wrappers {

  /**
  * @Description : Wrapper Account Has Analysis Object
  * @Author : juanignacio.hita.contractor@bbva.com
  */
  public class WrapperAccHasAnalysis {
    /**
    *
    * @Description : String with a record Id
    */
    @AuraEnabled public String recordId {get;set;}
    /**
    *
    * @Description : boolean with main subsidiary information
    */
    @AuraEnabled public Boolean mainSubsidiary {get;set;}
    /**
    *
    * @Description : String with record Id of FS valid for rating
    */
    @AuraEnabled public String ffssRatingId {get;set;}
    /**
    *
    * @Description : String with final rating valuem
    */
    @AuraEnabled public String ffssRatingFinal {get;set;}
    /**
    *
    * @Description : String with customer Id
    */
    @AuraEnabled public String customerId {get;set;}
    /**
    *
    * @Description : String with Customer Name
    */
    @AuraEnabled public String customerName {get;set;}
  }

  /**
  * @Description : Wrapper general
  * @Author : juanignacio.hita.contractor@bbva.com
  */
  public class WrapperGeneral {
    /**
    *
    * @Description : Map of id and Account Has Analysis
    */
    @AuraEnabled public Map<String, WrapperAccHasAnalysis> mapAccHasAnalysis {get;set;}
    /**
    *
    * @Description : List of maps with picklist value - label
    */
    @AuraEnabled public List<Map<String, String>> mapComboBox {get;set;}
  }

}