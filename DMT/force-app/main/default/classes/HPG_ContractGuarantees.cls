/**-------------------------------------------------------------------------------------------
* @Name     HPG ContractGuarantees
* @Author   Cosme Alcázar <cosme.alcazar.tech@bbva.com>
* @Date     Created: 2024-08-02
* --------------------------------------------------------------------------------------------
* @Description Wrapper Class for request contract-guarantees service
* --------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class HPG_ContractGuarantees {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getContractGuarantees(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('HPG_GetContractGuarantees', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                res = (Wrapper)System.JSON.deserialize(response.getBody(), Wrapper.class);
                res.success = true;
            }
            when else {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        return res;
    }

    /**
    * @Description: Class Wrapper
    */
    public class Wrapper {

        /* @Description: data */
        @AuraEnabled
        public List<Data> data {get;set;}

        /* @Description: pagination */
        @AuraEnabled
        public Pagination pagination {get;set;}

        /* @Description: success */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: errorMessage */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    /**
    * @Description: Class Data
    */
    public class Data {

        /* @Description: Identifier that applied by the reporting agent to uniquely identify each protection used to secure the instrument. Each protection must have one protection identifier. This value will not change over time and cannot be used as the protection identifier for any other guarantee. */
        @AuraEnabled
        public String guaranteeId {get;set;}

        /* @Description: Single global model code that identifies univocally contract globally. */
        @AuraEnabled
        public String contractId {get;set;}

        /* @Description: Local identifier code of the contract number. To protect data belonging to other customers, this information will be partially hidden. */
        @AuraEnabled
        public String localContractNumberId {get;set;}

        /* @Description: Description of the internal contract code. */
        @AuraEnabled
        public String internalContractCodeDesc {get;set;}

        /* @Description: String based on ISO-8601 for specifying the registration update date. */
        @AuraEnabled
        public Date cutoffDate {get;set;}

        /* @Description: String based on ISO-8601 for specifying the date from which the guarantee applies must be reported. */
        @AuraEnabled
        public Date beginningGuaranteeDate {get;set;}

        /* @Description: String based on ISO-8601 for specifying the date until which the guarantee applies must be reported, that is, the end date of the guarantee. */
        @AuraEnabled
        public Date endGuaranteeDate {get;set;}

        /* @Description: Mark used to identify the grouping of guarantees based on common characteristics. */
        @AuraEnabled
        public String guaranteeType {get;set;}

        /* @Description: Description of the type guarantee. */
        @AuraEnabled
        public String guaranteeTypeDesc {get;set;}

        /* @Description: Type of collateral associated to tot the trade. */
        @AuraEnabled
        public String tradeCollateralType {get;set;}

        /* @Description: Description of the type of collateral of guarantee associated to the trade. */
        @AuraEnabled
        public String tradeGuarranteeCollateralTypeDesc {get;set;}

        /* @Description: Identifier of the guarantor customer. */
        @AuraEnabled
        public String guarantorCustomerId {get;set;}

        /* @Description: Description of the guarantor customers's name. */
        @AuraEnabled
        public String guarantorCustomerNameDesc {get;set;}

        /* @Description: Amount of the guarantor. */
        @AuraEnabled
        public Decimal guarantorAmount {get;set;}

        /* @Description: Amount of the guarantee guaranteed by the contract on the date the information is sent. */
        @AuraEnabled
        public Decimal currentGuaranteedAmount {get;set;}

        /* @Description: Identifier of global model that classifies the currency corresponding to the amount of preferential collection rights of third parties against guarantee based on the international standard ISO 4217. */
        @AuraEnabled
        public String guaranteeCurrencyId {get;set;}

        /* @Description: Identifier of the guarantor currency. */
        @AuraEnabled
        public String guarantorCurrencyId {get;set;}

        /* @Description: Percentage of mitigation of guarantor. */
        @AuraEnabled
        public Decimal guarantorMitigationPer {get;set;}

        /* @Description: String based on ISO-8601 for specifying the moment that occurred last appraisal. The value appraisals varies with time depending on certain factors such as the market price of similar goods, the evolution of the state of good etc. To have an updated value is important that the pricing date is as close as possible to the present moment. */
        @AuraEnabled
        public Date lastAppraisalDate {get;set;}

        /* @Description: Codification that allows the univocal identification of the asset, whether real property, movable property or right valued in money or susceptible to be valued. */
        @AuraEnabled
        public String assetId {get;set;}

        /* @Description: String based on ISO-8601 for specifying the date in the event that the guarantee is made with debt securities or fixed income securities, the expiration date of the securities guaranteeing the transaction must be reported. */
        @AuraEnabled
        public Date expirationSecuritiesDate {get;set;}

        /* @Description: In the event that the guarantee is covered by a professional guarantor, the percentage of the unpaid balance that the insurer will cover should be reported once the loss for a contract has been declared. */
        @AuraEnabled
        public Decimal insuranceCoverPer {get;set;}

        /* @Description: Identifier of the current year of the guarantee. */
        @AuraEnabled
        public String guaranteeCurrentYearId {get;set;}

        /* @Description: Name of the type of record */
        @AuraEnabled
        public String recordTypeName {get;set;}
    }

    /**
    * @Description: Class Pagination
    */
    public class Pagination {

        /* @Description: links */
        @AuraEnabled
        public Links links {get;set;}

        /* @Description: page */
        @AuraEnabled
        public Integer page {get;set;}

        /* @Description: pageSize */
        @AuraEnabled
        public Integer pageSize {get;set;}

        /* @Description: totalElements */
        @AuraEnabled
        public Integer totalElements {get;set;}

        /* @Description: totalPages */
        @AuraEnabled
        public Integer totalPages {get;set;}
    }

    /**
    * @Description: Class Links
    */
    public class Links {

        /* @Description: first */
        @AuraEnabled
        public String first {get;set;}

        /* @Description: last */
        @AuraEnabled
        public String last {get;set;}

        /* @Description: previous */
        @AuraEnabled
        public String previous {get;set;}

        /* @Description: next */
        @AuraEnabled
        public String next {get;set;}
    }
}