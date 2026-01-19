/**
* ____________________________________________________________________________
* Simulate Factoring Request Wrapper
* Wrapper class for the request of the ASO service "simulate-factoring"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-06-02
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class RPP_SimulateFactoringRequest_Wrapper {
    /*
    * @Description: Assignor of the portfolio
    */
    @AuraEnabled
    global Assignor assignor;
    /*
    * @Description: Configuration data for the simulation.
    */
    @AuraEnabled
    global Configuration configuration;
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
        * @Description: Assignor’s internal rating
        */
        @AuraEnabled
        global String internalRating;
        /*
        * @Description: Total limit associated to the portfolio
        */
        @AuraEnabled
        global AmountCurrency totalLimit;
    }
    /*
    * @Description: Configuration data for the simulation
    */
    global class Configuration {
        /*
        * @Description: Applies insurance
        */
        @AuraEnabled
        global Boolean applyInssurance;
        /*
        * @Description: Assignor rating
        */
        @AuraEnabled
        global String assignorRating;
        /*
        * @Description: Average dilution
        */
        @AuraEnabled
        global Decimal averageDilution;
        /*
        * @Description: Deviation dilution
        */
        @AuraEnabled
        global Decimal deviationDilution;
        /*
        * @Description: Equivalence PD for non rated
        */
        @AuraEnabled
        global String equivalencePDNonRated;
        /*
        * @Description: Prefixed first lost level
        */
        @AuraEnabled
        global Decimal firstLossLevel;
        /*
        * @Description: Goal of the simulation
        */
        @AuraEnabled
        global String goal;
        /*
        * @Description: Inssurance liability
        */
        @AuraEnabled
        global Decimal isInssuranceLiability;
        /*
        * @Description: LGD Capital
        */
        @AuraEnabled
        global Decimal lgdCapital;
        /*
        * @Description: Maturity
        */
        @AuraEnabled
        global Decimal maturity;
        /*
        * @Description: Maximum percentage of non rated debtors
        */
        @AuraEnabled
        global Decimal maxLimitNonRated;
        /*
        * @Description: Number of simulations
        */
        @AuraEnabled
        global Decimal numberSimulations;
        /*
        * @Description: Goal rating
        */
        @AuraEnabled
        global String ratingSimLosses;
        /*
        * @Description: Seller rating
        */
        @AuraEnabled
        global String sellerRating;
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
        * @Description: Debtor's document
        */
        @AuraEnabled
        global String document;
        /*
        * @Description: Debtor’s internal rating
        */
        @AuraEnabled
        global String internalRating;
        /*
        * @Description: Debtor’s lei
        */
        @AuraEnabled
        global String lei;
        /*
        * @Description: Debtor’s name
        */
        @AuraEnabled
        global String name;
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