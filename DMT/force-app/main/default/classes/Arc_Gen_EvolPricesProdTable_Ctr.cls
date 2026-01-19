/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EvolPricesProdTable_Ctr
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2021-26-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to manage Arc_Gen_EvolPricesTableModal cmp
* ------------------------------------------------------------------------------------------------
* |2021-26-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_EvolPricesProdTable_Ctr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param void
    * @return void
    * @example Arc_Gen_EvolPricesProdTable_Ctr controller = new Arc_Gen_EvolPricesProdTable_Ctr()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_EvolPricesProdTable_Ctr() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description return the columns and rows of the evolution prices table for agro template
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param accHasId - id of an account has analysis object
    * @return String
    * @example getTableInfo(accHasId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTableInfo(String accHasId) {
        return Arc_Gen_EvolPricesProdTable_Service.getTableInfo(accHasId);
    }
}