/**
* ____________________________________________________________________________
* Simulate Factoring Response Wrapper
* Wrapper class for the response of the ASO service "simulate-factoring"
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
global class RPP_SimulateFactoringResponse_Wrapper {
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
    * @Description: Goal rating Standard’s and Poor method
    */
    @AuraEnabled
    global String ratingStandardAndPoors;
    /*
    * @Description: Results dilution
    */
    @AuraEnabled
    global ResultsDilution resultsDilution;
    /*
    * @Description: Results S&P Method Rating
    */
    @AuraEnabled
    global List<ResultsSandP> resultsStandardAndPoors;
    /*
    * @Description: Simulation results
    */
    @AuraEnabled
    global SimulationResults simulationResults;
    /*
    * @Description: Totals results of the simulation
    */
    @AuraEnabled
    global TotalSimulation totalSimulation;
    /*
    * @Description: Assignor of the portfolio
    */
    global class Assignor {
        /*
        * @Description: Default probability
        */
        @AuraEnabled
        global Decimal averagePD;
        /*
        * @Description: Assignor calculated debt rating
        */
        @AuraEnabled
        global String debtRating;
        /*
        * @Description: Exposure at default
        */
        @AuraEnabled
        global Decimal ead;
        /*
        * @Description: Expected loss
        */
        @AuraEnabled
        global Decimal expectedLoss;
        /*
        * @Description: Assignor’s internal rating
        */
        @AuraEnabled
        global String internalRating;
        /*
        * @Description: Assignor rating calculated with Standards and Poor method
        */
        @AuraEnabled
        global String ratingStandardAndPoors;
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
        * @Description: Default probability
        */
        @AuraEnabled
        global Decimal averagePD;
        /*
        * @Description: Debtor’s calculated Rating
        */
        @AuraEnabled
        global String calculatedRating;
        /*
        * @Description: Debtor’s calculated Rating SP
        */
        @AuraEnabled
        global String calculatedRatingStandardAndPoors;
        /*
        * @Description: Debtor's document
        */
        @AuraEnabled
        global String document;
        /*
        * @Description: Exposure at default
        */
        @AuraEnabled
        global Decimal ead;
        /*
        * @Description: Expected loss
        */
        @AuraEnabled
        global Decimal expectedLoss;
        /*
        * @Description: Debtor’s internal rating
        */
        @AuraEnabled
        global String internalRating;
        /*
        * @Description: Debtor’s KIRB
        */
        @AuraEnabled
        global Decimal kirb;
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
    * @Description: Results dilution
    */
    global class ResultsDilution {
        /*
        * @Description: Dilution
        */
        @AuraEnabled
        global ValuePercentage dilution;
        /*
        * @Description: Maximum liability
        */
        @AuraEnabled
        global ValuePercentage maximumLiability;
        /*
        * @Description: Risk retention
        */
        @AuraEnabled
        global ValuePercentage riskRetention;
        /*
        * @Description: Senior tranche
        */
        @AuraEnabled
        global ValuePercentage seniorTranche;
        /*
        * @Description: Maximun insurance amount
        */
        @AuraEnabled
        global ValuePercentage maximumInsuranceAmount;
    }
    /*
    * @Description: Results S&P Method Rating
    */
    global class ResultsSandP {
        /*
        * @Description: First loss
        */
        @AuraEnabled
        global Decimal firstLoss;
        /*
        * @Description: Objective rating
        */
        @AuraEnabled
        global String objectiveRating;
        /*
        * @Description: Rating loss
        */
        @AuraEnabled
        global String ratingLoss;
    }
    /*
    * @Description: Simulation results
    */
    global class SimulationResults {
        /*
        * @Description: Simulated first loss
        */
        @AuraEnabled
        global Decimal firstLoss;
        /*
        * @Description: Lower rating
        */
        @AuraEnabled
        global String lowerRating;
        /*
        * @Description: Maximun between S&P and fixed
        */
        @AuraEnabled
        global Decimal maxOrFixed;
        /*
        * @Description: Senior rating
        */
        @AuraEnabled
        global String ratingSenior;
        /*
        * @Description: Simulated rating
        */
        @AuraEnabled
        global Decimal simulatedRating;
        /*
        * @Description: Total limit
        */
        @AuraEnabled
        global Decimal totalLimit;
    }
    /*
    * @Description: Totals results of the simulation
    */
    global class TotalSimulation {
        /*
        * @Description: Credit enhancement
        */
        @AuraEnabled
        global Decimal ce;
        /*
        * @Description: Equivalent rating
        */
        @AuraEnabled
        global String equivalentRating;
        /*
        * @Description: Risk-weighted asset
        */
        @AuraEnabled
        global Decimal rwa;
        /*
        * @Description: Total extend loss
        */
        @AuraEnabled
        global Decimal totalExpectedLoss;
        /*
        * @Description: Total KIRB for the simulation
        */
        @AuraEnabled
        global Decimal totalKIRB;
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
    /*
    * @Description: Value + Percentage
    */
    global class ValuePercentage {
        /*
        * @Description: Value
        */
        @AuraEnabled
        global Decimal value;
        /*
        * @Description: Percentage
        */
        @AuraEnabled
        global Decimal percentage;
    }
}