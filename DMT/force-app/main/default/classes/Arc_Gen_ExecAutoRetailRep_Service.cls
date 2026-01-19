/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecAutoRetailRep_Service
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-03-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service for Executive Summary visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-03-01 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ExecAutoRetailRep_Service {
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_ExecAutoRetailRep_Service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon
    * @Date     2019-07-03
    * @param    null
    * @return   Arc_Gen_ExecAutoRetailRep_Service
    * @example  new Arc_Gen_ExecAutoRetailRep_Service()
    * */
    @TestVisible
    private Arc_Gen_ExecAutoRetailRep_Service() {
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Page that control to build Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon
    * @Date     2021-03-01
    * @param    Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF wrappObj Objeto wrapper para generar pdf
    * @return    Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF wrappObj Objeto wrapper para generar pdf
    * @example  Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF GenPDF(Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF wrappObj)
    * */
    public static Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF genPDF(Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF wrappObj) {
        final Id rid = wrappObj.rid;
        Arc_Gen_ExecAutoRetailRep_Controller.WrapPDF newWrappObj = wrappObj;
        newWrappObj = Arc_Gen_ExecAutoRetailRep_Helper.getAutoRetailData(rid, newWrappObj);
        return newWrappObj;
    }
}