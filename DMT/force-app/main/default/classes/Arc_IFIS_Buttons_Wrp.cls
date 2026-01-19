/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_Buttons_Wrp
* @Author         marcos.gimeno.next@bbva.com
* @Date           04-09-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Wrapper class for all button functionalities.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 04-09-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.ExcessivePublicCount')
public class Arc_IFIS_Buttons_Wrp {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Delegation wrapper.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     29-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    public class DelegationWrapper {
        /** @description Analysis id**/
        public Id analysisId { get; set; }
        /** @description Ambit current user**/
        public String ambit { get; set; }
        /** @description Ambit sanction**/
        public String sanctionAmbit { get; set; }
        /** @description Status of if the analysis has delegation. Values: YES,NO,NOTCALCULATED**/
        public String hasDelegation { get; set; }
        /** @description List of ambit**/
        public List<Map<String, String>> lstAmbits { get; set; }
        /** @description List of comittees**/
        public Integer codStatus { get; set; }
        /** @description Message info in the errors handling**/
        public String msgInfo { get; set; }
        /** @description List of users**/
        public List<Map<String, String>> lstUsers { get; set; }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This class represents a response object for validated operations.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    public class ValidateResponse {
        /** @description The data returned by the operation**/
        @AuraEnabled
        public Map<String, Object> data { get; set; }
        /** @description Whether the operation succeeded or not**/
        @AuraEnabled
        public Boolean success { get; set; }
        /** @description The message associated with the operation result**/
        @AuraEnabled
        public String message { get; set; }
        /**
        * -----------------------------------------------------------------------------------------------
        * @description Initializes a new instance of the ValidateResponse class.
        * -----------------------------------------------------------------------------------------------
        * @autor    marcos.gimeno.contractor@bbva.com
        * @date     25-05-2023
        * @param    data       The data returned by the operation.
        * @param    success    Whether the operation succeeded or not.
        * @param    message    The message associated with the operation result.
        * @return   New instance of the ValidateResponse class.
        * @example  createResponseObj(data, success, message)
        * -----------------------------------------------------------------------------------------------
        **/
        public ValidateResponse(Map<String, Object> data, Boolean success, String message) {
            this.data = data;
            this.success = success;
            this.message = message;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper to support wrapper deserialization.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     02-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    public class ValidationData {
        /** @description String storing arce__Account_has_Analysis__c Id**/
        public String ahaId { get; set; }
        /** @description String storing current User Id**/
        public String validatedById { get; set; }
        /** @description String storing arce__rating__c Id**/
        public String ratingId { get; set; }
        /** @description String storing validation ambit**/
        public String ambit { get; set; }
        /** @description String storing validation description**/
        public String description { get; set; }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service request.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    public class ServPersisenceParams {
        /** @description Event type name**/
        public String eventType { get; set; }
        /** @description Su event type name**/
        public String subEventType { get; set; }
        /** @description Business agent id**/
        public String businessAgentId { get; set; }
        /** @description Bank id**/
        public String bankId { get; set; }
        /** @description Branch id**/
        public String branchId { get; set; }
        /** @description Branch level**/
        public String branchLevel { get; set; }
        /** @description Participant id**/
        public String participantId { get; set; }
        /** @description Participant type**/
        public String participantType { get; set; }
        /** @description Evaluation date**/
        public String evaluationDate { get; set; }
        /** @description Risk assessment id**/
        public String riskAssessmentId { get; set; }
        /** @description Rating id**/
        public String ratingid { get; set; }
        /** @Description: Indicates the client type (IFIS).**/
        public String clientType { get; set; }
    }

    public class ButtonsException extends Exception {
    }
}