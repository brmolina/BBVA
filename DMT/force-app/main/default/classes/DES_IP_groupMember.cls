/**
* Clase controladora para flujo IP y grupos
*
**/
public without sharing class DES_IP_groupMember {

  /*
  *   Constructor de clase sin argumentos
  *
  **/
  private DES_IP_groupMember() {
    System.debug('DES_IP_groupMember');
  }

  /*
  * Variable para literal 'Manual'
  */
  private static String  modeManual = 'Manual';

  /*
  * Variable para literal 'Edit'
  */
  private static String  modeEdit = 'Edit';

  /*
  * Entrada del method invocable addMemberGroup
  */
  public class IpMemberGroup {
    /**
     * Id del grupo
     */
    @InvocableVariable(label='idGroup' required=false)
    public Id idGroup; //NOSONAR
    /**
     * Id del usuario
     */
    @InvocableVariable(label='idUser' required=false)
    public Id idUser; //NOSONAR

    /**
     * Id del registro relacionado con el grupo
     */
    @InvocableVariable(label='recordId' required=false)
    public Id recordId; //NOSONAR

    /**
     * operacion
     */
    @InvocableVariable(label='operation' required=false)
    public String operation; //NOSONAR

  }

  /*
  * Gestiona miembros/grupos
  *
  */
  @InvocableMethod(label='MemberGroup' description='Member to group')
  public static void memberToGroup(list<IpMemberGroup> mgList) {
    final IpMemberGroup ipGroup = mgList[0];
    switch on ipGroup.operation {

      when 'delete' {
        deleteMember(ipGroup.idGroup, ipGroup.idUser);
      }
      when 'deleteGroup' {
        deleteGroup(ipGroup.idGroup);
      }
      when 'createGroup' {


        Id groupId;
        System.debug('****************** Antes de crear registro Opportunity Share');
        System.debug('****************** ipGroup.recordId: ' + ipGroup.recordId + '\r\nUserOrGroupId: ' + groupId);

        useFictionOwner( ipGroup.recordId, ipGroup.idUser );
        try {
          groupId = createGroup( ipGroup.recordId );
          final OpportunityShare oppShare = new OpportunityShare(
              OpportunityId = ipGroup.recordId,
              OpportunityAccessLevel = modeEdit,
              RowCause = modeManual,
              UserOrGroupId = groupId
          );
          insert oppShare;
          System.debug('****************** id de la oppShare insertada: ' + oppShare.id);
        } catch (Exception ex) {
          System.debug('****************** Exception: ' + ex.getMessage());
          throw ex;
        }
        addMember( groupId, ipGroup.idUser);
      }
      when 'createGroupNF' {

        //Id groupId = createGroup( ipGroup.recordId );
        useFictionOwner( ipGroup.recordId, ipGroup.idUser );
        final OpportunityShare oppShare = new OpportunityShare(

            OpportunityId = ipGroup.recordId,
            OpportunityAccessLevel = modeEdit,
            RowCause = modeManual,
            UserOrGroupId = createGroup( ipGroup.recordId )

        );
        insert oppShare;
      }
      when 'addMemberNF' {
        addMemberNF( ipGroup.recordId, ipGroup.idUser );
      }
      when else {
        addMember(ipGroup.idGroup, ipGroup.idUser);
      }
    }
  }

  /**
   * Crea el grupo y lo asocia con la oportunidad y con el formulario, y cambia el Owner real por el usuario ficticio
   *
   * @param recordId
   * @param userId
   */
  @AuraEnabled
  public static void preparePrivateOpportunity ( Id recordId, Id userId, Id formId) {

    try {

      final Id groupId = createGroup( recordId );
      useFictionOwner( recordId, userId);
      final OpportunityShare oppShare = new OpportunityShare(

          OpportunityId = recordId,
          OpportunityAccessLevel = modeEdit,
          RowCause = modeManual,
          UserOrGroupId = groupId

      );
      insert oppShare;

      final Inside_information_form__Share formShare = new Inside_information_form__Share(

          ParentId = formId,
          AccessLevel = modeEdit,
          RowCause = modeManual,
          UserOrGroupId = groupId

      );
      insert formShare;

    } catch (Exception e) {

      throw new AuraHandledException(Label.DES_IP_ERROR + e);

    }


  }

  /**
   * Cambia el Owner por el usuario con name = 'non - disclosed', y oculta el owner original
   *
   * @param recordId Id de la oportunidad
   * @param userId Id del Owner de la oportunidad
   */
  public static void useFictionOwner ( Id recordId, Id userId ) {

    final User fictionUser = [SELECT Id FROM User WHERE Name = 'non - disclosed' LIMIT 1];

    update new Opportunity(
        Id = recordId,
        operation_privileged_user_name__c = userId,
        OwnerId = fictionUser.Id
    );

  }

  /**
  * Añadir miembro a grupo
  */
  @future
  public static void addMember(Id groupId, Id userId) {

    GroupMember gMember;
    gMember = new GroupMember();
    gMember.GroupId = groupId;
    gMember.UserOrGroupId = userId;
    insert gMember;

  }

  /**
  * Añadir miembro a grupo, metodo futuro
  */
  @future
  public static void addMemberFt ( Id recordId, Id userId ) {

    addMemberNF( recordId, userId );

  }

  /**
  * Añadir miembro a grupo por registro
  */
  @AuraEnabled
  public static void addMemberNF( Id recordId, Id userId ) {

    try {

      final Group currentGroup = [SELECT Id FROM Group WHERE Name = :recordId LIMIT 1];

      GroupMember gMember;
      gMember = new GroupMember();
      gMember.GroupId = currentGroup.Id;
      gMember.UserOrGroupId = userId;
      insert gMember;

    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }

  }

  /**
  * Elimina miembro de grupo
  */
  @future
  public static void deleteMember(Id groupId, Id userId) {
  	system.debug('Valor de groupId: ' +groupId);
  	system.debug('Valor de userId: ' +userId);
    final List <GroupMember> groupList = new List<GroupMember>([
        SELECT Id
        FROM GroupMember
        WHERE UserOrGroupId = :userId and
        GroupId = :groupId
    ]);

    GroupMember gMember;
    if(!groupList.isEmpty()) {
      gMember = new GroupMember();
      gMember.Id = groupList[0].Id;
      delete gMember;
    }
  }

  /**
  * Elimina un grupo
  */
  @future
  public static void deleteGroup(Id groupId) {
    Group gDelete;
    gDelete = new Group();
    gDelete.Id = groupId;
    delete gDelete;
  }

  /**
  * Crea un grupo
  */
  public static Id createGroup( Id recordId ) {

    final Group sharingGroup = new Group(
        DoesIncludeBosses = false,
        Name = recordId
    );

    insert sharingGroup;

    return sharingGroup.Id;

  }

}