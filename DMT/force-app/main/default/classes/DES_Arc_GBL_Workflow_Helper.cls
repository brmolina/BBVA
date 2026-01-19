/**
* ------------------------------------------------------------------------------------------------
* @Name     DES_Arc_GBL_Workflow_Helper
* -----------------------------------------------------------------------------------------------
* @Description Class "DES_Arc_GBL_Workflow_Helper"
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidDuplicateLiterals,sf:TooManyMethods')
public with sharing class DES_Arc_GBL_Workflow_Helper {

  /**
  * @Description : Service message class
  */
  static final arce.Arc_Gen_CustomServiceMessages SERVICE_MESSAGES = new arce.Arc_Gen_CustomServiceMessages();
  static final Map<String,String> GEOGR = new Map<String,String>{'E' => 'SPAIN','C' => 'COLOMBIA','P' => 'PORTUGAL','M' => 'MEXICO', 'PE' => 'PERU','A' => 'ARGENTINA','CIB' => 'CIB','GRM' => 'HOLDING'};
  static final Map<String,String> BUSSUNIT = new Map<String,String>{'OF0' => 'BUSINESS UNIT (Local)','OF1' => 'BUSINESS UNIT (Global Banker)','R1' => 'RISK UNIT (Territorial)','R2' => 'RISK UNIT (Central)', 'R3' => 'RISK UNIT (CIB)','R4' => 'RISK UNIT (GRM)','OFC' => 'BUSINESS UNIT (Cross Border)'};

  /**
  * ----------------------------------------------------------------------------------------------------
  * @Description Void Constructor to avoid warning in sonar qube
  * ----------------------------------------------------------------------------------------------------
  * @date		11/03/2021
  * @author	Global Desktop
  * @param void
  * @return void
  * @example Arc_GBL_Workflow_Helper data = new Arc_GBL_Workflow_Helper()
  * ----------------------------------------------------------------------------------------------------
  **/
  @TestVisible
  private DES_Arc_GBL_Workflow_Helper() {
  }

  /**
  *-------------------------------------------------------------------------------
  * @description proposeRAIPAction : Propose RAIP Action
  *--------------------------------------------------------------------------------
  * @date		11/03/2021
  * @author	Global Desktop
  * @param    Arc_Gen_Delegation_Wrapper : wrapper
  * @return   Arc_Gen_Delegation_Wrapper
  * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
  */
  public static Arc_Gen_Delegation_Wrapper proposeRAIPAction(Arc_Gen_Delegation_Wrapper wrapper) {
    try {
      List<arce__Account_has_Analysis__c> aha = [Select DES_Local_Client__r.crossBorder__c from arce__Account_has_Analysis__c where arce__Analysis__c  = :wrapper.analysisId];
      wrapper.lstRegion = formatAmbit(wrapper.ambit, false, null, null,aha.get(0).DES_Local_Client__r.crossBorder__c,wrapper.validate);
      wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
    } catch (Exception e) {
      wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
      wrapper.msgInfo = 'Error Propose RAIP Action : ' + e.getMessage();
    }
    return wrapper;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description proposeAction : Propose action method
  *--------------------------------------------------------------------------------
  * @date		  16/03/2021
  * @author	  Global Desktop
  * @param    Arc_Gen_Delegation_Wrapper : wrapper
  * @return   Arc_Gen_Delegation_Wrapper
  * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
  */
  public static Arc_Gen_Delegation_Wrapper returnAction(Arc_Gen_Delegation_Wrapper wrapper) {
    try {
      wrapper.lstAmbits = formatAmbit(wrapper.ambit, true, null, null,false,false);
      wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
    } catch (Exception e) {
      wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
      wrapper.msgInfo = 'Error Return Action : ' + e.getMessage();
    }
    return wrapper;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description proposeRAIPAction : Propose RAIP Action
  *--------------------------------------------------------------------------------
  * @date		11/03/2021
  * @author	Global Desktop
  * @param    Arc_Gen_Delegation_Wrapper : wrapper
  * @return   Arc_Gen_Delegation_Wrapper
  * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
  */
  public static Arc_Gen_Delegation_Wrapper fetchUsersProposeRaip(String selectedAmbit) {
    final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
    try{
      wrapper.lstUsers = gtUsersAmbit(selectedAmbit);
      wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
    } catch (Exception e) {
      wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
      wrapper.msgInfo = 'Error Propose RAIP Action : ' + e.getMessage();
    }
    return wrapper;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description proposeRAIPAction : Propose RAIP Action
  *--------------------------------------------------------------------------------
  * @date		11/03/2021
  * @author	Global Desktop
  * @param    Arc_Gen_Delegation_Wrapper : wrapper
  * @return   Arc_Gen_Delegation_Wrapper
  * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
  */
  public static Arc_Gen_Delegation_Wrapper fetchLevelRegion(String selectedAmbit, String region, String level, String accHasAnalysisId, Boolean validate) {
    final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
    try{
      List<arce__Account_has_Analysis__c> aha = [Select DES_Local_Client__r.crossBorder__c from arce__Account_has_Analysis__c where Id = :accHasAnalysisId];
      if(level == null || level == '') {
        wrapper.lstLevel = formatAmbit(selectedAmbit,false,region,level,aha.get(0).DES_Local_Client__r.crossBorder__c,validate);
      } else {
        wrapper.lstAmbits = formatAmbit(selectedAmbit,false,region,level,aha.get(0).DES_Local_Client__r.crossBorder__c,validate);
      }
      wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
    } catch (Exception e) {
      wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
      wrapper.msgInfo = 'Error Propose RAIP Action : ' + e.getMessage();
    }
    return wrapper;
  }


  /*
	* @author Global Desktop
	*/
  private static List<Map<String, String>> formatAmbit(String ambitUser, boolean fromUser,String region, String level, Boolean xborder, Boolean validate) {
    final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
      SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, SelectablesCross__c, Validate__c, ValidateCross__c , canRead__c, canEdit__c, canPropose__c, canValidate__c
      FROM Arce_ambit_hierarchy__mdt
      ORDER BY Description__c ASC LIMIT 4000
    ]);
    final Arce_ambit_hierarchy__mdt ambit = gtAmbitFromLiteral(ambitUser, ambitMetadatas);

    final List<Map<String, String>> listAmbitKey = new List<Map<String, String>>();
    if(fromUser) {
      listAmbitKey.add(new map<String,String>{'label' => ambitUser , 'value' => ambit.Ambit__c});
    } else {
      List<String> ambitSelectables = getAmbitsSelect(validate, xborder, ambit);
      for(Arce_ambit_hierarchy__mdt ambitAux : ambitMetadatas) {
        if (level != null && level != '') {
            if(isLevel(level,region,ambitSelectables,ambitAux))
          		listAmbitKey.add(new map<String,String>{'label' => ambitAux.Description__c , 'value' => ambitAux.Ambit__c});
        } else if (region != null && region != '') {
            if (isRegion(listAmbitKey,region,ambitSelectables,ambitAux))
              listAmbitKey.add(new map<String,String>{'label' => BUSSUNIT.get(ambitAux.Level__c) , 'value' => ambitAux.Level__c});
        } else {
          if (isAmbit(listAmbitKey, ambitSelectables, ambitAux)) {
              listAmbitKey.add(new map<String,String>{'label' => GEOGR.get(ambitAux.Region__c) , 'value' => ambitAux.Region__c});
            }
          }
        }
      }
    return listAmbitKey;
    }
  /**
  * @description
  * @author Global Desktop | 23-02-2022
  * @param level
  * @param region
  * @param ambitSelectables
  * @param ambitAux
  * @return Boolean
  **/
  private static Boolean isLevel (String level, String region, List<String> ambitSelectables, Arce_ambit_hierarchy__mdt ambitAux) {
    Boolean isLevel = false;
          if (ambitSelectables.contains(ambitAux.Ambit__c) && ambitAux.Region__c == region
          	&& ambitAux.Level__c == level && ambitAux.Description__c != null && ambitAux.Description__c != '') {
            	isLevel = true;
          }
    return isLevel;
  }

  /**
  * @description
  * @author Global Desktop | 23-02-2022
  * @param listAmbitKey
  * @param region
  * @param ambitSelectables
  * @param ambitAux
  * @return Boolean
  **/
  private static Boolean isRegion (List<Map<String, String>> listAmbitKey, String region, List<String> ambitSelectables, Arce_ambit_hierarchy__mdt ambitAux) {
    Boolean isRegion = false;

        if( ambitSelectables.contains(ambitAux.Ambit__c) && ambitAux.Region__c == region
        	&& ambitAux.Level__c != null && ambitAux.Level__c != '' && !listAmbitKey.contains(new map<String,String>{'label' => BUSSUNIT.get(ambitAux.Level__c) , 'value' => ambitAux.Level__c})) {
          		isRegion = true;
        }

    return isRegion;
  }

  private static Boolean isAmbit (List<Map<String, String>> listAmbitKey,  List<String> ambitSelectables, Arce_ambit_hierarchy__mdt ambitAux) {
    Boolean isAmbit = false;
    if (ambitSelectables.contains(ambitAux.Ambit__c) && ambitAux.Region__c != null && ambitAux.Region__c != ''
      && !listAmbitKey.contains(new map<String,String>{'label' => GEOGR.get(ambitAux.Region__c) , 'value' => ambitAux.Region__c})) {
          isAmbit = true;
    }
    return isAmbit;
  }

  /**
  * @description
  * @author Global Desktop | 23-02-2022
  * @param validate
  * @param xborder
  * @param ambit
  * @return List<String>
  **/
  private static List<String> getAmbitsSelect (Boolean validate, Boolean xborder, Arce_ambit_hierarchy__mdt ambit) {
    List<String> ambitSelectables = new List<String>();
    if(validate) {
      if (xborder) {
        ambitSelectables = ambit.ValidateCross__c.split(';');
      } else {
        ambitSelectables = ambit.Validate__c.split(';');
      }
    } else {
      if (xborder) {
        ambitSelectables = ambit.SelectablesCross__c.split(';');
      } else {
        ambitSelectables = ambit.Selectables__c.split(';');
      }
    }
    return ambitSelectables;
  }

  /*
	* @author Global Desktop
	*/
  private static List<Map<String, String>> gtUsersAmbit(String selectedAmbit) {
    final String ambitString = gtStringAmbit(selectedAmbit);

    final List<User> lstUsers = new List<User>([
      SELECT Id, Name
      FROM User
      WHERE gf_user_operation_ambit_name__c = :ambitString
      AND IsActive = true
      ORDER BY Name ASC
    ]);

    final List<Map<String, String>> listAmbitUser = new List<Map<String, String>>();
    for(User usr : lstUsers) {
      listAmbitUser.add(new map<String,String>{'label' => usr.Name , 'value' => usr.Id});
    }
    return listAmbitUser;
  }

  /*
	* @author Global Desktop
	*/
  public static String gtStringAmbit(String selectedAmbit) {
    final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
      SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
      FROM Arce_ambit_hierarchy__mdt
      WHERE Ambit__c = :selectedAmbit
      LIMIT 40000
    ]);

    String ambitString = '';
    if(!ambitMetadatas.isEmpty()) {
      ambitString = ambitMetadatas.get(0).Region__c + ' - ' + ambitMetadatas.get(0).Level__c + (ambitMetadatas.get(0).Description__c == null || ambitMetadatas.get(0).Description__c == '' ? ' -' : ' - ' + ambitMetadatas.get(0).Description__c);
    }
    return ambitString;
  }

  /*
	* @author Global Desktop
	*/
  public static String gtDescriptionAmbit(String selectedAmbit) {
    final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
      SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
      FROM Arce_ambit_hierarchy__mdt
      WHERE Ambit__c = :selectedAmbit
      LIMIT 40000
    ]);

    String ambitString = '';
    if(!ambitMetadatas.isEmpty() && ambitMetadatas.get(0).Description__c != null && ambitMetadatas.get(0).Description__c != '') {
      ambitString = ambitMetadatas.get(0).Description__c;
    }
    return ambitString;
  }

  /*
	* @author Global Desktop
	*/
  public static Arce_ambit_hierarchy__mdt gtAmbitFromLiteral(String ambitUser, List<Arce_ambit_hierarchy__mdt> ambitMetadatas) {
    List<String> ambitFormatted = ambitUser.split('-');
    final String levelQuery = ambitFormatted.get(1).trim();
    final String regionQuery = ambitFormatted.get(0).trim();
    final String descriptionQuery = ambitFormatted.get(2).trim();

    Iterator<Arce_ambit_hierarchy__mdt> iter = ambitMetadatas.iterator();
    Arce_ambit_hierarchy__mdt ambit = new Arce_ambit_hierarchy__mdt();
    Boolean bool = true;
    while(iter.hasNext() && bool) {
      ambit = iter.next();
      if(ambit.Level__c == levelQuery && ambit.Region__c == regionQuery && ambit.Description__c == descriptionQuery) {
        bool = false;
      }
    }

    return ambit;
  }
}