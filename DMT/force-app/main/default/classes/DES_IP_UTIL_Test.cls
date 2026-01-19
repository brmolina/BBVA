/**
*
* @author Global Desktop
*/
public class DES_IP_UTIL_Test { //NOSONAR

  public static DES_UtilTestClass util = new DES_UtilTestClass();

  public Id visitIPRecordTypeId {
    get{
      if ( visitIPRecordTypeId == null ) {
        visitIPRecordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get('PrivilegedAccountVisit').getRecordTypeId();
      }
      return visitIPRecordTypeId;
    }
    set;
  }

  public Id oppIPRecordTypeId {
    get{
      if ( oppIPRecordTypeId == null ) {
        oppIPRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Privileged Opportunity').getRecordTypeId();
      }
      return oppIPRecordTypeId;
    }
    set;
  }

  public Id bussOppRecordTypeId {
    get{
      if ( bussOppRecordTypeId == null ) {
        bussOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId();
      }
      return bussOppRecordTypeId;
    }
    set;
  }

  public Map<String, User> usersByUsername {
    get {
      if ( usersByUsername == null ) {
        usersByUsername = new Map<String, User>();
        Set<String> userNames = new Set<String>{
            'ownertest@bbvatest.test',
            'fictionusertest@bbvatest.test',
            'managerusertest@bbvatest.test',
            'globalbankertest@bbvatest.test',
            'industryusertest@bbvatest.test'
        };
        for ( User user : [ SELECT Id, Username, Profile.Id, Profile.Name, FederationIdentifier FROM User WHERE Username IN :userNames ] ){
          usersByUsername.put( user.Username, user );
        }
      }
      return usersByUsername;
    }
    set;
  }

  public Map<String, Account> clientsByName {
    get {
      if ( clientsByName == null ){
        clientsByName = new Map<String, Account>();
        Set<String> clientsName = new Set<String>{
            'clientTest',
            'non - disclosed'
        };
        for ( Account account: [ SELECT Id, Name, DES_ID_Fiscal__c, RecordType.Name FROM Account WHERE Name IN :clientsName ] ){
          clientsByName.put( account.Name, account );
        }
      }
      return clientsByName;
    }
    set;
  }

  /**
   * Crear los usuarios necesarios para el Test
   */
  private void createUsers () {

    List<User> usersToInsert = new List<User>();

    UserRole userRole = [SELECT Id FROM UserRole WHERE Name = 'GLOBAL CLIENTS Management'].get(0);

    // Owner User
    User ownerUser = util.createUserWithProfileName( 'BBVA Desktop GCC Standard', 'ownertest@bbvatest.test' );
    ownerUser.ID_User__c = 'owneruserid';
    ownerUser.FederationIdentifier = 'owneruserid';
    ownerUser.CommunityNickname = 'ownertest@bbvatest.test';
    ownerUser.UserRoleId = userRole.Id;

    usersToInsert.add( ownerUser );

    // Fiction User
    User fictionUser = util.createUserWithProfileName( 'BBVA Desktop GCC Standard', 'fictionusertest@bbvatest.test' );
    fictionUser.ID_User__c = 'fictionuserid';
    fictionUser.FederationIdentifier = 'fictionuserid';
    fictionUser.CommunityNickname = 'fictionusertest@bbvatest.test';

    usersToInsert.add( fictionUser );

    UserRole managerRole = [SELECT Id, Name FROM UserRole WHERE Name = 'GCC-IBF-GM-GTB-Desktop Management'];

    // Manager User
    User managerUser = util.createUserWithProfileName( 'BBVA Desktop GCC Standard', 'managerusertest@bbvatest.test' );
    managerUser.ID_User__c = 'manageruserid';
    managerUser.FederationIdentifier = 'manageruserid';
    managerUser.CommunityNickname = 'managerusertest@bbvatest.test';
    managerUser.UserRoleId = managerRole.Id;

    usersToInsert.add( managerUser );

    // Industry Head
    User industryHeadUser = util.createUserWithProfileName( 'BBVA Desktop GCC Standard', 'industryusertest@bbvatest.test' );
    industryHeadUser.ID_User__c = 'industryuserid';
    industryHeadUser.FederationIdentifier =  'industryuserid';
    industryHeadUser.CommunityNickname = 'industryusertest@bbvatest.test';
    ownerUser.UserRoleId = userRole.Id;

    usersToInsert.add( industryHeadUser );

    // Global Banker
    User globalBankerUser = util.createUserWithProfileName( 'BBVA Desktop GCC Standard', 'globalbankertest@bbvatest.test' );
    globalBankerUser.ID_User__c = 'globaluserid';
    globalBankerUser.FederationIdentifier =  'globaluserid';
    globalBankerUser.CommunityNickname = 'globalbankertest@bbvatest.test';

    usersToInsert.add( globalBankerUser );

    insert usersToInsert;

  }

  class ObjectPermissionsAccess {

    Boolean permissionsRead = false;
    Boolean permissionsEdit = false;
    Boolean permissionsCreate = false;
    Boolean permissionsViewAll = false;

  }

  class TestPermissionSet {

    PermissionSet  ps;

    TestPermissionSet ( String permissionSetName ) {

      ps = new PermissionSet( Name = permissionSetName, Label = permissionSetName );
      insert ps;

    }

    void createObjectPermissionSet( Map<String, ObjectPermissionsAccess> accessBySObject ) {

      List<ObjectPermissions> ops = new List<ObjectPermissions>();
      for ( String sObjectName: accessBySObject.keySet() ) {
        ops.add( new ObjectPermissions(

            ParentId = ps.Id,
            SobjectType = sObjectName,
            PermissionsRead = accessBySObject.get( sObjectName ).permissionsRead,
            PermissionsEdit = accessBySObject.get( sObjectName ).permissionsEdit,
            PermissionsCreate = accessBySObject.get( sObjectName ).permissionsCreate,
            PermissionsViewAllRecords = accessBySObject.get( sObjectName ).permissionsViewAll

        ));
      }

      insert ops;

    }

    void assignPermissionSetsToUsers ( List<Id> userIds ) {

      List<PermissionSetAssignment> psa  = new List<PermissionSetAssignment>();
      for ( Id userId: userIds ) {
        psa.add( new PermissionSetAssignment (
            PermissionSetId = ps.Id,
            AssigneeId = userId
        ));
      }

      insert psa;

    }

  }

  /**
   * Crear los clientes necesarios para el Test
   */
  private void createClients () {

    // Crear el cliente ficticio
    final String nonDisclosedName = 'non - disclosed';

    Account nonDisclosed = util.createClient();
    nonDisclosed.Name = nonDisclosedName;

    Map<String, User> usersByTeamRole = new Map<String, User>();
    usersByTeamRole.put( 'Global Banker', usersByUsername.get ( 'globalbankertest@bbvatest.test' ) );
    usersByTeamRole.put( 'Industry Head', usersByUsername.get( 'industryusertest@bbvatest.test' ) );

    final String clientTestName = 'clientTest';
    Account clientTest;
    clientTest = util.createClient( clientTestName, 'IDF - ' + clientTestName, usersByTeamRole );

  }

  public DES_IP_UTIL_Test () {

  }

  public void init () {

    // Para evitar DML Mixed Exception, las operaciones sobre objeto de setup las realizamos bajo runAs
    System.runAs( new User ( Id = UserInfo.getUserId() ) ) {
      createUsers();
      TestPermissionSet tps = new TestPermissionSet( 'TestPS' );
      ObjectPermissionsAccess pas = new ObjectPermissionsAccess();
      pas.permissionsRead = true;
      pas.permissionsViewAll = true;
      tps.createObjectPermissionSet( new Map<String, ObjectPermissionsAccess> { 'Account' => pas } );
      tps.assignPermissionSetsToUsers( new List<Id> {
          usersByUsername.get( 'ownertest@bbvatest.test' ).Id,
          usersByUsername.get( 'managerusertest@bbvatest.test' ).Id,
          usersByUsername.get( 'fictionusertest@bbvatest.test' ).Id,
          usersByUsername.get( 'globalbankertest@bbvatest.test' ).Id,
          usersByUsername.get( 'industryusertest@bbvatest.test' ).Id
      } );
    }

    createClients();
    Product2 testProduct = util.createProduct( 'TestProduct' ); // GTB Family
    insert testProduct;
    insert util.createPricebookEntry(testProduct);

  }

}