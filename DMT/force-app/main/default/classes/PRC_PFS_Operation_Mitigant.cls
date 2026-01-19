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
@SuppressWarnings('sf:LongVariable,sf:CommentRequired,sf:FinalFieldCouldBeStatic,sf:ShortVariable')
public with sharing class PRC_PFS_Operation_Mitigant {
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
    public  String mitigantType {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal commercialRisk {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Decimal countryRisk {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  String maturityType {get;set;}
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
    public  Boolean isCountryRiskCoverage {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Boolean belongsSameGroup {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-05-2021
    **/
    @AuraEnabled
    public  Boolean isInLocalCurrency {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public  guarantor guarantor {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public  String description {get;set;}
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    @AuraEnabled
    public  Boolean isEuropeanExportCreditAgency {get;set;}

    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public PRC_PFS_Operation_Mitigant() {

    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public  class guarantor {
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
        public  rating rating {get;set;}
        /**
        * @description
        * @author Global Desktop | 03-05-2021
        **/
        public guarantor(String id, rating rating) {
            this.id = id;
            this.rating = rating;
        }

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public guarantor() {
            this.id = '';
            this.rating = new rating();
        }
    }
    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public  class rating {
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
        * @author Global Desktop | 03-08-2021
        * @param shortScaleValue
        * @param longScaleValue
        **/
        public rating(String shortScaleValue, String longScaleValue) {
            this.shortScaleValue = shortScaleValue;
            this.longScaleValue = longScaleValue;
        }

        /**
        * @description
        * @author Global Desktop | 03-08-2021
        **/
        public rating() {
            this.shortScaleValue = '';
            this.longScaleValue = '';
        }
    }

}