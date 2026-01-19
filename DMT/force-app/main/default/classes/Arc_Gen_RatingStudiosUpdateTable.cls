/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingStudiosUpdateTable
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 28/10/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class to implements the interface of Dynamic Table and updates the selected record of studies
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_RatingStudiosUpdateTable implements dwp_dv.SelectionActionInterface {
    /**
*-------------------------------------------------------------------------------
* @description Global method that sets in false the selected record check
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com | 25/10/2019
* @param String recordId - Id of the selected record of the studies table
* @param Boolean value - Value of the selected record check
* @return Boolean - Updated check
* @example updateSelected (String recordId, Boolean value)
**/
    global Boolean updateSelected (String recordId, Boolean value) {
        Return false;
    }
}