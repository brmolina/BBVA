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
public with sharing class PRC_PFS_Operation_Amortization {
    @AuraEnabled
    public  String amortizationType {get;set;}
    @AuraEnabled
    public  String paymentFrequency {get;set;}
    @AuraEnabled
    public  margin margin {get;set;}
    @AuraEnabled
    public  notional notional {get;set;}
    @AuraEnabled
    public  fee fee {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  List<installment> installments {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public PRC_PFS_Operation_Amortization() {
        this.amortizationType = '';
        this.paymentFrequency = '';
        this.margin = new margin(0,0);
        this.notional = new notional(0,0);
        this.fee = new fee(0,0);
        //this.installments = new List<installment>();
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public  class installment {
        @AuraEnabled
        public  Datetime paymentDate {get;set;}
        @AuraEnabled
        public  margin margin {get;set;}
        @AuraEnabled
        public  notional notional {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  fee fee {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  rating rating {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public  Decimal lossGivenDefault {get;set;}
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
        public installment() {}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param paymentDate
        * @param margin
        * @param notional
        * @param fee
        * @param rating
        * @param lossGivenDefault
        * @param financingType
        **/
        public installment(Datetime paymentDate, margin margin, notional notional, fee fee, rating rating, Decimal lossGivenDefault, String financingType) {
            this.paymentDate = paymentDate;
            this.margin = margin;
            this.notional = notional;
            this.fee = fee;
            this.rating = rating;
            this.lossGivenDefault = lossGivenDefault;
            this.financingType = financingType;
        }
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public  class margin {
        @AuraEnabled
        public  Decimal onBalance {get;set;}
        @AuraEnabled
        public  Decimal offBalance {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public margin() {
            this.onBalance = 0;
            this.offBalance = 0;
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param onBalance
        * @param offBalance
        **/
        public margin(Decimal onBalance,Decimal offBalance) {
            this.onBalance = onBalance;
            this.offBalance = offBalance;
        }
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public  class fee {
        /* @AuraEnabled
        public  String id {get;set;}
        @AuraEnabled
        public  Decimal value {get;set;} Obsoleto en V3.0 se añaden lso campos ACCRUAL y NON_ACCRUAL*/
        @AuraEnabled
        public  Decimal accrual {get;set;}
        @AuraEnabled
        public  Decimal nonAccrual {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public fee() {}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
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
    * @author Global Desktop | 03-05-2021
    **/
    public  class notional {
        @AuraEnabled
        public  Decimal onBalance {get;set;}
        @AuraEnabled
        public  Decimal offBalance {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public notional() {
            this.onBalance = 0;
            this.offBalance = 0;
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param onBalance
        * @param offBalance
        **/
        public notional(Decimal onBalance,Decimal offBalance) {
            this.onBalance = onBalance;
            this.offBalance = offBalance;
        }
    }
     /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    public class rating {
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        @AuraEnabled
        public String longScaleValue {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public rating() {
            this.longScaleValue = '';
        }
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        * @param longScaleValue
        **/
        public rating(String longScaleValue) {
            this.longScaleValue = longScaleValue;
        }
    }
}