/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 03-08-2021
 * @last modified by  : Global Desktop
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   03-05-2021   Global Desktop   Initial Version
**/
public with sharing class PRC_PFS_Operation {
     /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
    @AuraEnabled
    public  String id {get;set;}
     /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
    @AuraEnabled
    public  Boolean isFundingCalculatedByTerm {get;set;}
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Boolean isCommited {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public Boolean IsRegulationCapitalRequired  {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Datetime startDate {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Datetime maturityDate {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String paymentType {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String productModality {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String booking {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String financingType {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String currenc_y {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String countryRisk {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal order {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal underlyingOperationsNumber {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal taxRate {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal costToIncome {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal userLossGivenDefault {get;set;}

    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
	@AuraEnabled
    public businessArea businessArea {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  PRC_PFS_Operation_Amortization amortization {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  PRC_PFS_Operation_Funding funding {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  List<PRC_PFS_Operation_Mitigant> mitigants {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public Decimal operationalRiskPercentage {get;set;}

    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public PRC_PFS_Operation() {

    }
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @param mock
    **/
    public PRC_PFS_Operation(Boolean mock) {
        this.isFundingCalculatedByTerm = false;
        this.isCommited = false;
        this.IsRegulationCapitalRequired = false;

        this.startDate = Datetime.now();
        this.maturityDate = Datetime.now();

        this.paymentType = '';
        this.productModality = '';
        this.booking = '';
        this.financingType = '';
        this.currenc_y = '';
        this.countryRisk = '';

        this.order = 0;
        this.underlyingOperationsNumber = 0;

        this.taxRate = 0;
        this.costToIncome = 0;
        //this.userLossGivenDefault = 0;

        //this.maximumBalance = new maximumbalance();
        this.businessArea = new businessArea('GLOBAL_TRANSACTION_BANKING','');

        this.amortization = new PRC_PFS_Operation_Amortization();
        this.funding = new PRC_PFS_Operation_Funding();
        this.mitigants = new List<PRC_PFS_Operation_Mitigant>{ new PRC_PFS_Operation_Mitigant()};

        this.rating = new operationrating('shortScaleValue', 'longScaleValue');
        this.ratingModalityType = 'GROUP';
        //this.fees = new List<operationfee>{}; Obsoleto en V3.0
        this.productType = new operationProductType('id');

        this.operationalRiskPercentage = 0;
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public  class operationrating {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  String shortScaleValue {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  String longScaleValue {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public operationrating() {}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param shortScaleValue
        * @param longScaleValue
        **/
        public operationrating(String shortScaleValue, String longScaleValue) {
            this.shortScaleValue = shortScaleValue;
            this.longScaleValue = longScaleValue;
        }
    }
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  operationrating rating {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String ratingModalityType {get;set;}
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public  class operationProductType {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  String id {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public operationProductType() {}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param id
        **/
        public operationProductType(String id) {
            this.id = id;
        }
    }
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  operationProductType productType {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public class maximumbalance {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public Decimal amount {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public String currenc_y {get;set;}
    }
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  maximumbalance maximumBalance {get;set;}
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public class businessArea {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public String id {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public product product {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public businessArea() {
            this.id = '';
            this.product = new PRC_PFS_Operation.product();
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param Id
        * @param productId
        **/
        public businessArea(String Id, String productId) {
            this.id = Id;
            if (productId != null) {
                this.product = new PRC_PFS_Operation.product(productId);
            }
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param Id
        **/
        public businessArea(String Id) {
            this.id = Id;
        }
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public class product {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public string id {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public product() {
            this.id = '';
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param Id
        **/
        public product(String Id) {
            this.id = Id;
        }
    }
}