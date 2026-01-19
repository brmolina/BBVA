/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveMainBuroHelper
* @Author   Bertha Elena Tellez Lira
* @Date     Created: 13/02/2020
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
public class Arc_Gen_SaveMainBuroHelper {
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to call Main and Bureau persistance service
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example DataMainBuro mb = new DataMainBuro()
    * -----------------------------------------------------------------------------------------------
    **/
    public class DataMainBuro {
        /**
        * @Description: String with an identifier of dinamic form
        */
        public String idDF {get; set;}
        /**
        * @Description: String with a value of adicional coments of politics
        */
        public String hasSummaryComm {get; set;}
        /**
        * @Description: String with a value of comments of risk
        */
        public String commentsRisk {get; set;}
        /**
        * @Description: String with a value of numbre of bancks
        */
        public String numOfBanks {get; set;}
        /**
        * @Description: String with a value of others products of customer
        */
        public String othersProducs {get; set;}
        /**
        * @Description: String with a value of comments about the others products of customer
        */
        public String othersProdComm {get; set;}
        /**
        * @Description: String with a value of other operations of customer
        */
        public String otherOperations {get; set;}
        /**
        * @Description: String with a value of comments about the others products of customer
        */
        public String otherOprDesc {get; set;}
        /**
        * @Description: String with a value of rentability
        */
        public String rarRentab {get; set;}
        /**
        * @Description: String with a value of comments about the rentability
        */
        public String rarComm {get; set;}
        /**
        * @Description: String with a value of Level qualification
        */
        public String nivelWL {get; set;}
        /**
        * @Description: String with a value of operations in Stage
        */
        public String stageColl {get; set;}
        /**
        * @Description: String with a value of comments about operations in Stage
        */
        public String stageCollDesc {get; set;}
        /**
        * @Description: String with a value of Analysis of compensation, reciprocity and transactionality of the client
        */
        public String custProductUsage {get; set;}
        /**
        * @Description: String with a value of total detail of the debt
        */
        public String bankPool {get; set;}
        /**
        * @Description: String with a value of Capital provition
        */
        public String capProvTyp {get; set;}
        /**
        * @Description: String with a value of comments about Capital provition
        */
        public String capProvDesc {get; set;}
        /**
        * @Description: String with a value of covenats breach
        */
        public String covenBreach {get; set;}
        /**
        * @Description: String with a value of comments about covenants breach
        */
        public String covenBreachDesc {get; set;}
    }

}