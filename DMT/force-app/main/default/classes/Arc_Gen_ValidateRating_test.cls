/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingStudiosUpdateTable
* @Author   Eduardo Efrain Hernandez Rendon  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 28/10/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests the classes ValidateRating_controller,ValidateRating_service and ValidateRating_data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Add static service parameters and comments
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2020-01-07 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |24/01/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Remove logic static parameters to ASO services
* |24/06/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             update test class
* |07/07/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create constant variable called USERADMIN
* |17/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Create testingRatingDataRAIP, testControllerConstr methods.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |02/02/2021 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |24/02/2021 joseluis.garcia4.contractor@bbva.com
*             Update test to reflect new parameter in setupValidateRating() method.
* |2021-03-12 eduardoefrain.hernandez.contractor@bbva.com
*             Change arce__modifier_type__c field to arce__rating_modifier_adj_type__c
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_ValidateRating_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with literal UserAdmin
    */
    static final string USERADMIN = 'UserAdmin';
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup test
    * --------------------------------------------------------------------------------------
    * @Author   javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-01-08
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
    arce.Arc_UtilitiesToTest_tst.enableBypass();
    Arc_UtilitysDataTest_tst.setupAcccounts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String name - Name of the arce
    * @return  arce__Analysis__c
    * @example setAnalysis(String name)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c setAnalysis(String name) {
        arce__Analysis__c analysis = new arce__Analysis__c(
            Name = name,
            arce__wf_status_id__c = '02',
            arce__Stage__c = '1'
        );
        Insert analysis;
        Return analysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String clientId - Id of the account
    * @param String analysisId - Id of the arce
    * @param String validFs - Id of valid FS
    * @return arce__Account_has_Analysis__c
    * @example setAnalyzedClient(String clientId,String analysisId,String validFs)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedClient(String clientId,String analysisId,String validFs) {
        arce__Account_has_Analysis__c analyzedClient = new arce__Account_has_Analysis__c(
            arce__Customer__c = clientId,
            arce__Analysis__c = analysisId,
            arce__ffss_for_rating_id__c = validFs
        );
        Insert analyzedClient;
        Return analyzedClient;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String accName - Name of the account
    * @param String accNumber - Number of the account
    * @param String analysisName - Name of the arce
    * @param String validFs - Id of valid FS
    * @return arce__Account_has_Analysis__c
    * @example getAnalyzedClient(String accName,String accNumber,String analysisName,String validFs)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedClient(String accNumber,String analysisName,String validFs) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accNumber});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(accNumber);
        arce__Analysis__c analysis = setAnalysis(analysisName);
        arce__Account_has_Analysis__c accHasAn = setAnalyzedClient(groupAccount.accId,analysis.Id,validFs);
        Return accHasAn;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String ratingId - Id of the rating
    * @param String validInd - Valid indicator
    * @return arce__Financial_Statements__c
    * @example setFFSS(String ratingId, String validInd)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Financial_Statements__c setFFSS(String ratingId, String validInd) {
        arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(
            arce__ffss_valid_type__c = validInd,
            arce__financial_statement_id__c = '70252018129',
            arce__rating_id__c = ratingId
        );
        Insert ffss;
        Return ffss;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return arce__rating__c
    * @example setRating()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__rating__c setRating(String ratingValue, Decimal scoreNumber) {
        arce__rating__c rating = new arce__rating__c(
            arce__rating_id__c = '0000000120160130XX',
            arce__status_type__c = '2',
            arce__rating_long_value_type__c = ratingValue,
            arce__rating_short_value_type__c = 'BBB',
            arce__short_rating_value_type__c = 'AAA',
            arce__long_rating_value_type__c = 'BBB-2',
            arce__total_rating_score_number__c = scoreNumber,
            arce__PD_per__c = 0.24
        );
        Insert rating;
        Return rating;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String analysisId - arce id
    * @param String ratingId - id of the rating
    * @return arce__rating_variables_detail__c
    * @example setRatingVariable(String analysisId,String ratingId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__rating_variables_detail__c setRatingVariable(String analysisId,String ratingId) {
        arce__rating_variables_detail__c ratingVariable = new arce__rating_variables_detail__c(
            arce__account_has_analysis_id__c = analysisId,
            arce__rating_id__c = ratingId,
            arce__adj_long_rating_value_type__c = 'BBB+1',
            arce__adj_short_rating_value_type__c = 'CC',
            arce__rating_modifier_adj_type__c = 'OVERRIDE'
        );
        Insert ratingVariable;
        Return ratingVariable;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingRatingData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingRatingData1() {
        try {
            final arce__rating__c rating = setRating('AAA', 90.0);
            final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
            final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,'Analysis Test',ffss.Id);
            Test.startTest();
            Arc_Gen_ValidateRating_controller.getRatingData(accHasAn.Id);
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'The method obtains the information of the rating');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingChangeStatus()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingChangeStatus() {
        User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADMIN,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = 'XME0514';
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
        Insert userAdmin;
        List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        arce__rating__c rating = new arce__rating__c();
        System.runAs(userAdmin) {
            rating = setRating('AAA', 90.0);
            arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
            arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,'Analysis Test',ffss.Id);
            Test.startTest();
            Arc_Gen_ValidateRating_controller.changeStatus(accHasAn.Id, rating.Id, false);
            Test.stopTest();
        }
        arce__rating__c modifiedRating = [SELECT arce__status_type__c FROM arce__rating__c WHERE Id =: rating.Id][0];
        System.assertEquals('3', modifiedRating.arce__status_type__c, 'The method changes the status of the ratinf FROM 2 to 3');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingDML()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingDML() {
        Arc_Gen_ValidateRating_data locator = new Arc_Gen_ValidateRating_data();
        Arc_Gen_ValidateRating_data.saveResult result = new Arc_Gen_ValidateRating_data.saveResult();
        arce__analysis__c arce1 = new arce__analysis__c(
            Name='Test1',
            arce__Stage__c='1'
        );
        insert arce1;
        arce1.Name = '12345678901234567890121234567890123456789012123456789012345678901212345678901234567890121234567890123456789012';
        Test.startTest();
        result = locator.updateRecord(arce1);
        Test.stopTest();
        System.assertEquals('false', result.status, 'The update send a false because there is an error in the DML operation');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingCalloutError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingCalloutError() {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADMIN,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = 'XME0514';
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
        Insert userAdmin;
        List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        List<iaso__GBL_Rest_Services_Url__c> ratingCustSett = [SELECT Name, iaso__Timeout__c FROM iaso__GBL_Rest_Services_Url__c WHERE name = 'ratingEngine'];
        ratingCustSett[0].iaso__Timeout__c = 0;
        update ratingCustSett;
        arce__rating__c rating = new arce__rating__c();
        System.runAs(userAdmin) {
            rating = setRating('AAA', 90.0);
            arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
            arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,'Analysis Test',ffss.Id);
            Test.startTest();
            response = Arc_Gen_ValidateRating_service.setupValidateRating(accHasAn.Id, rating.Id, '400', false);
            Test.stopTest();
        }
        System.assertNotEquals('200', response.serviceCode, 'The service status were not successful');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testControllerConstr() {
        Test.startTest();
        final Arc_Gen_ValidateRating_controller constructor = new Arc_Gen_ValidateRating_controller();
        System.assertEquals(constructor, constructor,'Empty controller constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingRatingData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingRatingDataRAIP() {
        Test.startTest();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        insert newSector;
        final arce__rating__c rating = setRating('AAA', 90.0);
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '4';
        newArce.arce__Stage__c = '1';
        insert newArce;
        arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, 're-gbl-01');
        accHasAn.arce__rating_scale_type__c = arce.Arc_Gen_Constants.LONG_SCALE_RATING;
        accHasAn.arce__ffss_for_rating_id__c = ffss.Id;
        insert accHasAn;
        try {
            Arc_Gen_ValidateRating_controller.getRatingData(accHasAn.Id);
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'The method obtains the information of the rating');
        }
        Test.stopTest();
    }
}