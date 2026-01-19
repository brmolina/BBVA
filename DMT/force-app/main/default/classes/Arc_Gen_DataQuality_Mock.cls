/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_DataQuality_Mock
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 27/05/2024
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_DataQuality_Mock
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |27-05-2024 aleksandar.dinkov.contractor@bbva.com
*             Class creation.
* ----------------------------------------------------------------------------------------------- 
*/
@SuppressWarnings('sf:PreserveStackTrace,sf:AvoidHardCodedError,sf:ShortVariable,sf:UnusedPrivateField,sf:LongVariable,sf:DUDataflowAnomalyAnalysis,sf:OnlyOneReturn')
public with sharing class Arc_Gen_DataQuality_Mock implements Callable {
    /**
    * @description String "OK" value.
    */
    public static final String DUMMY_RESPONSE = '{"message":"OK","status":"Success"}';

    /**
    * Constructor
    **/
    @TestVisible
    public Arc_Gen_DataQuality_Mock() {}

    /**
    * @description Utilizes the callable interface to call another methods of actual class.
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String action
    * @param Map<String,Object> args
    * @return Object
    **/
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'executeDataQuality' {
                return this.executeDataQuality((String)args.get('ahaId'));
            }
            when 'refreshParentRating' {
                return this.refreshParentRating((String)args.get('ahaId'));
            }
            when 'arpFlowValidation' {
                return this.arpFlowValidation((String)args.get('ahaId'));
            }
            when 'eeffAuditedValidation' {
                return this.eeffAuditedValidation((String)args.get('ahaId'));
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented!');
            }
        }
    }

    /**
    * @description ExtensionMalformedCallException
    **/
    public class ExtensionMalformedCallException extends Exception {}

    /**
    * @description Execute Data Quality validations
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return String JSON Map<String,String>: Contains status and message params
    **/
    public String executeDataQuality(String ahaId) {
        return DUMMY_RESPONSE;
    }

    /**
    * @description Refresh Parent Rating data
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return String JSON Map<String,String>: Contains status and message params
    **/
    public String refreshParentRating(String ahaId) {
        return DUMMY_RESPONSE;
    }

    /**
    * @description Execute Data Quality validations ARP
    * @author david.montero.bellon.contractor@bbva.com  | 12-01-2025
    * @param String ahaId
    * @return String JSON Map<String,String>: Contains status and message params
    **/
    public String arpFlowValidation(String ahaId) {
        return DUMMY_RESPONSE;
    }


    /**
    * @description Execute Data Quality EEFF validations
    * @author david.montero.bellon.contractor@bbva.com  | 2025-02-18
    * @param String ahaId
    * @return String JSON Map<String,String>: Contains status and message params
    **/
    public String eeffAuditedValidation(String ahaId) {
        return DUMMY_RESPONSE;
    }
      
}