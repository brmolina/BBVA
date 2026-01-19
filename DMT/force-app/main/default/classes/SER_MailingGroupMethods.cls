/*------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Class to handle SER_MailingGroup objects through SER_MailingGroupTrigger

    History:
    <Date>          <Author>                <Description>
    12/07/207		Juan Carlos Terrón		Initial Version
-------------------------------------------------------------------------------------------*/
public without sharing class SER_MailingGroupMethods {
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  private SER_MailingGroupMethods() {
    System.debug('Error');
    /** comment */
  }

  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public static void validateUser(List<SER_MailingGroup__c> news) {
    final Set<Id> set_UserIDS = new Set<Id>();             //Set de Id's de los usuarios relacionados.
    /*INSERT PROCESS*/
    for(SER_MailingGroup__c mG : news) {
      if(set_UserIDS.contains(mG.SER_User__c)) {
        mG.addError(System.Label.SER_Duplicated_User_Field);
      } else {
        set_UserIDS.add(mG.SER_User__c);
      }
    }
    if(!set_UserIDS.isEmpty()) {
      final Set<Id> setAltLinkedUrs = new Set<Id>();
      for(SER_MailingGroup__c mG :
          [
            select Id,
            SER_User__c,SER_MailingGroup__c
            from SER_MailingGroup__c
            where SER_User__c in :set_UserIDS
          ]) {
        setAltLinkedUrs.add(mG.SER_User__c);
      }
      boolean notNull;
      notNull = setAltLinkedUrs != null && !setAltLinkedUrs.isEmpty();
      if(notNull) {
        for(SER_MailingGroup__c mG : news) {
          if(setAltLinkedUrs.contains(mG.SER_User__c)) {
            mG.addError(System.Label.SER_Duplicated_User_Field);

          }
        }
      }
    }
  }
  /*---------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ------------------------------------------------------------------------------------------*/
  public static void validateUser(Map<Id,SER_MailingGroup__c> newMap) {
    final Set<Id> set_UserIDS = new Set<Id>();             //Set de Id's de los usuarios relacionados.
    /*INSERT PROCESS*/
    for(SER_MailingGroup__c mG : newMap.values()) {
      if(set_UserIDS.contains(mG.SER_User__c)) {
        mG.addError(System.Label.SER_Duplicated_User_Field);
      } else {
        set_UserIDS.add(mG.SER_User__c);
      }
    }
    if(!set_UserIDS.isEmpty()) {
      final Set<Id> setAltLinkedUrs = new Set<Id>();
      for(SER_MailingGroup__c mG :
          [
            select Id,
            SER_User__c,SER_MailingGroup__c
            from SER_MailingGroup__c
            where SER_User__c in :set_UserIDS
            AND Id not in :newMap.keyset()
          ]) {
        setAltLinkedUrs.add(mG.SER_User__c);
      }
      boolean notNull;
      notNull = setAltLinkedUrs != null && !setAltLinkedUrs.isEmpty();
      if(notNull) {
        for(SER_MailingGroup__c mG : newMap.values()) {
          if(setAltLinkedUrs.contains(mG.SER_User__c)) {
            mG.addError(System.Label.SER_Duplicated_User_Field);
          }
        }
      }
    }
  }

  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Metod to validate default mailbox assigned to the mailing group, isn't allowed to set more than one default mailbox

      IN:            List<SER_MailingGroup__c>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      19/07/2017				Juan Carlos Terrón		Initial version.
  --------------------------------------------------------------------------------------*/
  public static void validateDefaultMailbox(List<SER_MailingGroup__c> news) {
    for(SER_MailingGroup__c mG : news) {
      if(String.isNotBlank(mG.SER_DefaultMailbox__c)
          && mG.SER_DefaultMailbox__c.split(';').size() > 1) {
        mG.addError(System.Label.SER_Default_Mailbox_Error);
      }
    }
  }
}