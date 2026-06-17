/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_Testing_Util
* @Author   BBVA Developers
* @Date     Created: 2020-06-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description this class is the controller for the table.
* ------------------------------------------------------------------------------------------------
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList,sf:TooManyMethods,PMD.ExcessivePublicCount,PMD.CyclomaticComplexity,sf:CouplingBetweenObjects,PMD.ApexCRUDViolation,PMD.ExcessiveClassLength,PMD.UseObjectForClearerAPI,PMD.CognitiveComplexity')
public with sharing class GDT_Testing_Util {
    /**
    *-------------------------------------------------------------------------------
    * @description Literal 'AAA'
    *-------------------------------------------------------------------------------
    **/
    final static String AAA_LIT = 'AAA';
    /**
    *-------------------------------------------------------------------------------
    * @description Literal 'EUR'
    *-------------------------------------------------------------------------------
    **/
    final static String EUR_LIT = 'EUR';
    /**
    *-------------------------------------------------------------------------------
    * @description Literal 'ahaId'
    *-------------------------------------------------------------------------------
    **/
    final static String AHA_ID_LIT = 'ahaId';
    /**
    *-------------------------------------------------------------------------------
    * @description Literal 'arceId'
    *-------------------------------------------------------------------------------
    **/
    final static String ARCE_ID_LIT = 'arceId';
    /**
    *-------------------------------------------------------------------------------
    * @description SRVWRAPPER
    *-------------------------------------------------------------------------------
    **/
    final static String SRVWRAPPER = '{"proposalWrap":{"status":{"id":"1"},"participants":[{"ratings":[{"ratingId":"1100021344","financialStatement":{"financialStatementType":{"id":"CONSOLIDATED"},"financialStatementId":"0000000000000000488473"}}],"proposalFolderId":"PF00000092","id":"ES0182009687897","entityType":{"id":"PARENT_GROUP"}}],"parentParticipant":{"proposalId":"PR00000102","id":"G00000000000000"},"financialStatement":{"financialStatementType":{"id":"CONSOLIDATED"},"financialStatementId":null},"eventType":{"id":"NEW"},"businessAgent":{"id":"XE79175"}},"messageErrorList":[]}';
    /**
    *-------------------------------------------------------------------------------
    * @description SRVWRAPPER
    *-------------------------------------------------------------------------------
    **/
    final static String SRVWRAPPER_REN = '{"proposalWrap":{"status":{"id":"1"},"participants":[{"ratings":[{"ratingId":"1100021344","financialStatement":{"financialStatementType":{"id":"CONSOLIDATED"},"financialStatementId":"0000000000000000488473"}}],"proposalFolderId":"PF00000093","id":"ES0182009687897","entityType":{"id":"PARENT_GROUP"}}],"parentParticipant":{"proposalId":"PR00000103","id":"G00000000000000"},"financialStatement":{"financialStatementType":{"id":"CONSOLIDATED"},"financialStatementId":null},"eventType":{"id":"NEW"},"businessAgent":{"id":"XE79175"}},"messageErrorList":[]}';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor to avoid SonarQube warning. dd
    *-------------------------------------------------------------------------------
    **/

    public static arce__Analysis__c createAnalisis() {
        arce__Analysis__c analisis = new arce__Analysis__c();
        return analisis;
    }

    public static arce__Account_has_Analysis__c createAccountHasAnalisis(String idAnalisis) {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        aha.arce__Analysis__c = idAnalisis;
        return aha;
    }





}