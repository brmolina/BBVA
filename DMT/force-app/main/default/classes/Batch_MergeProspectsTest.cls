/*
* Test for Batch Merge prospect
*/
@isTest
public class Batch_MergeProspectsTest {
  /*
  * Test method
  */
  @isTest
  public static void mergeProspect() {
    String cib;
    String x1234;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();

    cib = 'C';
    x1234 = '1234';

    final Account accProspectGrupo = utilClass.createClient();
    accProspectGrupo.CIB_Commercial_Prospect__c = 'CIB';
    accProspectGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    insert accProspectGrupo;

    final Account accProspectSub = utilClass.createClient();
    accProspectSub.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    accProspectSub.DES_ID_Fiscal__c = x1234;
    accProspectSub.CIB_Commercial_Prospect__c = 'CIB';
    accProspectSub.participant_id__c = accProspectGrupo.Id;
    insert accProspectSub;

    final Contact conSub= utilClass.createContact(accProspectSub);
    insert conSub;

    final Account accGroup = utilClass.createClient();
    accGroup.DES_BBVA_Segmentation__c = cib;
    accGroup.DES_Structure_Type__c = 'Group';
    insert accGroup;

    final Account accSub = utilClass.createClient();
    accSub.DES_BBVA_Segmentation__c = cib;
    accSub.DES_Structure_Type__c = 'Subsidiary';
    accSub.DES_Entity_Type__c = 'Subsidiary';
    accSub.Merge_Insert__c = true;
    accSub.DES_ID_Fiscal__c = x1234;
    insert accSub;
      
    final Local_Client__c objLCLient=new  Local_Client__c();
    objLCLient.Name='cliente';
    objLCLient.Cib_Client__c=accSub.id;
    insert objLCLient;
      
    
    final AMH_GBL_Account_Relationship__c relationship = utilClass.createAccRelationship(accGroup, accSub);
    insert relationship;

    final User user1 = utilClass.createUser(userinfo.getProfileId());
    insert user1;
    final List<DES_BBVA_Management_team__c> members = new List<DES_BBVA_Management_team__c>();
    final DES_BBVA_Management_team__c bbvaMT = utilClass.createBBVAManagementTeamMember(user1, accSub);
    final User user2 = utilClass.createUser(userinfo.getProfileId());
    insert user2;
    final DES_BBVA_Management_team__c bbvaMT1 = utilClass.createBBVAManagementTeamMember(user2, accSub);
    members.add(bbvaMT);
    members.add(bbvaMT1);
    insert members;

    Test.startTest();
    //final Id batchInstanceId2 = Database.executeBatch(new Batch_MergeProspects(), 1);
    String batchInstanceId2 = system.schedule('Test Check', '0 0 2 * * ?', new ScheduleMergeProspects());
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId2);
    system.assertNotEquals(batchInstanceId2, null, 'not null');
    Test.stopTest();
    system.debug('accs -> ' + [SELECT Id, Name, RecordType.DeveloperName, DES_ID_Fiscal__c, DES_Main_Parent__r.Name from Account LIMIT 5]);
  }

  /*
  * Test method
  */
  @isTest
  public static void prospectHandlerClass() {
    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final Account acc = utilClass.createClient();
    acc.DES_ID_Fiscal__c = '1234';
    insert acc;
    final List <Account> accs = new List <Account>();
    final Map<String, Account> mapAccs= new Map <String, Account>();
    mapAccs.put('1234', acc);
    accs.add(acc);
    Test.startTest();
    final String aux = ProspectHandler.checkConvertedClients(accs, mapAccs);
    final String aux1 = ProspectHandler.validateNonCliente(acc);
    final String aux2 = ProspectHandler.checkDuplicateNonClients('test1','test2','test3');
    system.debug(aux1 + ' ' + aux2);
    system.assertEquals(aux, 'ok', 'ok');
    Test.stopTest();
  }
}