/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecAutoRetailRep_Controller
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-03-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to obtain info in order to print executive summary for Auto Retail Template
* ------------------------------------------------------------------------------------------------
* @Changes
* |2021-03-01 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyFields')
public without sharing class Arc_Gen_ExecAutoRetailRep_Controller {
    /**
    *   wrapper that contains the data of the template
    * @author eduardoefrain.hernandez.contractor@bbva.com
    */
    public WrapPDF wrapIns {get;set;}

    /**
    * ------------------------------------------------------------------------------------------------
    * @Name     WrapPDF
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-03-01
    * @Group    ARCE
    * ------------------------------------------------------------------------------------------------
    * @Description Class to Wrap results between SOC
    * ------------------------------------------------------------------------------------------------
    * @Changes
    * -----------------------------------------------------------------------------------------------
    */
    public class WrapPDF {
        /**
        *   record Id
        * @author Efraín Rendón
        */
        Public Id rid {get;set;}
        /**
        *   selected year 1
        * @author Efraín Rendón
        */
        Public String year1 {get;set;}
        /**
        *   selected year 2
        * @author Efraín Rendón
        */
        Public String year2 {get;set;}
        /**
        *   AutoRetail behavior table for news
        * @author Efraín Rendón
        */
        Public Arc_Gen_AutoRetailTableRow[] autoRetForNews {get;set;}
        /**
        *   AutoRetail behavior table for seminews
        * @author Efraín Rendón
        */
        Public Arc_Gen_AutoRetailTableRow[] autoForSemiNews {get;set;}
        /**
        * ------------------------------------------------------------------------------------------------
        * @Description Constructor of WrapPDF to set recordId of Account has analysis
        * ------------------------------------------------------------------------------------------------
        * @param Id recordId of Account has analysis
        * @return Constructed Obj WrapPDF
        * @example new WrapPDF(ApexPages.currentPage().getParameters().get('Id'))
        * ------------------------------------------------------------------------------------------------
        **/
        public WrapPDF(Id accHasId) {
            rid = accHasId;
        }
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Constructor of Arc_Gen_ExecAutoRetailRep_Controller to obtain data in order to print PDF
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @param ApexPages.StandardController controller Control of Apex page to print VF
    * @return Constructed Obj Arc_Gen_ExecAutoRetailRep_Controller
    * @example Arc_Gen_ExecAutoRetailRep_Controller(ApexPages.StandardController controller)
    * ------------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_ExecAutoRetailRep_Controller(ApexPages.StandardController controller) {
        WrapPDF wrappObj = new WrapPDF(Id.valueOf(controller.getRecord().Id));
        wrappObj = Arc_Gen_ExecAutoRetailRep_Service.genPDF(wrappObj);
        relateWrapperVars(wrappObj);
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Constructor of wrapIns to obtain data in order to print PDF
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @param wrappObj Wrapper that contains the data to show
    * @return void
    * @example relateWrapperVars(WrapPDF wrappObj)
    * ------------------------------------------------------------------------------------------------
    **/
    private void relateWrapperVars(WrapPDF wrappObj) {
        wrapIns = wrappObj;
    }
}