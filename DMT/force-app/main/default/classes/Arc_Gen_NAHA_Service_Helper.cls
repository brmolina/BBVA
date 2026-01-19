/**
* --------------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NAHA_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-10-12
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_NAHACtrl
* --------------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-10-12 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-29 javier.soto.carrascosa@bbva.com
*             Recover boolean saveobject
* |2020-04-02 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add two new parameters in setupPath() and created SetupPathWrapper to avoid 'long parameter lists'
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-16 antonio.munoz.perez.contractor@bbva.com
*             Created validateTDRating() method.
* --------------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_NAHA_Service_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2019-10-12
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Service Service = new Arc_Gen_NAHA_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_NAHA_Service_Helper() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that call the path service
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2019-10-12
    * @param idRecord - Id of an account has analysis object
    * @return arce.Arc_Gen_ServiceAndSaveResponse - response of the service
    * @example callPathService(idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse callPathService(Id idRecord) {
        Arc_Gen_getPathDataService_service.SetupPathWrapper pathParameters = new Arc_Gen_getPathDataService_service.SetupPathWrapper();
        final Arc_Gen_getPathDataService_service servicePath = new Arc_Gen_getPathDataService_service();
        final List<String> parameters =  Arc_Gen_getPathDataService_data.getAnalysisAndCustomer(idRecord);
        pathParameters.analysisId = parameters[0];
        pathParameters.customerId = parameters[1];
        pathParameters.clientNumber = parameters[2];
        pathParameters.subsidiary = parameters[3];
        pathParameters.saveobject = false;
        return servicePath.setupPath(pathParameters);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that validates if an arce__Account_has_Analysis__c can be added to the carousel.
    *              If that is true, it returns an arce__Account_has_Analysis__c to be updated.
    *              The logic might be local.
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2020-12-16
    * @param idRecord - Id of an account has analysis object
    * @return Arc_Gen_ServiceAndSaveResponse
    * @example validateTDRating(idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse validateTDRating(Id idRecord) {
        arce.Arc_Gen_ServiceAndSaveResponse servSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaLst = arce.Arc_Gen_AccHasAnalysis_Data.getRatingAnalysis(idRecord);
        final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('CopyRatingInterface');
        final String localClass = Test.isRunningTest() ? 'Arc_GBL_ToCopyRating' : lstArceConfig.get(0).arce__Value1__c;
        final Type inter = Type.forName(localClass);
        final Arc_Gen_ToCopyRating_Interface ToCopy = (Arc_Gen_ToCopyRating_Interface) inter.newInstance();
        final arce__Account_has_Analysis__c matrix  = ToCopy.getMatrix(ahaLst, idRecord);
        final arce__Account_has_Analysis__c groupAha = ToCopy.getHeader(ahaLst, idRecord);
        if ( idRecord == matrix.Id && ToCopy.doCopy(matrix, groupAha) ) {
            servSaveResp = ToCopy.updateRating(matrix, groupAha);
        } else if (idRecord == matrix.Id) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_TD_add_Matrix_error);
        }
        return servSaveResp;
    }
}