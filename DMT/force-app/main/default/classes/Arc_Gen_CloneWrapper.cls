/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_CloneWrapper
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-08-04
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Wrapper to save all the related records of an ARCE
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-08-04 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-10-13 eduardoefrain.hernandez.contractor@bbva.com
  *             Add lsRatios
  * |2021-16-02 mariohumberto.ramirez.contractor@bbva.com
  *               Added new param 'evolProducts'
  * |2021-03-24 eduardoefrain.hernandez.contractor@bbva.com
  *             Add lsAutoRetTable & lsAutoRetByYear
  * |2021-05-21 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add lsMainContApp, lsDatePeriod, lsHotelCategory, lsHotelProjection
  * |2021-12-22 francisco.munoz.torres.contractor@bbva.com
  *             Add lsFFSS
  **/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyFields')
public class Arc_Gen_CloneWrapper {
    /**
        * @Description: lsarc
        */
        public List<arce__Analysis__c> lsarc {get;set;}
        /**
        * @Description: lsaha
        */
        public List<arce__Account_has_Analysis__c> lsaha {get;set;}
        /**
        * @Description: lsahaDefault
        */
        public List<arce__Account_has_Analysis__c> lsahaDefault {get;set;}
        /**
        * @Description: lsThirdPerson
        */
        public List<arce__Third_Participant_Details__c> lsThirdPerson {get;set;}
        /**
        * @Description: lsGeo
        */
        public List<arce__Table_Content_per_Analysis__c> lsGeo {get;set;}
        /**
        * @Description: lsRatios
        */
        public List<arce__Table_Content_per_Analysis__c> lsRatios {get;set;}
        /**
        * @Description: lsMainBanks
        */
        public List<arce__main_banks__c> lsMainBanks {get;set;}
        /**
        * @Description: Limits exposure object to copy from previous Analysis
        */
        public List<arce__limits_exposures__c> lsLimExp {get;set;}
        /**
        * @Description: Limits exposure object to copy from previous Analysis
        */
        public String ffssForRatingId {get;set;}
        /**
        * @Description: arce__evol_main_prod_agro__c to copy from previous Analysis
        */
        public List<arce__evol_main_prod_agro__c> evolProducts {get;set;}
        /**
        * @Description: List of dealerships Records of autoretail
        */
        public List<arce__autoretail_behavior_table__c> lsAutoRetTable {get;set;}
        /**
        * @Description: List of dealerships Records of autoretail by year
        */
        public List<arce__autoretail_behavior_by_year__c> lsAutoRetByYear {get;set;}
        /**
        * @Description: lsMainContApp
        */
        public List<arce__contracts_and_appraisals__c> lsMainContApp {get;set;}
        /**
        * @Description: lsDatePeriod
        */
        public List<arce__hotel_analysis_date_period__c> lsDatePeriod {get;set;}
        /**
        * @Description: lsHotelCategory
        */
        public List<arce__hotel_analysis_category__c> lsHotelCategory {get;set;}
        /**
        * @Description: lsHotelProjection
        */
        public List<arce__hotel_projection__c> lsHotelProjection {get;set;}
        /**
        * @Description: lsFFSS
        */
        public List<arce__Financial_Statements__c> lsFFSS {get;set;}
}