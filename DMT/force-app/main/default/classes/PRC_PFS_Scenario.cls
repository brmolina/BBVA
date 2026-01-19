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
@SuppressWarnings('sf:VariableNamingConventions,sf:LongVariable,sf:VariableDeclarationHidesAnother,sf:ShortVariable')
public with sharing class PRC_PFS_Scenario {
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
    public Decimal averageLossGivenDefault {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal averageProbabilityOfDefault {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal averageFunding {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal duration {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal regulatoryDurationInYears {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal averageLifeInYears {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal averageDaysInYears {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal taxRate {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<exposuresAtDefault> exposuresAtDefault {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<axis> axis {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public allIn allIn {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public term term {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal maxBalance {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public String equivalentRating {get;set;}

    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public fundingCostInCash fundingCostInCash {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public regulatoryFundingDuration regulatoryFundingDuration {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<result> results {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<fund> funds {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<income> incomes {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<profitabilityMetric> profitabilityMetrics {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<creditRisk> creditRisks {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<sensitivity> sensitivities {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<operation> operations {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public costToIncome costToIncome {get;set;}

    //Campos de Operation
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal currencyFactor {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal regulatoryExpectedLoss {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal netFundingCostInCash {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public Decimal fundingDuration {get;set;}
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<riskWeightedAssests> riskWeightedAssests {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public maximumBalance maximumBalance {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public netProfit netProfit {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public List<operationalRisks> operationalRisks {get;set;}


    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public PRC_PFS_Scenario() {
        this.id = '';
        this.averageLossGivenDefault = 0;
        this.averageProbabilityOfDefault = 0;
        this.averageFunding = 0;
        this.duration = 0;
        this.regulatoryDurationInYears = 0;
        this.averageLifeInYears = 0;
        this.averageDaysInYears = 0;
        this.taxRate = 0;
        this.maxBalance = 0;
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class maximumBalance {
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

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class netProfit {
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

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class operationalRisks {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public List<amounts> amounts {get;set;}

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class amounts {
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

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class axis {
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
        public Decimal value {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public axis() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class exposuresAtDefault {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String model {get;set;}
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
        @AuraEnabled
        public Decimal amount {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public exposuresAtDefault() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class allIn {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal onBalance {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal offBalance {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public allIn() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class term {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal value {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String unit {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public term() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class fundingCostInCash {
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
        public fundingCostInCash() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class regulatoryFundingDuration {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal value {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String unit {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public regulatoryFundingDuration() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class result {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public String resultType {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal year {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal offerRate {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal timeGap {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal taxes {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal operationalRisk {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public List<amount> amounts {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public interest interest {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public List<exchangerate> name {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public List<riskWeightedAssests> riskWeightedAssests {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public result() {

        }
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class riskWeightedAssests {
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
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class amount {
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
        public amount() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class interest {
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
        public interest() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class exchangerate {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal ratio {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public exchangerate() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class fund {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal onBalance {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal offBalance {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public fund() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class income {
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
        public income() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class profitabilityMetric {
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
        public Decimal deal {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal dealFirstTwelveMonths {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal total {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal totalFirstTwelveMonths {get;set;}

    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class creditRisk {
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
        public List<amount> amounts {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public creditRisk() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class sensitivity {
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
        public fixedsum fixedSum {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public margin margin {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public sensitivity() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class fixedsum {
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
        public fixedsum() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class margin {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal onBalance {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal offBalance {get;set;}

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public margin() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public  class fee {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal accrual {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public Decimal nonAccrual {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public fee() {}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        * @param accrual
        * @param nonAccrual
        **/
        public fee(Decimal accrual, Decimal nonAccrual) {
            this.accrual = accrual;
            this.nonAccrual = nonAccrual;
        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class operation {
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public margin margin {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        @AuraEnabled
        public fee fee {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public operation() {

        }
    }
        /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public class costToIncome {
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
        public costToIncome() {

        }
    }

}