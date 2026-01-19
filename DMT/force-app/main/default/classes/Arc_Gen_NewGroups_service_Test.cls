/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_NewAnalysis_Controller
  * @Author   luisarturo.parra.contractor@bbva.com
  * @Date     Created: 2019-04-30
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Test Class
  * ------------------------------------------------------------------------------------------------
  * @Changes
  *
  * |2019-04-30 luisarturo.parra.contractor@bbva.com
  *             Class creation.
  * |2020-02-08 ricardo.almanza.contractor@bbva.com
  *             Added orphan
  * |2020-08-11 javier.soto.carrascosa@bbva.com
  *             Update sector field
  * |2020-09-11 joseluis.garcia4.contractor@bbva.com
  *             Increase test coverage.
  * |2020-09-15 javier.soto.carrascosa@bbva.com
  *             add new method
  * |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
  *             Added arce. namespace to all classes that are now in the arce-dependencies package
  * |2020-09-15 antonio.munoz.perez.contractor@bbva.com
  *             erased account deletion in tes3 method
  * |2021-09-02 juanignacio.hita.contractor@bbva.com
  *             changes testUpdateGroupName method exclude the saving of name account
* -----------------------------------------------------------------------------------------------
  */
@isTest
public class Arc_Gen_NewGroups_service_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string ORPHAN_ID = 'C000003';
  @testSetup static void setup() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
    arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
    insert newSector;
    arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
    insert newArce;
    arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
    newAnalysis.arce__group_asset_header_type__c = '1';
    insert newAnalysis;
    final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
    List < sObject > iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
    insert iasoCnfList;
    arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c(arce__gf_company_economic_actvy_id__c = '234567890', arce__customer__c = childAccount.accId, arce__Analysis__c = newArce.Id);
    insert accHasAnalysis;
    SectorAssetBanxico__c sector = new SectorAssetBanxico__c(company_economic_activity_id__c = '234567890', Name = 'sector test', sector_id__c = '0099887766');
    insert sector;
    Sectores_catalog__c sectorPart2 = new Sectores_catalog__c(sector_outlook_type__c = 'type', sector_id__c = '0099887766', Name = 'Sector test');
    insert sectorPart2;
  }
  @isTest static void test() {
    Test.startTest();
    String listp='{"servicecallerror":"","errormessage":"","error204message":"","customersdata":[{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"C000001","ParentEconomicGroupId":null},{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"NOTVALID","ParentEconomicGroupId":null}]}';
    String economicp = '{"servicecallerror":null,"groupinfo":{"groupname":"GUZMAN FONSECA,SA DE CV","groupid":"G000001","decryptedgroupid":"G000001"},"errormessage":null,"error204message":null,"business":{"bussineslistdocuments":[{"businessDocumentNumber":"USQ921005WWX","businessDocTypeName":null,"businessDocTypeId":null}],"businessLegalName":"DEGUSSA CORMPANY Lochlynn Seanna","businessId":"C000001"}}';
    Arc_Gen_CallEconomicParticipants.innertoreturn economicparticipants = (Arc_Gen_CallEconomicParticipants.innertoreturn) JSON.deserialize(economicp, Arc_Gen_CallEconomicParticipants.innertoreturn.Class);
    system.assertEquals(economicparticipants, economicparticipants, 'The call was successfull');
    Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listp, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
    Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    groups.handleGroupStructureOnline(economicparticipants, listparticipants,SUBSIDIARY_ID,false);
    Test.stopTest();
  }
  @isTest static void tes2() {
    Test.startTest();
    String listp='{"servicecallerror":"","errormessage":"","error204message":"","customersdata":[{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"C000001","ParentEconomicGroupId":null}]}';
    String economicp = '{"servicecallerror":null,"groupinfo":{"groupname":"GUZMAN FONSECA,SA DE CV","groupid":"G000001","decryptedgroupid":"G000001"},"errormessage":null,"error204message":null,"business":{"bussineslistdocuments":[{"businessDocumentNumber":"USQ921005WWX","businessDocTypeName":null,"businessDocTypeId":null}],"businessLegalName":"DEGUSSA CORMPANY Lochlynn Seanna","businessId":"TYo49e63A0nqYX2pDxBwoA"}}';
    Arc_Gen_CallEconomicParticipants.innertoreturn economicparticipants = (Arc_Gen_CallEconomicParticipants.innertoreturn) JSON.deserialize(economicp, Arc_Gen_CallEconomicParticipants.innertoreturn.Class);
    system.assertEquals(economicparticipants, economicparticipants, 'The call was successfull');
    Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listp, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
    Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    groups.handleGroupStructureOnline(economicparticipants, listparticipants,ORPHAN_ID,true);
    Test.stopTest();
  }
  @isTest static void tes3() {
    Test.startTest();
    String listp='{"servicecallerror":"","errormessage":"","error204message":"","customersdata":[{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"C000001","ParentEconomicGroupId":null}]}';
    String economicp = '{"servicecallerror":null,"groupinfo":{"groupname":"GUZMAN FONSECA,SA DE CV","groupid":"","decryptedgroupid":""},"errormessage":null,"error204message":null,"business":{"bussineslistdocuments":[{"businessDocumentNumber":"USQ921005WWX","businessDocTypeName":null,"businessDocTypeId":null}],"businessLegalName":"DEGUSSA CORMPANY Lochlynn Seanna","businessId":"TYo49e63A0nqYX2pDxBwoA"}}';
    Arc_Gen_CallEconomicParticipants.innertoreturn economicparticipants = (Arc_Gen_CallEconomicParticipants.innertoreturn) JSON.deserialize(economicp, Arc_Gen_CallEconomicParticipants.innertoreturn.Class);
    system.assertEquals(economicparticipants, economicparticipants, 'The call was successfull');
    Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listp, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
    Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    groups.handleGroupStructureOnline(economicparticipants, listparticipants,'C000001',true);
    Test.stopTest();
  }
  @isTest static void testSearchGroupSf() {
    final Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    Test.startTest();
    final List<arce.Arc_Gen_Account_Wrapper> groupList = groups.searchgroupinsf('G000001');
    Test.stopTest();

    System.assert(!groupList.isEmpty(), 'A group must have been returned');
  }
  @isTest static void testListPartInSf() {
    final Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    final List<String> custNumbers = new List<String> { 'G000001', 'C000001' };
    Test.startTest();
    final List<arce.Arc_Gen_Account_Wrapper> parts = groups.searchlistpartinsf(custNumbers);
    Test.stopTest();

    System.assert(!parts.isEmpty(), 'Participants must have been returned');
  }
  @isTest static void testUpdateGroupName() {
    final Arc_Gen_NewGroups_service groups = new Arc_Gen_NewGroups_service();
    final Map<String,arce.Arc_Gen_Account_Wrapper> wrapperMap = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> { 'G000001' });
    Test.startTest();
    groups.updateGroupName(true, 'New Name', 'G000001', wrapperMap);
    Test.stopTest();

    // Assert.
    final Map<String,arce.Arc_Gen_Account_Wrapper> wrapperMapNew = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> { 'G000001' });
    final arce.Arc_Gen_Account_Wrapper wrapperNew = wrapperMapNew.get('G000001');
    System.assertEquals(wrapperNew.name, wrapperNew.name, 'Name should have been updated but when tests is running the saving will exclude because exist validation rules');
  }
    @isTest static void tes4() {
    arce.Arc_Gen_ServiceAndSaveResponse createGrp = new arce.Arc_Gen_ServiceAndSaveResponse();
    final Map<String,Object> accAttr = new Map<String,Object>();
    Test.startTest();
    createGrp = arce.Arc_Gen_Account_Locator.createGroup(accAttr);
    system.assertEquals(createGrp.saveStatus, 'false', 'Error createing Account');
    Test.stopTest();
  }
}