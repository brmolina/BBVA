/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RetrievePS_Service_Mock
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 01/08/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_RetrievePS_Service_Mock
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |01-08-2023 aleksandar.dinkov.contractor@bbva.com
*             Class creation.
* |31-10-2023 aleksandar.dinkov.contractor@bbva.com
*             Removed arce__Arc_Gen_Parent_Relationship__c field hardcoded setting.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:PreserveStackTrace,sf:AvoidHardCodedError,sf:ShortVariable,sf:UnusedPrivateField,sf:LongVariable,sf:DUDataflowAnomalyAnalysis')
public with sharing class Arc_Gen_RetrievePS_Service_Mock implements Callable {
    /**
    * @description String "OK" value.
    */
    public static final String VALUE_OK = 'OK';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_SUCCESS = 'Success';
    /**
    * @Class: MessageResponse
    * @Description: Container that contains the message for the Lightning component as a response
    * @author BBVA
    */
    public class MessageResponse {
        /**
        * @Description: Indicates status
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Indicates message
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @description MessageResponse constructor
        * @author aleksandar.dinkov.contractor@bbva.com | 01-08-2023
        **/
        public MessageResponse() {
            status = VALUE_SUCCESS;
            message = VALUE_OK;
        }
    }

    /**
    * @description Utilizes the callable interface to call another methods of actual class.
    * @author aleksandar.dinkov.contractor@bbva.com | 02-02-2024
    * @param String action
    * @param Map<String,Object> args
    * @return Object
    **/
    public Object call(String action, Map<String, Object> args) {
        Object result;
        switch on action {
            when 'callParentSubsidiary' {
                result = this.callParentSubsidiaryMock((String)args.get('ahaId'));
            }
            when 'checkSuccess' {
                result = this.checkSuccessMock((String)args.get('ahaId'));
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented!');
            }
        }
        return result;
    }

    /**
    * @description ExtensionMalformedCallException
    **/
    public class ExtensionMalformedCallException extends Exception {}

    /**
    * @description retrieves Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 01-08-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    public MessageResponse callParentSubsidiaryMock(String ahaId) {
        return new MessageResponse();
    }

    /**
    * @description retrieves Parent Subsidiary status from ahaExtension object.
    * @author aleksandar.dinkov.contractor@bbva.com | 09-08-2023
    * @param String ahaId
    * @return Boolean
    **/
    public Boolean checkSuccessMock(String ahaId) {
        return true;
    }
}