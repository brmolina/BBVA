/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveFinancialStatementHelper
* @Author   Bertha Elena Tellez Lira
* @Date     Created: 07/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Helper Class that contains the Financial Statement wrappers
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-02-06 Bertha Elena Téllez Lira
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyFields')
public class Arc_Gen_SaveFinancialStatementHelper {
/**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to set property list of wrapper finacial Statement
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Indicators indiList = new Indicators()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ArraysData {
        /**
        * @Description: String with an identifier of dinamic form
        */
        public String id {get; set;}
        /**
        * @Description: String with an identifier of indicators
        */
        public String idIndicator {get; set;}
        /**
        * @Description: Boolean with a value of isActive of indicators
        */
        public String isActive {get; set;}
        /**
        * @Description: String with a value of variables
        */
        public String variableType {get; set;}
        /**
        * @Description: String with a comment of indicators
        */
        public String commentsIndicators {get; set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to call Financial Risk service
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example FinacialStatements fs = new FinacialStatements()
    * -----------------------------------------------------------------------------------------------
    **/
    public class FinacialStatements{
        /**
        * @Description: String with an identifier of dinamic form
        */
        public String id {get; set;}
        /**
        * @Description: String with an opinion of auditor
        */
        public String opinionAuditor {get; set;}
        /**
        * @Description: String with a full name of auditor
        */
        public String fullName {get; set;}
        /**
        * @Description: String with a quality of auditor
        */
        public String quality {get; set;}
        /**
        * @Description: String with a Comments of auditor
        */
        public String agentComments {get; set;}
        /**
        * @Description: String with an id of Financial Statement
        */
        public String finStId {get; set;}
        /**
        * @Description: String with a value of Financial Statement Consolidated
        */
        public String finStConsolidate {get; set;}
        /**
        * @Description: String with a value of currency
        */
        public String currencyType{get; set;}
        /**
        * @Description: String with a value of units
        */
        public String units {get; set;}
        /**
        * @Description: String with a value of available maturity table
        */
        public String availableMat {get; set;}
        /**
        * @Description: String with a value of debt maturity
        */
        public String debtMat {get; set;}
        /**
        * @Description: String with a value of total bancks numbers
        */
        public String banksNumbre {get; set;}
        /**
        * @Description: String with a value of budget of year
        */
        public String budgetType {get; set;}
        /**
        * @Description: String with a value of budget comments
        */
        public String budgetIsInc {get; set;}
        /**
        * @Description: String with a value of included budget
        */
        public String budgetComments {get; set;}
        /**
        * @Description: List with the values of Indicators
        */
        public List<arraysData> listIndicator {get; set;}
        /**
        * @Description: List with the values of Variations
        */
        public List<arraysData> listVariations {get; set;}
        /**
        * @Description: List with the values of Variables
        */
        public List<arraysData> listVariables {get; set;}
    }
}