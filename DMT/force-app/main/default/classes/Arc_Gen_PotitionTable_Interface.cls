/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionTable_Interface
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Interfaz for Arc_Gen_PotitionBankTable CMP
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             Added new methods
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             deleted unused methods
* -----------------------------------------------------------------------------------------------
*/
global interface Arc_Gen_PotitionTable_Interface {
    Arc_Gen_DataTable getData(Id recordId);
}