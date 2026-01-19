/*-----------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to handle user level hierachy custom setting.

    History:
    <Date>          <Author>                <Description>
    16/03/2017    Juan Carlos Terrón    Initial Version.
------------------------------------------------------------------------------------*/
public without sharing class CIB_ByPassUtils {
  /* setTargetId */
  public static Set<Id> setTargetId {get;set;}
  /* initByPassInst */
  public static Map<String,Instance> initByPassInst {get;set;}
  /* currByPassInst */
  public static Map<String,Instance> currByPassInst {get;set;}
  /* Constante 'User' */
  public final static String USER = 'User';
  /* Constante 'profile' */
  public final static String PROFILE = 'profile';
  static {
    if(setTargetId==null) {setTargetId = new Set<Id>();}
    if(initByPassInst==null) {initByPassInst = new Map<String,Instance>();}
    if(currByPassInst==null) {currByPassInst = new Map<String,Instance>();}
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   Constructor privado.
  ---------------------------------------------------------------------------------------*/
  private CIB_ByPassUtils() {
    System.debug('CIB_ByPassUtils.CIB_ByPassUtils()');
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPass.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPass(
    Id targetId,
    String csType,
    Boolean skipAll,
    Boolean skipTrigger,
    Boolean skipValRule,
    Boolean skipWorkflow,
    Boolean skipAssert,
    Boolean stopJobs,
    Boolean migration) {

    Boolean response;
    response = true;
    try {
      Instance newInstance;
      newInstance = new Instance();
      newInstance.targetId = targetId;
      newInstance.csType = csType;
      newInstance.isNew = true;
      newInstance.bypassInstance = new CIB_Bypass__c();
      newInstance.assignFields(skipAll, skipTrigger,   skipValRule, skipWorkflow, skipAssert, stopJobs, migration);
      response = assignInstance(newInstance);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPassSelfUser.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPassAll(
    Id targetId,
    String csType) {

    Boolean response;
    response = true;
    try {
      Instance newInstance;
      newInstance = new Instance();
      newInstance.targetId = targetId;
      newInstance.csType = csType;
      newInstance.isNew = true;
      newInstance.bypassInstance = new CIB_Bypass__c();
      newInstance.skipAll();
      response = assignInstance(newInstance);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPassSelfUser.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPassSelfUser(
    Boolean skipTrigger,
    Boolean skipValRule,
    Boolean skipWorkflow,
    Boolean skipAssert,
    Boolean stopJobs,
    Boolean migration) {

    Boolean response;
    response = true;
    try {
      Id userId;
      userId = UserInfo.getUserId();
      enableByPass(userId, USER, false, skipTrigger, skipValRule, skipWorkflow, skipAssert, stopJobs, migration);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPassAllSelfUser.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPassAllSelfUser() {
    Boolean response;
    response = true;
    try {
      Id userId;
      userId = UserInfo.getUserId();
      enableByPassAll(userId,USER);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPassAllSelfProfile.

    IN:            Boolean skipTrigger.
    IN:            Boolean skipValRule.
    IN:            Boolean skipWorkflow.
    IN:            Boolean skipAssert.
    IN:            Boolean stopJobs.
    IN:            Boolean migration.
    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPassSelfProfile(
    Boolean skipTrigger,
    Boolean skipValRule,
    Boolean skipWorkflow,
    Boolean skipAssert,
    Boolean stopJobs,
    Boolean migration) {

    Boolean response;
    response = true;
    try {
      Id profileId;
      profileId = UserInfo.getProfileId();
      enableByPassAll(profileId,PROFILE);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   enableByPassAllSelfProfile.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean enableByPassAllSelfProfile() {
    Boolean response;
    response = true;
    try {
      Id profileId;
      profileId = UserInfo.getProfileId();
      enableByPassAll(profileId,PROFILE);
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   assignInstance.

    IN:            Instance newInstance.
    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean assignInstance(Instance newInstance) {
    try {
      String csType;
      csType = newInstance.csType;
      List<CIB_Bypass__c> byPassToUpsert;
      byPassToUpsert = new List<CIB_Bypass__c>();
      Boolean isUser;
      isUser = csType.equalsIgnoreCase(USER) || csType.containsIgnoreCase(USER);
      Boolean isProfile;
      isProfile = csType.equalsIgnoreCase(PROFILE) || csType.containsIgnoreCase(PROFILE);
      if(isUser) {
        Id userId;
        userId = newInstance.targetId;
        if(CIB_Bypass__c.getInstance(UserInfo.getUserId()) == null) {
          initByPassInst.put(userId, null);
          currByPassInst.put(userId, newInstance);
          byPassToUpsert.add(newInstance.bypassInstance);
        } else {
          if(initByPassInst.containsKey(userId)) {
            if(currByPassInst.containsKey(userId)) {
              currByPassInst.put(userId, newInstance);
              byPassToUpsert.add(newInstance.bypassInstance);
            } else {
              currByPassInst.put(userId, newInstance);
              byPassToUpsert.add(newInstance.bypassInstance);
            }
          } else {
            currByPassInst.put(userId, newInstance);
            initByPassInst.put(userId, newInstance);
            byPassToUpsert.add(newInstance.bypassInstance);
          }
        }
        System.debug('JCT - BYPASS A INSERTAR : ' + byPassToUpsert);  //NOSONAR
        if(byPassToUpsert.isEmpty() == false) {
          upsert byPassToUpsert;
        }
      } else if(isProfile) {
        Id profileId;
        profileId = newInstance.targetId;
        if(CIB_Bypass__c.getInstance(UserInfo.getProfileId()) == null) {
          initByPassInst.put(profileId, null);
          currByPassInst.put(profileId, newInstance);
          byPassToUpsert.add(newInstance.bypassInstance);
        } else {
          if(initByPassInst.containsKey(profileId)) {
            if(currByPassInst.containsKey(profileId)) {
              currByPassInst.put(profileId, newInstance);
              byPassToUpsert.add(newInstance.bypassInstance);
            } else {
              currByPassInst.put(profileId, newInstance);
              byPassToUpsert.add(newInstance.bypassInstance);
            }
          } else {
            currByPassInst.put(profileId, newInstance);
            initByPassInst.put(profileId, newInstance);
            byPassToUpsert.add(newInstance.bypassInstance);
          }
        }
        if(byPassToUpsert.isEmpty() == false) {
          upsert byPassToUpsert;
        }
      }

    } catch(Exception ex) {
      System.debug('JCT - CATCHED! : '+ex);
    }
    return false;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   clearAllInstances.

    OUT:           Boolean.
  ---------------------------------------------------------------------------------------*/
  public static Boolean clearAllInstances() {
    Boolean response;
    response = true;
    try {
      if(currByPassInst.isEmpty() == false) {
        List<CIB_Bypass__c> instancesToUps;
        instancesToUps = new List<CIB_Bypass__c>();
        List<CIB_Bypass__c> instancesToDel;
        instancesToDel = new List<CIB_Bypass__c>();
        for(Instance instance : currByPassInst.values()) {
          if(initByPassInst.get(instance.targetId) == null) {
            instancesToDel.add(instance.bypassInstance);
          } else {
            instancesToUps.add(initByPassInst.get(instance.targetId).bypassInstance);
            instancesToDel.add(instance.bypassInstance);
          }
        }
        delete instancesToDel;
        upsert instancesToUps;
      } else {
        response = false;
      }
    } catch(Exception ex) {
      response = false;
    }
    return response;
  }


/*-------------------------------------------------------------------------------
    Author:        BBVA
    Description:   Clase interna.
---------------------------------------------------------------------------------*/
  public class Instance {
    /* csType */
    String csType {get;set;}
    /* targetId */
    String targetId {get;set;}
    /* isNew */
    Boolean isNew {get;set;}
    /* bypassInstance */
    CIB_Bypass__c bypassInstance {get;set;}
    
    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   constructor publico sin argumentos.
    ---------------------------------------------------------------------------------------*/
    public Instance() {
      System.debug('CIB_ByPassUtils.Instance()');
    }

    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   constructor publico con argumentos.

      IN:            Id targetId.
      IN:            String csType.
      IN:            Boolean isNew.
    ---------------------------------------------------------------------------------------*/
    public Instance(Id targetId, String csType, Boolean isNew) {
      this.targetId = targetId;
      this.csType = csType;
      this.isNew = isNew;
    }

    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   constructor publico con argumentos.

      IN:            Id targetId.
      IN:            String csType.
      IN:            Boolean isNew.
      IN:            CIB_Bypass__c bypassInstance.
    ---------------------------------------------------------------------------------------*/
    public Instance(Id targetId, String csType, Boolean isNew, CIB_Bypass__c bypassInstance) {
      this.targetId = targetId;
      this.csType = csType;
      this.isNew = isNew;
      this.bypassInstance = bypassInstance;
    }

    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   skipFields.

      OUT:           Boolean.
    ---------------------------------------------------------------------------------------*/
    public Boolean skipAll() {
      Boolean response;
      response = false;
      try {
        response = this.assignFields(true, false, false, false, false, false, false);
      } catch(Exception ex) {
        response = false;
      }
      return response;
    }

    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   skipFields.

      IN:            Boolean skipTrigger.
      IN:            Boolean   skipValRule.
      IN:            Boolean skipWorkflow.
      IN:            Boolean skipAssert.
      IN:            Boolean stopJobs.
      IN:            Boolean migration.
      OUT:           Boolean.
    ---------------------------------------------------------------------------------------*/
    public Boolean skipFields(
      Boolean skipTrigger,
      Boolean skipValRule,
      Boolean skipWorkflow,
      Boolean skipAssert,
      Boolean stopJobs,
      Boolean migration) {

      Boolean response;
      response = false;
      try {
        response = this.assignFields(false, skipTrigger, skipValRule, skipWorkflow, skipAssert, stopJobs, migration);
      } catch(Exception ex) {
        response = false;
      }
      return response;
    }

    /*---------------------------------------------------------------------------------------
      Company:       BBVA.
      Description:   assignFields.

      IN:            Boolean skipAll.
      IN:            Boolean skipTrigger.
      IN:            Boolean skipValRule.
      IN:            Boolean skipWorkflow.
      IN:            Boolean skipAssert.
      IN:            Boolean stopJobs.
      IN:            Boolean migration.
      OUT:           Boolean.
    ---------------------------------------------------------------------------------------*/
    public Boolean assignFields(
      Boolean skipAll,
      Boolean skipTrigger,
      Boolean skipValRule,
      Boolean skipWorkflow,
      Boolean skipAssert,
      Boolean stopJobs,
      Boolean migration) {

      Boolean response;
      response = true;
      try {
        if(skipAll) {
          this.bypassInstance.SetupOwnerId = this.targetId;
          this.bypassInstance.CIB_skip_trigger__c = true;
          this.bypassInstance.CIB_skip_validationrule__c = true;
          this.bypassInstance.CIB_skip_workflow__c = true;
          this.bypassInstance.CIB_skip_assert__c = true;
          this.bypassInstance.CIB_stop_job__c = true;
          this.bypassInstance.CIB_migration__c = true;
          this.bypassInstance.CIB_skip_triggers_AP__c = true;
        } else {
          this.bypassInstance.SetupOwnerId = this.targetId;
          this.bypassInstance.CIB_skip_trigger__c = skipTrigger;
          this.bypassInstance.CIB_skip_validationrule__c = skipValRule;
          this.bypassInstance.CIB_skip_workflow__c = skipWorkflow;
          this.bypassInstance.CIB_skip_assert__c = skipAssert;
          this.bypassInstance.CIB_stop_job__c = stopJobs;
          this.bypassInstance.CIB_migration__c = migration;
          this.bypassInstance.CIB_skip_triggers_AP__c = true;
        }
      } catch (Exception ex) {
        response = false;
      }
      return response;
    }
  }
}