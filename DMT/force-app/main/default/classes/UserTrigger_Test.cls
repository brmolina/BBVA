/***************************************************************************************
* @author       BBVA
* @date         17-06-2020
* @description  Class to test UserTrigger.

****************************************************************************************/
@isTest
@SuppressWarnings('sf:TooManyMethods')
private class UserTrigger_Test {

  /**CONSTANTE 'EUROPE'*/
  public static final String EUROPE = 'Europe/London';
    /**CONSTANTE 'UTF8'*/
  public static final String UTF8 = 'UTF-8';

  /*
  * String
  */
  static final String USERNAME = 'test2@tested.test';

  /*
  * String
  */
  static final String LASTNAME = 'LastNameTest2';

  /*
  * String
  */
  static final String EMAIL = 'Alias2@accenture.com';

  /*
  * String
  */
  static final String ALIAS = 'Alias2';

  /*
  * String
  */
  static final String IDUSER = 'SampleUserID';

  /*
  * String
  */
  static final String IDUSER2 = 'SampleUserID2';

/**
    *@Author: Global Desktop
    *Description: UserLogicassign.PermissionSet
    */
    @isTest
    public static void UserLogicassignPermissionSet() {
        Test.startTest();
        PermissionSet ps = [SELECT Id FROM PermissionSet limit 1];
        List<User> lstUsers=[select id from user limit 3];
        Set<Id> setUser=new Set<Id>();
        for(Integer i=0;i<lstUsers.size();i++) { 
           setUser.add(lstUsers[i].id);
        }
        UserLogic.assignPermissionSet(ps.Id,setUser);
        UserLogic.assignPermissionSet(ps.Id,setUser);

        Test.stopTest();
        System.assertNotEquals(setUser,null);

    }

    /**
    *@Author: Global Desktop
    *Description: INsert
    */
    @isTest
    public static void insertDataloaderTest() {

      Id profileDefault = [select id from Profile where Name='Consultation IT' limit 1].id;
        Profile perfil = [select id from Profile where Name='Consultation IT' limit 1];
        System.debug('Profile: '+profileDefault);


        Test.startTest();

        User SampleUser = new User(ProfileId = perfil.Id,
                                   Username= USERNAME,
                                   Lastname=LASTNAME,
                                   Email = EMAIL,
                                   Alias = ALIAS,
                                   CommunityNickname = 'ComunityNickNameTest2',
                                   Timezonesidkey=EUROPE,
                                   Localesidkey='en_US',
                                   EmailEncodingKey = UTF8,
                                   ID_User__c = IDUSER,
                                   Languagelocalekey='en_US');


        insert SampleUser;

            SampleUser.FirstName = 'NameTest';
            update SampleUser;

            //User userNew = UnitTestUtils.GetDataloaderNewUser('ExternaIDTest','FX');
            User userNew = UnitTestUtils.GetFXSalesUser();
            insert userNew;
        Test.stopTest();



        User user1 = [Select Id, Name, ProfileId, UserRoleId From User Where Id =:SampleUser.Id limit 1];
        Id profileFX = [select id from profile where name='Consultation IT' limit 1].id;
        User user2 = [Select Id, Name, ProfileId, UserRoleId From User Where Id =:userNew.Id limit 1];
        System.assertEquals(SampleUser.ProfileId, user1.ProfileId);
        System.assertEquals(SampleUser.UserRoleId, user1.UserRoleId);

    }


    /*
    * ¡OJO! En este testMethod invoca métodos @future de la clase UserLogic, y estos métodos a veces daban problemas porque termina
    * la ejecución del testMethod y los futuros todavía no se habían ejecutado. Esto provocaba que fallaban los Assertion.
    * Parece que la cosa se soluciona simplemente añadiendo un par de "system.debug" justo antes de los Assertion, pero hay que tener cuidado
    */
    @isTest
    public static void permissionSetChatter_Test() {
      //Data needed
      Id profileDefault = [select id from Profile where Name='Consultation IT' limit 1].id;
        Profile perfil = [select id from Profile where Name='Consultation IT' limit 1];
        System.debug('Profile: '+profileDefault);

        //Test
        Test.startTest();

        User SampleUser = new User(ProfileId = perfil.Id,
                                   Username= USERNAME,
                                   Lastname=LASTNAME,
                                   Email = EMAIL,
                                   Alias = ALIAS,
                                   CommunityNickname = 'ComunityNickNameTest2',
                                   Timezonesidkey=EUROPE,
                                   Localesidkey='en_US',
                                   EmailEncodingKey = UTF8,
                                   ID_User__c = IDUSER,
                                   Languagelocalekey='en_US');


        insert SampleUser;

            SampleUser.FirstName = 'NameTest';
            SampleUser.DES_Disable_Chatter__c = true;
            update SampleUser;

            //User userNew = UnitTestUtils.GetDataloaderNewUser('ExternaIDTest','FX');
            User userNew = UnitTestUtils.GetFXSalesUser();
            userNew.DES_Disable_Chatter__c = true;
            insert userNew;

            userNew.DES_Disable_Chatter__c = false;
            update userNew;

        Test.stopTest();


        List<PermissionSetAssignment> psaList = [select Id, PermissionSetId, AssigneeId,Assignee.Username  from PermissionSetAssignment where PermissionSet.Name = :Label.DES_Name_PermissionSet_Chatter];
        List<Id> idList = new List<Id>();
        for (PermissionSetAssignment psa : psaList) {
            idList.add(psa.AssigneeId);
        }

        System.assert(!idList.contains(SampleUser.id), 'Error: method permissionSetChatter_Test first_assertion');
    }

    /**
    *@Author: Global Desktop
    *Description: group
    */
    @isTest
    public static void userToGroupsTest() {

      Test.startTest();
      DES_UtilTestClass utilTestClass = new DES_UtilTestClass();


    List<User> listaUsers = new List<User>();
    String profileTest = utilTestClass.createProfile();
    User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.Entity_name__c = 'DES_LEGAL_Entity_BBVA_PARIS;DES_LEGAL_Entity_BBVA_MADRID';
    userTest1.DES_Country__c = 'ARG';
    listaUsers.add(userTest1);

    User userTest2 = utilTestClass.createUser(profileTest);
    userTest2.Entity_name__c = 'DES_LEGAL_Entity_BBVA_PORTUGAL;DES_LEGAL_Entity_BBVA_MILAN';
    userTest2.username = 'userTest2@none1.es';
    userTest2.CommunityNickname = 'userTest2@none1.es';
    userTest2.ID_User__c = 'userTest2';
    userTest2.DES_Country__c = 'FRA';
    listaUsers.add(userTest2);

    User userTest3 = utilTestClass.createUser(profileTest);
    userTest3.Entity_name__c = 'DES_LEGAL_Entity_BBVA_DEUTSCHLAND; DES_LEGAL_Entity_BBVA_BRUSELAS_IRELAND; DES_LEGAL_Entity_BBVA_NEW_YORK';
    userTest3.username = 'userTest3@none2.es';
    userTest3.CommunityNickname = 'userTest3@usertest3@none.es.es';
    userTest3.ID_User__c = 'userTest3';
    userTest3.DES_Country__c = 'ESP';
    listaUsers.add(userTest3);

    User userTest4 = utilTestClass.createUser(profileTest);
    userTest4.Entity_name__c = 'DES_LEGAL_Entity_BBVA_TAIPEI_TP_DBU';
    userTest4.username = 'userTest4@none2.es';
    userTest4.CommunityNickname = 'userTest4@none2.es';
    userTest4.ID_User__c = 'userTest4';
    userTest4.DES_Country__c = 'ESP';
    listaUsers.add(userTest4);

    system.debug('>>>>> ANTES userTest1.DefaultCurrencyIsoCode: ' + userTest1.DefaultCurrencyIsoCode);
    insert listaUsers;
    system.debug('>>>>> DESPUES userTest1.DefaultCurrencyIsoCode: ' + userTest1.DefaultCurrencyIsoCode);



    listaUsers.get(2).Entity_name__c = 'DES_LEGAL_Entity_BBVA_DEUTSCHLAND; DES_LEGAL_Entity_BBVA_BRUSELAS_IRELAND';

    update listaUsers.get(2);


    userTest1 = [SELECT id, Entity_name__c FROM User WHERE id = :listaUsers.get(2).id];
    System.assertEquals(listaUsers.get(2).Entity_name__c, 'DES_LEGAL_Entity_BBVA_DEUTSCHLAND; DES_LEGAL_Entity_BBVA_BRUSELAS_IRELAND', 'Error');

    Test.stopTest();
    }


    /**
    *@Author: Global Desktop
    *Description: Deleted
    */
    @isTest
    public static void setDeleteGroup() {
      DES_UtilTestClass utilTestClass = new DES_UtilTestClass();


      CIB_Bypass__c bypass = new CIB_Bypass__c(CIB_DES_skip_trigger_in_denorm__c = true);
      upsert bypass;

      String profileTest = utilTestClass.createProfile();
      User userTest = utilTestClass.createUser(profileTest);
      insert userTest;
      CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();

      insert userSettings;

      system.runAs(userTest) {
        Group gggb = new Group();
        gggb.Name = 'DES_LEGAL_Entity_BBVA_NEW_YORK2';
        gggb.DeveloperName = 'DES_LEGAL_Entity_BBVA_NEW_YORK2';
        insert gggb;
        List<User> listaUsersb = new List<User>();
        User userTest1b = utilTestClass.createUser(profileTest);
        userTest1b.username = 'userTest1@none.es';
        userTest1b.CommunityNickname = 'userTest1@none.es';
        userTest1b.ID_User__c = 'userTest1';
        userTest1b.Entity_name__c = 'DES_LEGAL_Entity_BBVA_NEW_YORK2;DES_LEGAL_Entity_BBVA_NEW_YORK2';
        listaUsersb.add(userTest1b);

        User userTest2b = utilTestClass.createUser(profileTest);
        userTest2b.Entity_name__c = 'DES_LEGAL_Entity_BBVA_NEW_YORK2';
        userTest2b.username = 'userTest2@none.es';
        userTest2b.CommunityNickname = 'userTest2@none.es';
        userTest2b.ID_User__c = 'userTest2';
        listaUsersb.add(userTest2b);

        User userTest3b = utilTestClass.createUser(profileTest);
        userTest3b.Entity_name__c = 'BBVA-MADRID-TESORERIA';
        userTest3b.username = 'userTest3@none1.es';
        userTest3b.CommunityNickname = 'userTest3@none1.es';
        userTest3b.ID_User__c = 'userTest3';
        listaUsersb.add(userTest3b);

        User userTest4b = utilTestClass.createUser(profileTest);
        userTest4b.Entity_name__c = 'BBVA-MADRID-TESORERIA;BBVA-MADRID-TESORERIA';
        userTest4b.username = 'userTest4@none1.es';
        userTest4b.CommunityNickname = 'userTest4@none1.es';
        userTest4b.ID_User__c = 'userTest4';
        listaUsersb.add(userTest4b);

        insert listaUsersb;


        Test.startTest();
          update listaUsersb;

          System.assertEquals([SELECT id, UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId = :userTest1b.id].GroupId, gggb.Id, 'Error');

        Test.stopTest();
      }
    }

    /**
    *   @author: Global Desktop
    */
    @isTest
    public static void logicCopySPUsertoGroup() {
      final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
      final Profile profileSP = [SELECT Id FROM Profile WHERE Name LIKE '%Desktop SP%' LIMIT 1];
      final Profile profBBVAGCCStd = [SELECT Id FROM Profile WHERE Name LIKE '%Desktop GCC Standard%' LIMIT 1];

      Test.startTest();
      User userSP;
      userSP = utilTestClass.createUser((String)profileSP.Id, 'userProfSP@none.es');
      insert userSP;

      User userUpdSP;
      userUpdSP = utilTestClass.createUser((String)profBBVAGCCStd.Id, 'userSPUpd@none.es');
      insert userUpdSP;

      userUpdSP.ProfileId = profileSP.Id;
      update userUpdSP;

      userUpdSP.ProfileId = profBBVAGCCStd.Id;
      update userUpdSP;

      Test.stopTest();
      System.assertEquals(userUpdSP.ProfileId, profBBVAGCCStd.Id, 'Error');

    }

    /**
    *@Author: Global Desktop
    *Description: Deleted
    */
    @isTest
    public static void assignAmbit() {
      final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

      final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
        SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c
        FROM Arce_ambit_hierarchy__mdt
      ]);
      String ambit1 = '';
      String ambit2 = '';
      String ambit3 = '';
      for(Arce_ambit_hierarchy__mdt ambit : ambitMetadatas) {
        if(ambit.canRead__c && ambit.canEdit__c) {
          ambit1 = ambit.Region__c + ' - ' + ambit.Level__c + (ambit.Description__c == null || ambit.Description__c == '' ? ' -' : ' - ' + ambit.Description__c);
        } else if(!ambit.canRead__c && !ambit.canEdit__c) {
          ambit2 = ambit.Region__c + ' - ' + ambit.Level__c + (ambit.Description__c == null || ambit.Description__c == '' ? ' -' : ' - ' + ambit.Description__c);

        }
      }
      system.debug('** -> ambit1 ' + ambit1);
      String profileTest = utilTestClass.createProfile();
      final User userTest1 = utilTestClass.createUser(profileTest);
      userTest1.gf_user_operation_ambit_name__c = ambit1;
      insert userTest1;
      userTest1.gf_user_operation_ambit_name__c = ambit2;
      update userTest1;
      system.assertNotEquals(null, userTest1.gf_user_operation_ambit_name__c, 'usernotinserted');
    }

    /**
    * Test para checks de creación de usuario de eSales
     */
    @isTest
    public static void assignECommercePermissionSetByRoleTest() {

      Test.startTest();

      Final Id perfil = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop GM Click To Dial' LIMIT 1].Id;
      Final List<UserRole> usrRole = [SELECT id FROM UserRole WHERE Name='GLOBAL MARKETS E-COMMERCE' OR Name ='GLOBAL MARKETS ECOMMERCE SALES' LIMIT 2];
      Final List<User> sampleUser = new List<User>{new User(ProfileId = perfil,
                                  Username= 'test2@tested.test1',
                                  Lastname='LastNameTest3',
                                  Email = EMAIL,
                                  Alias = 'Alias3',
                                  CommunityNickname = 'ComunityNickNameTest1313',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[0].Id), new User(ProfileId = perfil,
                                  Username= USERNAME,
                                  Lastname=LASTNAME,
                                  Email = EMAIL,
                                  Alias = ALIAS,
                                  CommunityNickname = 'ComunityNickNameTest13',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER2,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[1].Id)};
      insert sampleUser;
      List<User> updateUsers;
      updateUsers = new List<User>();
      for(User newUser : sampleUser) {
        if(newUser.UserRoleId == usrRole[1].Id) {
          newUser.UserRoleId = usrRole[0].Id;
        } else {
          newUser.UserRoleId = usrRole[1].Id;
        }
        updateUsers.add(newUser);
      }
      update updateUsers;
      Test.stopTest();
      System.assertEquals(sampleUser[1].UserRoleId, usrRole[0].Id, 'El rol es el correcto');
    }

    /**
      * Test para checks de creación de usuario de eSales
      */
    @isTest
    public static void updateECommercePermissionSetByRoleTest() {

      Test.startTest();

      Final Id perfil = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop GM Click To Dial' LIMIT 1].Id;
      Final List<UserRole> usrRole = [SELECT id FROM UserRole WHERE Name='GLOBAL MARKETS E-COMMERCE' OR Name = 'Global Management' LIMIT 2];
      Final List<User> sampleUser = new List<User>{new User(ProfileId = perfil,
                                  Username= 'test2@tested.test1',
                                  Lastname='LastNameTest3',
                                  Email = EMAIL,
                                  Alias = 'Alias3',
                                  CommunityNickname = 'ComunityNickNameTest1313',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[0].Id), new User(ProfileId = perfil,
                                  Username= USERNAME,
                                  Lastname=LASTNAME,
                                  Email = EMAIL,
                                  Alias = ALIAS,
                                  CommunityNickname = 'ComunityNickNameTest13',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER2,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[1].Id)};
      insert sampleUser;
      List<User> updateUsers;
      updateUsers = new List<User>();
      for(User newUser : sampleUser) {
        if(newUser.UserRoleId == usrRole[1].Id) {
          newUser.UserRoleId = usrRole[0].Id;
        } else {
          newUser.UserRoleId = usrRole[1].Id;
        }
        updateUsers.add(newUser);
      }
      update updateUsers;
      Test.stopTest();
      System.assertEquals(sampleUser[1].UserRoleId, usrRole[0].Id, 'El rol es el correcto');
    }


    /**
    * Test para checks de creación de usuario de eSales
     */
    @isTest
    public static void updateECommercePermissionSetByRoleTest2() {

      Test.startTest();

      final Id perfil = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop GM Click To Dial' LIMIT 1].Id;
      final List<UserRole> usrRole = [SELECT id FROM UserRole WHERE Name ='GLOBAL MARKETS ECOMMERCE SALES' OR Name = 'Global Management' LIMIT 2];
      final List<User> sampleUser = new List<User>{new User(ProfileId = perfil,
                                  Username= 'test2@tested.test1',
                                  Lastname='LastNameTest3',
                                  Email = EMAIL,
                                  Alias = 'Alias3',
                                  CommunityNickname = 'ComunityNickNameTest1313',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[0].Id), new User(ProfileId = perfil,
                                  Username= USERNAME,
                                  Lastname=LASTNAME,
                                  Email = EMAIL,
                                  Alias = ALIAS,
                                  CommunityNickname = 'ComunityNickNameTest13',
                                  Timezonesidkey=EUROPE,
                                  Localesidkey='en_US',
                                  EmailEncodingKey = UTF8,
                                  ID_User__c = IDUSER2,
                                  Languagelocalekey='en_US',
                                  UserRoleId = usrRole[1].Id)};
      insert sampleUser;
      List<User> updateUsers;
      updateUsers = new List<User>();
      for(User newUser : sampleUser) {
        if(newUser.UserRoleId == usrRole[1].Id) {
          newUser.UserRoleId = usrRole[0].Id;
        } else {
          newUser.UserRoleId = usrRole[1].Id;
        }
        updateUsers.add(newUser);
      }
      update updateUsers;
      Test.stopTest();
      System.assertEquals(sampleUser[1].UserRoleId, usrRole[0].Id, 'El rol es el correcto');
    }

  /**
  *@Author: Global Hub
  *Description: Deleted
  */
  @isTest
  public static void assignPricewise() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final List <PermissionSet> psList = new List<PermissionSet>([
      SELECT Id, Name
      FROM PermissionSet
      WHERE name = 'Pricewise_Available'
    ]);

    final String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.gf_pricing_gtb_type__c = true;
    insert userTest1;
    final List<PermissionSetAssignment> currentAssign = new List <PermissionSetAssignment>([
      SELECT Id, PermissionSetId, AssigneeId
      FROM PermissionSetAssignment
      WHERE PermissionSetId = :psList.get(0).Id AND AssigneeId = :userTest1.Id
    ]);
    userTest1.gf_pricing_gtb_type__c = false;
    update userTest1;
    system.assertNotEquals(false, currentAssign.isEmpty(), 'usernotinserted');
  }

    @isTest
    public static void assignUserUosToDmtApproverTest() {
      loadTestDataUOS();
      User user = [SELECT Id FROM User WHERE DES_LevelUO_10__c = 'AA080134' AND LastName = 'Without Permissions'];
      System.runAs(new User(Id=UserInfo.getUserId()))
      {
        DMT_Test_DataFactory.generateApproverMemberForUserWithUOS(user.Id,'AA080134');
        GroupMember groupMember = new GroupMember();
        groupMember.UserOrGroupId = user.Id;
        groupMember.GroupId =  [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1].Id;
        insert groupMember;
      }
      update user;
      user.DES_LevelUO_10__c = 'AA080138';
      System.runAs(new User(Id=UserInfo.getUserId()))
      {
      update user;
      }
      System.assertNotEquals(user.DES_LevelUO_10__c,'AA080134','Error:Uos not changed.');
    }

    private static void loadTestDataUOS() {
      System.runAs(new User(Id=UserInfo.getUserId()))
      {
      User userTest = new User();
      userTest.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT'].Id;
      userTest.FirstName = 'User Name Test 3';
      userTest.LastName = 'Without Permissions';
      userTest.Alias = 'ATest3';
      userTest.Email = 'useremail@test.comm';
      userTest.username= String.valueof(DateTime.now().getTime()) + 'useremail3@test.comm';
      userTest.CommunityNickname = 'useremail3@test.comm';
      userTest.EmailEncodingKey = 'UTF-8';
      userTest.Timezonesidkey='Europe/London';
      userTest.Localesidkey ='en_US';
      userTest.languagelocalekey='en_US';
      userTest.ID_User__c ='iduserTest'+Integer.valueof((Math.random() * 100000000));
      userTest.DES_LevelUO_1__c='00080137';
      userTest.DES_LevelUO_2__c='00081237';
      userTest.DES_LevelUO_3__c='00080135';
      userTest.DES_LevelUO_4__c='00080136';
      userTest.DES_LevelUO_5__c='00043981';
      userTest.DES_LevelUO_6__c='00006374';
      userTest.DES_LevelUO_7__c='00025539';
      userTest.DES_LevelUO_8__c='00003906';
      userTest.DES_LevelUO_9__c='00081238';
      userTest.DES_LevelUO_10__c='AA080134';

      insert userTest;

      PermissionSet ps = [SELECT Id 
                    FROM PermissionSet 
                    WHERE Name LIKE 'DMT%' Limit 1];
      insert new PermissionSetAssignment(AssigneeId = userTest.Id, PermissionSetId = ps.Id);
      }
    }

    @isTest
  public static void testfillUserRoleByProject() {

    Test.startTest();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    List<User> finalUser = new List<User>();
    finalUser.add(userTest1);
    Database.executeBatch(new DES_BatchUpdatedPrflUsers(finalUser));
    system.assertNotEquals('DMT_Proyecto', userTest1.DMT_User_Role__c, 'User role not found');
    Test.stopTest();
    
    }
}