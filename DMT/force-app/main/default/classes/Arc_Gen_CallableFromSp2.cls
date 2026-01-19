/**
* @File Name          : Arc_Gen_CallableFromSp2.cls
* @Description        : callable class called from corporate classes
* @Author             : alberto.martinez.carrero.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 05-26-2025
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         04/06/2024    alberto.martinez.carrero.tech@bbva.com     Initial Version
**/
global with sharing class Arc_Gen_CallableFromSp2 implements Callable { 
    /**
    * @description Utilizes the callable interface to call another methods of actual class.
    * @author aleksandar.dinkov.contractor@bbva.com | 02-02-2024
    * @param String action
    * @param Map<String,Object> args
    * @return Object
    **/
    global Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'buildFFSS' {
                return callBuildFFSS(args);
            }
            when 'validateFSForRating' {
                return callValidateFSForRating(args);
            }
            when 'getFfssValidType' {
                return callGetFfssValidType(args);
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented!');
            }
        }
    }
    /**
    * @description ExtensionMalformedCallException
    **/
    global class ExtensionMalformedCallException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description get map info that will be used to call buildFFSS method.
    *--------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callBuildFFSS(Map<String, Object> mapInfo) {
        final String callFrom = (String) mapInfo.get('callFrom');
        switch on callFrom {
            when 'proposal' {
                final Map<String, Object> servResp = (Map<String, Object>) mapInfo.get('servResp');
                final Integer auditorOp = (Integer) mapInfo.get('auditorOp');
                return Arc_Gen_Balance_Tables_helper.buildFFSS(null, servResp, auditorOp, null, null, null);
            }
            when else {
                throw new ExtensionMalformedCallException('Error: invalid callFrom method');
            }
        }
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description callValidateFSForRating method call validateFSForRating method of Arc_Gen_Balance_Tables_helper class
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callValidateFSForRating(Map<String, Object> mapInfo) {
        final arce__Financial_Statements__c ffss = (arce__Financial_Statements__c) mapInfo.get('ffss');
        return Arc_Gen_Balance_Tables_helper.validateFSForRating(ffss);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description callGetFfssValidType method call getFfssValidType method of Arc_Gen_Balance_Tables_helper class
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callGetFfssValidType(Map<String, Object> mapInfo) {
        final Boolean ffssValidRating = (Boolean) mapInfo.get('ffssValidForRating');
        return Arc_Gen_Balance_Tables_helper.getFfssValidType(ffssValidRating);
    }
}