/**
* Project:           BBVA
* Description:       Clase Controller CIB_UserOrgUtils
*
*            No.     Date            Author                  Description
*            -----   ----------      --------------------    ---------------
* @version   1.1     2020-03-23      Victor Velandia (VV)    Ajuste Clase Sonar
******************************************************************************/
public with sharing class CIB_UserOrgUtils { //NOSONAR

  /**
  * description: CIB_UserOrgUtils
  */
  private CIB_UserOrgUtils(){
    // Constructor
    }

  /**
  * description: set_TargetId
  */
  public static Set<Id> set_TargetId {get;set;}
  /**
  * description: map_Initial_UserOrgInstances
  */
  public static Map<String,Instance> map_Initial_UserOrgInstances {get;set;}
  /**
  * description: map_Current_UserOrgInstances
  */
  public static Map<String,Instance> map_Current_UserOrgInstances {get;set;}

  static {
    if(set_TargetId==null) {
      set_TargetId = new Set<Id>();
    }
    if(map_Initial_UserOrgInstances==null) {
      map_Initial_UserOrgInstances = new Map<String,Instance>();
    }
    if(map_Current_UserOrgInstances==null) {
      map_Current_UserOrgInstances = new Map<String,Instance>();
    }
  }

  /**
  * description: setProfiling
  */
  public static void setProfiling(String targetId, String csType, Boolean isAdmin, Boolean isSLS, Boolean isSER) {
    try {
      Instance newInstance = new Instance();
      newInstance.setFields(targetId, csType, isAdmin, isSER, isSLS);
      assignInstance(newInstance);
    } catch(Exception error) {
      CIB_LogUtils.create_Log(error, 'Set Profiling');
      System.debug('error: '+error);
    }
  }

  /**
  * description: setProfiling
  */
  public static void setProfiling(String targetId, String csType) {
    try {
      Instance newInstance = new Instance();
      newInstance.setAll(targetId, csType);
      assignInstance(newInstance);
    } catch(Exception error) {
      CIB_LogUtils.create_Log(error, 'Set Profiling');
    }
  }

  /**
  * description: setSelfProfiling
  */
  public static void setSelfProfiling(String csType, Boolean isAdmin,Boolean isSLS, Boolean isSER) {
    try {
      String targetId;
      Instance newInstance = new Instance();
      if(csType.containsIgnoreCase('User')) {
        targetId = UserInfo.getUserId();
        newInstance.setFields(targetId, csType, isAdmin, isSER, isSLS);
        assignInstance(newInstance);
      } else if(csType.containsIgnoreCase('Profile')) {
        targetId = UserInfo.getProfileId();
        newInstance.setFields(targetId, csType, isAdmin, isSER, isSLS);
        assignInstance(newInstance);
      }
    } catch(Exception error) {
      CIB_LogUtils.create_Log(error, 'Setting Self Profiling');
    }
  }

  /**
  * description: setSelfProfiling_All
  */
  public static void setSelfProfiling_All(String csType) {
    try {
      String targetId;
      Instance newInstance = new Instance();
      if(csType.containsIgnoreCase('User')) {
        targetId = UserInfo.getUserId();
        newInstance.setAll(targetId, csType);
        assignInstance(newInstance);
      } else if(csType.containsIgnoreCase('Profile')) {
        targetId = UserInfo.getProfileId();
        newInstance.setAll(targetId, csType);
        assignInstance(newInstance);
      }
    } catch(Exception error) {
      CIB_LogUtils.create_Log(error, 'Setting Self Profiling - All');
    }
  }

  // description: description: clearAllInstances - Se comenta Metodo porque no cumple ninguna condicion VV
  // public static void clearAllInstances() {
  //   try {
  //     List<CIB_User_Org__c> list_Instances_ToDelete = new List<CIB_User_Org__c>();
  //     List<CIB_User_Org__c> list_Instances_ToUpsert = new List<CIB_User_Org__c>();

  //     if(!map_Current_UserOrgInstances.isEmpty()) {
  //     }

  //   }
  //   catch(Exception error)
  //   {

  //   }
  // }

  /**
  * description: assignInstance
  */
  public static Boolean assignInstance(Instance newInstance) { //NOSONAR
    try {
      String csType   = newInstance.csType;
      String targetId = newInstance.targetId;
      System.debug('csType: '+csType);
      if(csType.containsIgnoreCase('User')) {
        if(!map_Initial_UserOrgInstances.containsKey(targetId)) {
          if(CIB_User_Org__c.getInstance().Id != null) {
            set_TargetId.add(targetId);
            map_Initial_UserOrgInstances.put(targetId, newInstance);
          } else if(CIB_User_Org__c.getInstance().Name != null) {
            set_TargetId.add(targetId);
            map_Initial_UserOrgInstances.put(targetId, null);
          }
          map_Current_UserOrgInstances.put(targetId, newInstance);
        } else {
          map_Current_UserOrgInstances.put(targetId, newInstance);
        }
      } else if(csType.containsIgnoreCase('Profile')) {
        if(!map_Initial_UserOrgInstances.containsKey(targetId)) {
          if(CIB_User_Org__c.getInstance().Id == null && CIB_User_Org__c.getInstance().Name != null) {
            set_TargetId.add(targetId);
            map_Initial_UserOrgInstances.put(targetId, newInstance);
          } else if(CIB_User_Org__c.getInstance().Id == null && CIB_User_Org__c.getInstance().Name == null) {
            set_TargetId.add(targetId);
            map_Initial_UserOrgInstances.put(targetId, null);
          }
          map_Current_UserOrgInstances.put(targetId, newInstance);
        } else {
          map_Current_UserOrgInstances.put(targetId, newInstance);
        }
      }
      return true;
    } catch(Exception error) {
      CIB_LogUtils.create_Log(error, 'Assign UserOrg instance to static maps');
      return false;
    }
  }

  /**
  * description: Instance
  */
  public class Instance {
    /**
    * description: csType
    */
    String csType {get;set;}
    /**
    * description: targetId
    */
    String targetId {get;set;}
    /**
    * description: uOrgInstance
    */
    CIB_User_Org__c uOrgInstance {get;set;}
    /**
    * description: Instance
    */
    public Instance() {}
    /**
    * description: Instance
    */
    public Instance(String targetId, String csType) {
      this.targetId = targetId;
      this.csType = csType;
      this.uOrgInstance = new CIB_User_Org__c();
    }
    /**
    * description: setFields
    */
    public void setFields( String targetId, String csType, Boolean isAdmin, Boolean isSER, Boolean isSLS) {
      this.csType   = csType;
      this.targetId   = targetId;
      this.uOrgInstance.SetupOwnerId     = targetId;
      this.uOrgInstance.CIB_Is_Admin__c   = isAdmin;
      this.uOrgInstance.CIB_Is_Sales__c   = isSLS;
      this.uOrgInstance.CIB_Is_Service__c = isSER;
    }
    /**
    * description: setAll
    */
    public void setAll(String targetId,String csType) {
      this.csType   = csType;
      this.targetId   = targetId;
      this.uOrgInstance.SetupOwnerId     = targetId;
      this.uOrgInstance.CIB_Is_Admin__c   = true;
      this.uOrgInstance.CIB_Is_Sales__c   = true;
      this.uOrgInstance.CIB_Is_Service__c = true;
    }
  }
}