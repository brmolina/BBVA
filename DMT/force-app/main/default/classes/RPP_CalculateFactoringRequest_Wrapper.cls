/**
* ____________________________________________________________________________
* Calculate Factoring Request Wrapper
* Wrapper class for the request of the ASO service "calculate-factoring"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-04-18
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class RPP_CalculateFactoringRequest_Wrapper {
    /*
    * @Description: Assignor of the portfolio
    */
    @AuraEnabled
    global Assignor assignor;
    /*
    * @Description: Debtors associated to the portfolio
    */
    @AuraEnabled
    global List<Debtor> debtorsList;
    /*
    * @Description: Assignor of the portfolio
    */
    global class Assignor {
        /*
        * @Description: Identity document of the assignor.It could be VAT or CIF. DISCLAIMER: Attributes name and document are optional. At least one attribute must be informed
        */
        @AuraEnabled
        global String document;
        /*
        * @Description: Assignor’s name. DISCLAIMER: Attributes name and document are optional. At least one attribute must be informed
        */
        @AuraEnabled
        global String name;
    }
    /*
    * @Description: Debtors associated to the portfolio
    */
    global class Debtor {
        /*
        * @Description: Limit associated with the debtor
        */
        @AuraEnabled
        global AmountCurrency amountLimit;
        /*
        * @Description: Total bills associated with the debtor
        */
        @AuraEnabled
        global AmountCurrency amountTotalBills;
        /*
        * @Description: Debtor’s document. It could be VAT or CIF. DISCLAIMER: Attributes name and document are optional. At least one attribute must be informed
        */
        @AuraEnabled
        global String document;
        /*
        * @Description: Legal entity identifier
        */
        @AuraEnabled
        global String lei;
        /*
        * @Description: Debtor's name. DISCLAIMER: Attributes name and document are optional. At least one attribute must be informed
        */
        @AuraEnabled
        global String name;
        /*
        * @Description: Debtor’s percentage of the total llimit
        */
        @AuraEnabled
        global Decimal percentage;
    }
    /*
    * @Description: Amount + Currency
    */
    global class AmountCurrency {
        /*
        * @Description: Amount
        */
        @AuraEnabled
        global Decimal amount;
        /*
        * @Description: String based on ISO-4217 for specifying the currency
        */
        @AuraEnabled
        global String currency_y;
    }
}