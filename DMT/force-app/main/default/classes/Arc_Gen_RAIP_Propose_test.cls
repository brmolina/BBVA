/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_test
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2020-01-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_RatingAsIndepProcess_controller, Arc_Gen_RatingAsIndepProcess_service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-13 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-03-30 juanignacio.hita.contractor@bbva.com
*             Changed test RAIP propose to integrate workflow interface
* |2020-09-11 eduardoefrain.hernandez.contractor@bbva.com
*             Update test coverage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_RAIP_Propose_test {
/**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: 'Bad response' literal
    */
    static final String ASSERT_BAD_RESP = 'Bad response';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_RatingAsIndepProcess_test
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RAIP_Propose_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        final User admin = Arc_UtilitysDataTest_tst.crearUsuario('UserAdmin', System.Label.Cls_arce_ProfileSystemAdministrator, null);
        admin.ID_User__C = String.valueOf((Math.random()*100000));
        insert admin;
        System.runAs(admin) {
            Arc_UtilitysDataTest_tst.setupAcccounts();
            final Map<String,
            arce.Arc_Gen_Account_Wrapper>groupAccWrapper=arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> {GROUP_ID, GROUP_ID2, SUBSIDIARY_ID});
            final arce.Arc_Gen_Account_Wrapper groupAccount=groupAccWrapper.get(GROUP_ID);
            final arce__Sector__c newSector=Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
            insert newSector;
            final arce__Sector__c newSector2=Arc_UtilitysDataTest_tst.crearSector('re-mx-01', '100', 're-mx-01', null);
            newSector2.arce__active_type__c = true;
            newSector2.arce__rar_rating_tool_id__c = '1234567890';
            newSector2.arce__sector_analisis_type__c = '4';
            insert newSector2;
            final arce__rating__c newRating=Arc_UtilitysDataTest_tst.createRatingObj('9999999999', 'AAA', 'AAA', '2');
            insert newRating;

            final arce__Financial_Statements__c financialStatem=Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, null, newRating.Id, null);
            insert financialStatem;

            final arce__Analysis__c newArce=Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
            newArce.arce__anlys_wkfl_sub_process_type__c='4';
            newArce.ownerId=admin.Id;
            insert newArce;

            final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
                arce__PS_Successfully_Retrieved__c = true
            );
            insert ahaExt;

            final arce__Account_has_Analysis__c accHasAnalysisG=Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, 's-01');
            accHasAnalysisG.arce__group_asset_header_type__c='1';
            accHasAnalysisG.arce__InReview__c=true;
            accHasAnalysisG.arce__ffss_for_rating_id__c=financialStatem.Id;
            accHasAnalysisG.arce__RAR_rating_tool_id__c = 'test';
            accHasAnalysisG.arce__AHA_Extension__c = ahaExt.Id;
            insert accHasAnalysisG;

            final List<sObject>iasoCnfList=Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
            insert iasoCnfList;

            final SectorAssetBanxico__c sector=new SectorAssetBanxico__c(company_economic_activity_id__c='234567890', Name='sector test', sector_id__c='0099887766');
            insert sector;

            final Sectores_catalog__c sectorPart2=new Sectores_catalog__c(sector_outlook_type__c='type', sector_id__c='0099887766', Name='Sector test');
            insert sectorPart2;
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.initDelegation()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void initDelegation() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_RAIP_Propose_controller.initDelegation(accHasAnalysisG.Id);
        final Arc_Gen_Delegation_Wrapper wrapper = (Arc_Gen_Delegation_Wrapper) JSON.deserialize(response, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(200, wrapper.codStatus, 'Status of the process');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.initDelegationError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void initDelegationError() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        String response;
        final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
        try {
            response = Arc_Gen_RAIP_Propose_controller.initDelegation(accHasAnalysisG.arce__Analysis__c);
            wrapper = (Arc_Gen_Delegation_Wrapper) JSON.deserialize(response, Arc_Gen_Delegation_Wrapper.class);
        } catch (Exception ex) {
            response = ex.getMessage();
            System.debug(response);
        }
        System.assertNotEquals(200, wrapper.codStatus, 'The Status of the process is 200');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.toProposeRaip()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void toProposeRaip() {
        test.startTest();
        Map<String, Object> responseDiv = new Map<String, Object>();
        final arce__Analysis__c arceVar = [SELECT Id,ownerId FROM arce__Analysis__c LIMIT 1];
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final User usr = utils.createUser(userinfo.getProfileId());
        final User usr2 = utils.createUser(userinfo.getProfileId());
        final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
          SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
          FROM Arce_ambit_hierarchy__mdt
          LIMIT 4000
        ]);

        final Iterator<Arce_ambit_hierarchy__mdt> iter = ambitMetadatas.iterator();
        Arce_ambit_hierarchy__mdt ambit = new Arce_ambit_hierarchy__mdt();
        Boolean bool = true;
        while(iter.hasNext() && bool) {
          ambit = iter.next();
          if(ambit.Selectables__c != null) {
            bool = false;
          }
        }
        final List<String> ambitosSel = ambit.Selectables__c.split(';');

        usr.gf_user_operation_ambit_name__c = DES_Arc_GBL_Workflow_Helper.gtDescriptionAmbit(ambit.Ambit__c);
        usr.gf_user_operation_ambit_name__c = DES_Arc_GBL_Workflow_Helper.gtStringAmbit(ambit.Ambit__c);
        insert usr;

        final User useraux = [SELECT Name from User WHERE ID = :usr.ID LIMIT 1];
        final List<arce.Arc_Gen_User_Wrapper> nameUsers = DES_Arc_User_Locator.getUsers(useraux.Name);

        usr2.gf_user_operation_ambit_name__c = DES_Arc_GBL_Workflow_Helper.gtStringAmbit(ambitosSel.get(0));
        usr2.CommunityNickname = usr2.CommunityNickname+1;
        insert usr2;
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(usr.id);
        final arce.Arc_Gen_User_Wrapper wrpUserGD = DES_Arc_User_Locator.getUserInfo(usr.id);
        final String usrID = DES_Arc_GBL_Workflow_Service.getIdentification('test',arceVar.Id);

        final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'RAIP-PROPOSE',false);
        final Arc_Gen_Delegation_Wrapper wrapperTest = DES_Arc_GBL_Workflow_Service.getDelegation(wrpUserGD.ambitUser, arceVar.Id, 'RAIP-PROPOSE',false);
        system.debug(JSON.serialize(wrapperTest) + ' ' + usrID + ' ' + nameUsers + ' ' + wrapper);
        final String wrapUsrSerialized = Arc_Gen_RAIP_Propose_controller.fetchUsers(usr.gf_user_operation_ambit_name__c);
        final Arc_Gen_Delegation_Wrapper wrapperUsers = (Arc_Gen_Delegation_Wrapper) JSON.deserialize(wrapUsrSerialized, Arc_Gen_Delegation_Wrapper.class);
        responseDiv = (Map<String, Object>)JSON.deserializeUntyped(Arc_Gen_RAIP_Propose_controller.toProposeRaip(arceVar.Id, usr.gf_user_operation_ambit_name__c,wrapperUsers.lstUsers.get(0).get('value')));
        System.assertEquals('true', responseDiv.get('status'), 'The Status of the process is true');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.toProposeRaipError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void toProposeRaipError() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        Map<String, Object> response = new Map<String, Object>();
        try {
            response = (Map<String, Object>)JSON.deserializeUntyped(Arc_Gen_RAIP_Propose_controller.toProposeRaip(accHasAnalysisG.arce__Customer__c, '3', UserInfo.getUserId()));
        } catch (Exception ex) {
            response.put('status', 'false');
        }
        System.assertNotEquals('true', response.get('status'), 'Status of the process is true');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.emptyConstructors()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyControllConst() {
        Test.startTest();
        final Arc_Gen_RAIP_Propose_controller constructor = new Arc_Gen_RAIP_Propose_controller();
        System.assertEquals(constructor, constructor, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.emptyConstructors()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyServConst() {
        Test.startTest();
        final Arc_Gen_RAIP_Propose_service constructorServ = new Arc_Gen_RAIP_Propose_service();
        System.assertEquals(constructorServ, constructorServ, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.initDelegationRatingError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void initDelegationRatingError() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        final arce__rating__c rating = [SELECT Id,arce__status_type__c FROM arce__rating__c LIMIT 1];
        rating.arce__status_type__c = '1';
        update rating;
        Test.startTest();
        String response;
        final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
        try {
            response = Arc_Gen_RAIP_Propose_controller.initDelegation(accHasAnalysisG.Id);
            wrapper = (Arc_Gen_Delegation_Wrapper) JSON.deserialize(response, Arc_Gen_Delegation_Wrapper.class);
        } catch (Exception ex) {
            response = ex.getMessage();
            System.debug('Error' + response);
        }
        System.assertNotEquals(200, wrapper.codStatus, 'Status of the process is 200');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Francisco Muñoz Torres  francisco.munoz.torres.contractor@bbva.com
    * @Date     Created: 15-07-2022
    * @param void
    * @return void
    * @example Arc_Gen_RAIP_Propose_controller.getPermissionOverlay()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetPermissionOverlay() {
      Test.startTest();
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final String response = Arc_Gen_RAIP_Propose_controller.getPermissionOverlay(accHasAnalysisG.Id);
        System.assertEquals('Show', response, 'Bad response testGetPermissionOverlay');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   antonio.perez.hernandez.contractor@bbva.com
    * @Date     Created: 2024-01-04
    * @example  Arc_Gen_RAIP_Propose_controller.validateParentSubsidiary(aha.Id)
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void testValidateParentSubsidiary() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_ValidatePS.MessageResponse response = Arc_Gen_RAIP_Propose_controller.validateParentSubsidiary(aha.Id, true);
        System.assertEquals('Success', response.status , 'Expected value "Success", instead has: ' + response.status);

        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for Arc_Gen_RAIP_Propose_controller.refreshParentSubsidiary()
    * --------------------------------------------------------------------------------------
    * @Author   antonio.vazquez.aguado.next@bbva.com
    * @Date     2024-01-12
    * @example  Arc_Gen_RAIP_Propose_test.testIsRTCException();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testRefreshParentSubsidiary() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_ValidatePS.MessageResponse msgResp = Arc_Gen_RAIP_Propose_controller.refreshParentSubsidiary(aha.Id, true);
        System.assertEquals('Success', msgResp.status, Arc_Gen_ArceCore_Constants.ASSERT_BAD_RESP);
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for Arc_Gen_RAIP_Propose_controller.testIsCorporates()
    * --------------------------------------------------------------------------------------
    * @Author   antonio.vazquez.aguado.next@bbva.com
    * @Date     2024-01-12
    * @example  Arc_Gen_RAIP_Propose_test.testIsRTCException();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testIsCorporates() {
        Test.startTest();
        final String isCorpo = Arc_Gen_RAIP_Propose_controller.isCorporates();
        System.assert(String.isNotEmpty(isCorpo), ASSERT_BAD_RESP);
        Test.stopTest();
    }
}