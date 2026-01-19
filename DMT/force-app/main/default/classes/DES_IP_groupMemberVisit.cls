public without sharing class DES_IP_groupMemberVisit {
	  /*
	  * Entrada del metodo invocable addMemberGroup
	  */
	  public class IpVisitMemberGroup {
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

	  @InvocableMethod(label='MemberGroupVisit' description='Member to group')
	  public static void memberToGroup(list<IpVisitMemberGroup> mgList) {
		IpVisitMemberGroup ipGroup = mgList[0];
	    switch on ipGroup.operation {

	      when 'delete' {
	        deleteMember(ipGroup.idGroup, ipGroup.idUser);
	      }
	      when 'deleteGroup' {
	        deleteGroup(ipGroup.idGroup);
	      }
	      when 'createGroup' {


	        final Id groupId = createGroup( ipGroup.recordId );
	        System.debug('****************** Antes de crear registro Visit Share');
	        System.debug('****************** ipGroup.recordId: ' + ipGroup.recordId + '\r\nUserOrGroupId: ' + groupId);

	        useFictionOwner( ipGroup.recordId, ipGroup.idUser );
	        try {
	        	dwp_kitv__Visit__Share  visitShare = new dwp_kitv__Visit__Share (
	        		ParentId = ipGroup.recordId,
	        		AccessLevel = 'Edit',
	        		RowCause = 'Manual',
	        		UserOrGroupId = groupId
	          );
	          insert visitShare;
	          System.debug('****************** id de la oppShare insertada: ' + visitShare.id);
	        }catch (Exception ex){
	          System.debug('****************** Exception: ' + ex.getMessage());
	          throw ex;
	        }
	        addMember( groupId, ipGroup.idUser, ipGroup.recordId );
	      }
	      when 'createGroupNF' {

	        final Id groupId = createGroup( ipGroup.recordId );
	        useFictionOwner( ipGroup.recordId, ipGroup.idUser );
	        dwp_kitv__Visit__Share visitShare = new dwp_kitv__Visit__Share(

	        	ParentId = ipGroup.recordId,
		        AccessLevel = 'Edit',
		        RowCause = 'Manual',
		        UserOrGroupId = groupId

	        );
	        insert visitShare;
	      }
	      when 'addMemberNF' {
	        addMemberNF( ipGroup.recordId, ipGroup.idUser );
	      }
          when 'closeVisit' {
          	changeOwnerClient(ipGroup.recordId);
          }
	      when else {
	        addMember(ipGroup.idGroup, ipGroup.idUser, ipGroup.recordId);
	      }
	    }
	  }

	  /**
	   * Crea el grupo y lo asocia con la oportunidad, y cambia el Owner real por el usuario ficticio
	   *
	   * @param recordId
	   * @param userId
	   */
	  @AuraEnabled
	  public static void preparePrivateVisit ( Id recordId, Id userId, Id formId) {

	    try {

	      final Id groupId = createGroup( recordId );
	      useFictionOwner( recordId, userId);
	      dwp_kitv__Visit__Share visitShare = new dwp_kitv__Visit__Share(

		        	ParentId = recordId,
			        AccessLevel = 'Edit',
			        RowCause = 'Manual',
			        UserOrGroupId = groupId

		        );
		  insert visitShare;

		  Inside_information_form__Share formShare = new Inside_information_form__Share(

			ParentId = formId,
			AccessLevel = 'Edit',
			RowCause = 'Manual',
			UserOrGroupId = groupId

		);
		insert formShare;

	    } catch (Exception e) {

	      throw e;

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

	    update new dwp_kitv__Visit__c (
	        Id = recordId,
	        visit_privileged_user_name__c = userId,
	        OwnerId = fictionUser.Id
	    );

	  }

	  @future
	  public static void addMember(Id groupId, Id userId, Id recordId) {

	    GroupMember gm = new GroupMember();
	    gm.GroupId = groupId;
	    gm.UserOrGroupId = userId;
	    insert gm;

	  }

	  @future
	  public static void addMemberFt ( Id recordId, Id userId ) {

	    addMemberNF( recordId, userId );

	  }

	  @AuraEnabled
	  public static void addMemberNF( Id recordId, Id userId ) {

	    try {

	      Group currentGroup = [SELECT Id FROM Group WHERE Name = :recordId LIMIT 1];

	      GroupMember gm = new GroupMember();
	      gm.GroupId = currentGroup.Id;
	      gm.UserOrGroupId = userId;
	      insert gm;

	    } catch (Exception e) {
	      throw e;
	    }

	  }

	  @future
	  public static void deleteMember(Id groupId, Id userId) {
	    final List <GroupMember> groupList = new List<GroupMember>([
	        SELECT Id
	        FROM GroupMember
	        WHERE UserOrGroupId = :userId and
	        GroupId = :groupId
	    ]);

	    GroupMember gm = new GroupMember();
	    gm.Id = groupList[0].Id;
	    delete gm;
	  }

	  @future
	  public static void deleteGroup(Id groupId) {
	    Group gm = new Group();
	    gm.Id = groupId;
	    delete gm;
	  }

	  public static Id createGroup( Id recordId ) {

	    Group sharingGroup = new Group(
	        DoesIncludeBosses = false,
	        Name = recordId
	    );

	    insert sharingGroup;

	    return sharingGroup.Id;

	  }

	 /**
	   * Cambia el Owner por el usuario con name = 'non - disclosed', y oculta el owner original
	   *
	   * @param recordId Id de la oportunidad
	   * @param userId Id del Owner de la oportunidad
	   */
	  public static void changeOwnerClient ( Id recordId) {
	
         
        final Group grupo = [Select Id,Name from Group where Name = :recordId LIMIT 1 ];
        final List<GroupMember> listgMember = [Select Id, UserOrGroupId from GroupMember where GroupId = :grupo.Id ];  
		final List<dwp_kitv__Visit__Share> listshare = new List<dwp_kitv__Visit__Share>();
      	for (GroupMember gm : listgMember) {
        	dwp_kitv__Visit__Share share = new dwp_kitv__Visit__Share();
            share.AccessLevel = 'Edit';
            share.RowCause = 'Manual';
            share.ParentId = recordId;
            share.UserOrGroupId = gm.UserOrGroupId;
            listshare.add(share);         
        }
        insert listshare;
        final dwp_kitv__Visit__Share shareGroup = [Select Id from dwp_kitv__Visit__Share where ParentId = :recordId and UserOrGroupId = :grupo.Id LIMIT 1 ];
        delete shareGroup;
        
        final dwp_kitv__Visit__c visit = [SELECT Id,visit_privileged_user_name__c, visit_prvlg_participant_id__c, OwnerId, dwp_kitv__account_id__c, disclosure_info_type__c FROM dwp_kitv__Visit__c WHERE Id = :recordId LIMIT 1];
        visit.OwnerId = visit.visit_privileged_user_name__c;
        visit.dwp_kitv__account_id__c = visit.visit_prvlg_participant_id__c;
        visit.disclosure_info_type__c = 'Confidential information';

	    update visit;  
	  }

}