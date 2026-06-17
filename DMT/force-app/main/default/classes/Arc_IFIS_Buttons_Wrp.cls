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
global class Arc_IFIS_Buttons_Wrp {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Delegation wrapper.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     29-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    global class DelegationWrapper {
        /** @description Analysis id**/
        global Id analysisId { get; set; }
        /** @description Ambit current user**/
        global String ambit { get; set; }
        /** @description Ambit sanction**/
        global String sanctionAmbit { get; set; }
        /** @description Status of if the analysis has delegation. Values: YES,NO,NOTCALCULATED**/
        global String hasDelegation { get; set; }
        /** @description List of ambit**/
        global List<Map<String, String>> lstAmbits { get; set; }
        /** @description List of comittees**/
        global Integer codStatus { get; set; }
        /** @description Message info in the errors handling**/
        global String msgInfo { get; set; }
        /** @description List of users**/
        global List<Map<String, String>> lstUsers { get; set; }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This class represents a response object for validated operations.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    global class ValidateResponse {
        /** @description The data returned by the operation**/
        @AuraEnabled
        global Map<String, Object> data { get; set; }
        /** @description Whether the operation succeeded or not**/
        @AuraEnabled
        global Boolean success { get; set; }
        /** @description The message associated with the operation result**/
        @AuraEnabled
        global String message { get; set; }
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
        global ValidateResponse(Map<String, Object> data, Boolean success, String message) {
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
    global class ValidationData {
        /** @description String storing arce__Account_has_Analysis__c Id**/
        global String ahaId { get; set; }
        /** @description String storing current User Id**/
        global String validatedById { get; set; }
        /** @description String storing arce__rating__c Id**/
        global String ratingId { get; set; }
        /** @description String storing validation ambit**/
        global String ambit { get; set; }
        /** @description String storing validation description**/
        global String description { get; set; }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service request.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    global class ServPersisenceParams {
        /** @description Event type name**/
        global String eventType { get; set; }
        /** @description Su event type name**/
        global String subEventType { get; set; }
        /** @description Business agent id**/
        global String businessAgentId { get; set; }
        /** @description Bank id**/
        global String bankId { get; set; }
        /** @description Branch id**/
        global String branchId { get; set; }
        /** @description Branch level**/
        global String branchLevel { get; set; }
        /** @description Participant id**/
        global String participantId { get; set; }
        /** @description Participant type**/
        global String participantType { get; set; }
        /** @description Evaluation date**/
        global String evaluationDate { get; set; }
        /** @description Risk assessment id**/
        global String riskAssessmentId { get; set; }
        /** @description Rating id**/
        global String ratingid { get; set; }
        /** @Description: Indicates the client type (IFIS).**/
        global String clientType { get; set; }
    }

    global class ButtonsException extends Exception {
    }
}