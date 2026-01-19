/**
* ____________________________________________________________________________
* Acquirer Activity Wrapper
* Wrapper class for the ASO service "acquirer-activity"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-08-22
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_AcquirerActivity_Wrapper {
    /*
    * @Description: Billing information
    */
    @AuraEnabled
    global Billing billing {get; set;}
    /*
    * @Description: Name that allows the Group to be unequivocally identified
    */
    @AuraEnabled
    global String businessGroupName {get; set;}
    /*
    * @Description: Official identifying name of the Company of those legal entities that are clients of the Entity
    */
    @AuraEnabled
    global String companyName {get; set;}
    /*
    * @Description: Information about the customer's devices
    */
    @AuraEnabled
    global DevicesInfo devicesInfo {get; set;}
    /*
    * @Description: Discount information
    */
    @AuraEnabled
    global Discount discount {get; set;}
    /*
    * @Description: e-commerce brand
    */
    @AuraEnabled
    global String ecommerce {get; set;}
    /*
    * @Description: e-commerce brand converted to checkbox
    */
    @AuraEnabled
    global Boolean ecommerceCheckbox {get; set;}
    /*
    * @Description: Information on expenses
    */
    @AuraEnabled
    global Expenses expenses {get; set;}
    /*
    * @Description: Description of the family to which the acquiring customer belongs, refers to a grouping of business lines that are governed by the customer's economic activity and are defined according to the business lines classified by the regulatory entity for these services, which is BANXICO
    */
    @AuraEnabled
    global String familyAcquirer {get; set;}
    /*
    * @Description: 'Gran Superficie' family
    */
    @AuraEnabled
    global Boolean isGS {get; set;}
    /*
    * @Description: Commission information
    */
    @AuraEnabled
    global Fees fees {get; set;}
    /*
    * @Description: Month and year of information.
    */
    @AuraEnabled
    global String infoDate {get; set;}
    /*
    * @Description: Month name
    */
    @AuraEnabled
    global String monthName {get; set;}
    /*
    * @Description: Year
    */
    @AuraEnabled
    global Integer year {get; set;}
    /*
    * @Description: Mix Percentage Information
    */
    @AuraEnabled
    global PercentageContainer percentage {get; set;}
    /*
    * @Description: Electronic device used in a debit, credit or smart card transaction
    */
    @AuraEnabled
    global PinPadsInfo pinPadsInfo {get; set;}
    /*
    * @Description: Name of the result of the last rates agreed by the client
    */
    @AuraEnabled
    global String ratesResult {get; set;}
    /*
    * @Description: Icon used for ratesResult field
    */
    @AuraEnabled
    global String ratesResultIcon {get; set;}
    /*
    * @Description: Amount of Profit Before Tax (BAI/EBT) of the customer in the acquirer
    */
    @AuraEnabled
    global AmountCurrency taxAcquirer {get; set;}
    /*
    * @Description: Terminal where the customer performed the operation
    */
    @AuraEnabled
    global Terminal terminal {get; set;}
    /*
    * @Description: Billing information
    */
    @AuraEnabled
    global Tickets tickets {get; set;}
    /*
    * @Description: Transaction information
    */
    @AuraEnabled
    global Transaction_y transaction_y {get; set;}
    /*
    * @Description: Percentage of customer profitability
    */
    @AuraEnabled
    global String yield {get; set;}
    /*
    * @Description: Basis Points
    */
    @AuraEnabled
    global String basisPoints {get; set;}
    /*
    * @Description: Billing information
    */
    global class Billing {
        /*
        * @Description: Debit billing information
        */
        @AuraEnabled
        global OwnThirdPartyContainer debit {get; set;}
        /*
        * @Description: Flag indicating whether the debit discount is shown as a rate or as an installment
        */
        @AuraEnabled
        global OwnThirdPartyContainer credit {get; set;}
        /*
        * @Description: Flag indicating whether the debit discount is shown as a rate or as an installment
        */
        @AuraEnabled
        global AmountCurrency international {get; set;}
        /*
        * @Description: Flag indicating whether the debit discount is shown as a rate or as an installment
        */
        @AuraEnabled
        global AmountCurrency totalAmount {get; set;}
    }
    /*
    * @Description: own  + thirdParty container
    */
    global class OwnThirdPartyContainer {
        /*
        * @Description: own  + thirdParty fields
        */
        @AuraEnabled
        global AmountCurrency own {get; set;}
        /*
        * @Description: own  + thirdParty fields
        */
        @AuraEnabled
        global AmountCurrency thirdParty {get; set;}
    }
    /*
    * @Description: Discount information
    */
    global class Discount {
        /*
        * @Description: Flag indicating whether the debit discount is shown as a rate or as an installment
        */
        @AuraEnabled
        global Debit debit {get; set;}
        /*
        * @Description: Maximum amount of debit discount
        */
        @AuraEnabled
        global AmountCurrency amount {get; set;}
        /*
        * @Description: Percentage discount
        */
        @AuraEnabled
        global Percentage percentage {get; set;}
        /*
        * @Description: Amount of commissions charged resulting from the multiplication of discount rates on credit, debit and international cards and their corresponding billing
        */
        @AuraEnabled
        global AmountCurrency card {get; set;}
    }
    /*
    * @Description: Information about the customer's devices
    */
    global class DevicesInfo {
        /*
        * @Description: Total Number of devices
        */
        @AuraEnabled
        global Integer devices {get; set;}
    }
    /*
    * @Description: Information on expenses
    */
    global class Expenses {
        /*
        * @Description: Amount of total expenses
        */
        @AuraEnabled
        global AmountCurrency totalAmount {get; set;}
        /*
        * @Description: The total amount of Volaris' commission expenses (ebind) and the percentage that does not stay in BBVA, is charged to the customer but goes to the aggregator (mit)
        */
        @AuraEnabled
        global AmountCurrency mit {get; set;}
    }
    /*
    * @Description: Commission information
    */
    global class Fees {
        /*
        * @Description: Amount of commissions per cellular network
        */
        @AuraEnabled
        global AmountCurrency cellnet {get; set;}
        /*
        * @Description: Low billing commission amount
        */
        @AuraEnabled
        global AmountCurrency billing {get; set;}
        /*
        * @Description: Total amount of commissions for extra POS
        */
        @AuraEnabled
        global AmountCurrency extraBilling {get; set;}
        /*
        * @Description: Commission collection opportunity information
        */
        @AuraEnabled
        global Opportunity opportunity {get; set;}
    }
    /*
    * @Description: Mix Percentage Information
    */
    global class PercentageContainer {
        /*
        * @Description: Percentage of credit mix
        */
        @AuraEnabled
        global Mix credit {get; set;}
        /*
        * @Description: Percentage of debit mix
        */
        @AuraEnabled
        global Mix debit {get; set;}
        /*
        * @Description: Percentage of international mix
        */
        @AuraEnabled
        global Decimal mixInternational {get; set;}
        /*
        * @Description: Total mix percentage
        */
        @AuraEnabled
        global Decimal total {get; set;}
    }
    /*
    * @Description: Electronic device used in a debit, credit or smart card transaction
    */
    global class PinPadsInfo {
        /*
        * @Description: Number of pin pads installed
        */
        @AuraEnabled
        global Integer pinPads {get; set;}
    }
    /*
    * @Description: Commission collection opportunity information
    */
    global class Opportunity {
        /*
        * @Description: Information on commission collection opportunity for cellular network
        */
        @AuraEnabled
        global AmountCurrency cellnet {get; set;}
        /*
        * @Description: Commission collection opportunity amount for low billing provided by the model
        */
        @AuraEnabled
        global AmountCurrency lowBilling {get; set;}
        /*
        * @Description: Commission collection opportunity amount for extra POS provided by the model
        */
        @AuraEnabled
        global AmountCurrency posExtra {get; set;}
    }
    /*
    * @Description: Terminal where the customer performed the operation
    */
    global class Terminal {
        /*
        * @Description: Terminal number tpv pos
        */
        @AuraEnabled
        global Integer id_y {get; set;}
    }
    /*
    * @Description: Billing information
    */
    global class Tickets {
        /*
        * @Description: Credit billing information
        */
        @AuraEnabled
        global OwnThirdPartyContainer credit {get; set;}
        /*
        * @Description: Debit billing information
        */
        @AuraEnabled
        global OwnThirdPartyContainer debit {get; set;}
        /*
        * @Description: Terminal number tpv pos
        */
        @AuraEnabled
        global AmountCurrency international {get; set;}
        /*
        * @Description: Terminal number tpv pos
        */
        @AuraEnabled
        global AmountCurrency totalAmount {get; set;}
    }
    /*
    * @Description: Transaction information
    */
    global class Transaction_y {
        /*
        * @Description: Total cumulative number of transactions of the acquiring product from all BBVA electronic payment providers in the month and for the affiliation, i.e. the affiliated merchant
        */
        @AuraEnabled
        global Integer acquirerAffiliation {get; set;}
        /*
        * @Description: Debit transaction information
        */
        @AuraEnabled
        global OwnThirdParty debit {get; set;}
        /*
        * @Description: Information on credit transactions
        */
        @AuraEnabled
        global OwnThirdParty credit {get; set;}
        /*
        * @Description: Number of international customer transactions
        */
        @AuraEnabled
        global Integer international {get; set;}
    }
    /*
    * @Description: Debit discounts
    */
    global class Debit {
        /*
        * @Description: Flag indicating whether the debit discount is shown as a rate or as an installment
        */
        @AuraEnabled
        global String mark {get; set;}
        /*
        * @Description: Customer's debit discount rate or fee number
        */
        @AuraEnabled
        global Decimal number_y {get; set;}
    }
    /*
    * @Description: amount + currency fields
    */
    global class AmountCurrency {
        /*
        * @Description: Import Amount
        */
        @AuraEnabled
        global Decimal amount {get; set;}
        /*
        * @Description: String based on ISO-4217 for specifying the currency related to the monetary amount
        */
        @AuraEnabled
        global String currency_y {get; set;}
    }
    /*
    * @Description: Percentage discount
    */
    global class Percentage {
        /*
        * @Description: Percentage discount rate on customer credit
        */
        @AuraEnabled
        global Decimal credit {get; set;}
        /*
        * @Description: Percentage discount rate for international customers
        */
        @AuraEnabled
        global Decimal international {get; set;}
    }
    /*
    * @Description: own  + thirdParty fields
    */
    global class OwnThirdParty {
        /*
        * @Description: Number of customer's own debit transactions
        */
        @AuraEnabled
        global Integer own {get; set;}
        /*
        * @Description: Number of customer's third party debit transactions
        */
        @AuraEnabled
        global Integer thirdParty {get; set;}
    }
    /*
    * @Description: mixExternal + mixOwn fields
    */
    global class Mix {
        /*
        * @Description: Percentage of external mix
        */
        @AuraEnabled
        global Decimal mixExternal {get; set;}
        /*
        * @Description: Own mix percentage
        */
        @AuraEnabled
        global Decimal mixOwn {get; set;}
    }
}