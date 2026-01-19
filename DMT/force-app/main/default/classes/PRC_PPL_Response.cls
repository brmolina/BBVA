/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 04-08-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   03-08-2021   Global Desktop   Initial Version
**/
public class PRC_PPL_Response {
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public String wsErrorMsg {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public String body {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public integer status {get;set;}

}