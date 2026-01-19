/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 19-05-2022
 * @last modified by  : Global Desktop
**/
@isTest
public with sharing class GlobalBankerClientsControllerTest {
    /**
    * @description
    * @author Global Desktop | 19-05-2022
    **/
    @isTest
    static void fetchAcctsTest() {
      final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

      final String profileTest = utilTestClass.createProfile();
      final List<User> usersToInsert = new List<User>();
      final User runningUser = utilTestClass.createUserWithProfileName('Desktop Integration', 'runningUser@bbvatest.test');
      usersToInsert.add(runningUser);

      final User userTest1 = utilTestClass.createUser(profileTest);
      userTest1.ID_User__c = 'userTest1';
      usersToInsert.add(userTest1);

      insert usersToInsert;

      system.runAs(runningUser) {
      // create a CIB group
        Account accGroup = utilTestClass.createClient();
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accGroup.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
        accGroup.DES_Group_Code__c = 'accGroup';
        insert accGroup;

        DES_BBVA_Management_team__c oBBVAMt = utilTestClass.createBBVAManagementTeamMember(userTest1, accGroup);
        oBBVAMt.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        oBBVAMt.DES_Clave_Externa__c = 'accGroup-Transaction Banker';
        insert oBBVAMt;
      }

      final DES_BBVA_Management_team__c oBBVAMT1 = [SELECT Id, DES_Member_Role__c
        FROM DES_BBVA_Management_team__c
        WHERE DES_Clave_Externa__c = 'accGroup-Transaction Banker'
        LIMIT 1];

        String respuesta = GlobalBankerClientsController.fetchAccts(oBBVAMT1.Id);

      system.debug('++ -> ' + respuesta);
      system.assert(respuesta != null, true);
    }
}