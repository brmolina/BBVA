/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NAHACtrl
* @Author   LUIS RUBEN QUINTO MUÑOZ  luisruben.quinto.munoz@bbva.com
* @Date     Created: 2019-07-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Obtains the data of the analyzed client to call List Customers Service and sets the
* path when a customer is added to the ARCE
* ------------------------------------------------------------------------------------------------
* @Changes
* |28/07/2019   luisruben.quinto.munoz@bbva.com
*               Class creation.
* |19/08/2019   eduardoefrain.hernandez.contractor@bbva.com
*               Added carousel-calling functions
* |03/09/2019   ricardo.almanza.contractor@bbva.com
*               Added setupRiskAssessments
* |27/11/2019   ricardo.almanza.contractor@bbva.com
*               Added Insertion of data in risk position summary
* |10/12/2019   mariohumberto.ramirez.contractor@bbva.com
*               Change to SOC
* |29/01/2020   javier.soto.carrascosa@bbva.com
*               Valid action with arce allocation and do not execute services if element is removed
* |29/01/2020   ricardo.almanza.contractor@bbva.com
*               Added messages for scope and triage
* |04/06/2020   joseluis.garcia4.contractor@bbva.com
*               Fix incorrect message shown when adding a no-scope customer with no async triage.
* -----------------------------------------------------------------------------------------------
*/

global class Arc_Gen_NAHACtrl implements qvcd.GBL_QVCD_Interface {

/*------------------------------------------------------------------------------------------------------
*@Description Naha Controller
* -----------------------------------------------------------------------------------------------------
* @Author   LUIS RUBEN QUINTO MUÑOZ
* @Date     2019-07-28
* @param    Id idRecord - Id of the Account has Analysis selected
* @param    String field - Field selected
* @param    Boolean value - If is true, the analyzed client is visible in the carousel
* @return   qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper - Wrapper that contains the response of the quick view card
* @example  validElementInCarousel(Id idRecord, String field, boolean value)
* -----------------------------------------------------------------------------------------------------------------
* */
    global qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper validElementInCarousel(Id idRecord, String field, boolean value) {
        qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = new qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper();
        final boolean canAdd = Arc_Gen_NAHA_Service.validateAddElement(idRecord);
        final String triageStat = Arc_Gen_NAHA_Service.triageElement(idRecord);
        System.debug('triageStat '+triageStat);
        if (value && canAdd) {
            final String scope = Arc_Gen_NAHA_Service.scopeElement(idRecord);
            if (scope == Arc_Gen_NAHA_Service.SCOPE_INSCOPE) {
                response = Arc_Gen_NAHA_Service.validElementInCarousel(idRecord, field, value);
            } else if (scope == Arc_Gen_NAHA_Service.SCOPE_NOTINSCOPE) {
                response.gblResultResponse = false;
                response.gblDescriptionResponse = System.Label.Arc_Gen_ScopeNAHA;
            } else {
                response.gblResultResponse = false;
                response.gblDescriptionResponse = triageStat == '1' ? System.Label.Arc_Gen_PendNAHA : System.Label.Lc_arce_NewARCE_UnexpectedError;
            }
        } else if (!value && canAdd) {
            response.gblResultResponse = true;
        } else {
            response.gblResultResponse = false;
            response.gblDescriptionResponse = System.Label.Customer_Allocation_Error_3;
        }
        return response;
    }
}