/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 03-08-2021
 * @last modified by  : Global Desktop
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   03-08-2021   Global Desktop   Initial Version
**/
public with sharing class PRC_PFS_Response {
    @AuraEnabled
    public String wsErrorMsg {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public data data {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public PRC_PFS_Response() {

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class data {
		@AuraEnabled
        public String id {get;set;}
		@AuraEnabled
        public responsebody engineWorksWith {get;set;}
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class responsebody {
		/**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String engineWorksWithType {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String investmentBankingProposalId {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String webPricingcode {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public Boolean hasCalculationMatched {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String id {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public Datetime valueDate {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public PRC_PFS_Scenario scenario {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public List<PRC_PFS_Scenario> scenarios {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public status status {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public List<PRC_PFS_Matrix> matrices {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public List<crossSellAmount> crossSellAmounts {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public PRC_PFS_Participant participant {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public List<PRC_PFS_Operation> operations {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public originationBranch originationBranch {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String currenc_y {get;set;}
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class status {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String id {get;set;}
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class crossSellAmount {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String id {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public Decimal amount {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
		@AuraEnabled
        public String currenc_y {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public crossSellAmount() {
            this.id = 'x';
            this.amount = 0;
            this.currenc_y = 'EUR';
        }
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class originationBranch {
         /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String id {get;set;}
        public originationBranch(){}
    }
}