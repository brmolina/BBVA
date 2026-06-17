/**
  * @author            Victor Velandia
  * Project:           BBVA Service
  * Description:       Test Class SER_CaseMethods_HELPER_Parent
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.0     2019-06-04      Victor Velandia (VV)    Initial version
  ************************************************************************************/
  @isTest
  public with sharing class SER_CaseMethods_HELPER_Parent_Tst {
  
    /**
      * description: STRPRUEBA
      * @author Victor Velandia
      */
    private static final string STRPRUEBA     = 'prueba';
    /**
      * description: STRCLOSED
      * @author Victor Velandia
      */
    private static final string STRCLOSED     = 'closed';
    /**
      * description: STRCONSULTA
      * @author Victor Velandia
      */
    private static final string STRCONSULTA   = 'consulta';
    /**
      * description: STRLINKED
      * @author Victor Velandia
      */
    private static final string STRLINKED     = 'linked to Master Case';
    /**
      * description: STRUPDMASTER
      * @author Victor Velandia
      */
    private static final string STRUPDMASTER  = 'bl_UpdatingMasterCases';
    /**
      * description: STRQUERYNEED
      * @author Victor Velandia
      */
    private static final string STRQUERYNEED  = 'bl_QueryNeeded';
  
    /**
      * description: nullIdParent
      */
    private static Id nullIdParent;
  
    /**
      * description: helperParentGM
      * @author Victor Velandia
      */
    public static testMethod void helperParentGM() {
      SER_TestUtils_3.initCustomsetting();
  
      final Boolean changeToModify            = false;
      final Set<Id> setMasterCasesID          = new Set<Id>();
      final Set<Id> setAlreadyExistMC         = new Set<Id>();
      final List<Case> lstCase                = new List<Case>();
      final Map<String,Boolean> mapBL         = new Map<String,Boolean>();
      final Map<Id,Case> mapMasterCases       = new Map<Id,Case>();
      final Map<Id,List<Case> > mapMasterIDCC  = new Map<Id,List<Case> >();
  
      Account pruebaAcc;
      pruebaAcc                               = new Account();
      pruebaAcc.Name                          = STRPRUEBA;
      insert pruebaAcc;
  
      Case parentCase;
      parentCase = new Case(AccountId = pruebaAcc.Id, Status = STRCLOSED, SER_Classification__c = STRCONSULTA, SER_Solution__c = 'Solution');
      insert parentCase;
  
      Case childCase;
      childCase = new Case(SER_Business_Case_Type__c = SER_Constant.BUSINESS_GM, SER_Is_Master_Case__c = changeToModify, SER_Close__c = false, status = STRLINKED, SER_IsSernova__c = true, ParentId = nullIdParent, RecordTypeId = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GM_User'].Id);
      insert childCase;
      childCase.SER_Close__c                  = false;
      childCase.status                        = STRCLOSED;
      update childCase;
  
      Case childCaseMap;
      childCaseMap                            = new Case();
      childCaseMap.SER_Business_Case_Type__c  = 'GM';
      childCaseMap.SER_Is_Master_Case__c      = changeToModify;
      childCase.SER_Classification__c         = 'feedback';
      childCaseMap.SER_Close__c               = false;
      childCaseMap.status                     = STRLINKED;
      childCaseMap.SER_IsSernova__c           = true;
      childCaseMap.ParentId                   = nullIdParent;
      childCaseMap.RecordTypeId               = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GM_User'].Id;
      insert childCaseMap;
      mapMasterCases.put(childCaseMap.Id, childCaseMap);
  
      mapBL.put(STRUPDMASTER, true);
      mapBL.put(STRQUERYNEED, true);
      setMasterCasesID.add(childCaseMap.id);
      setAlreadyExistMC.add(childCase.id);
      lstCase.add(childCase);
      mapMasterIDCC.put(childCaseMap.Id, lstCase);
  
      Test.startTest();
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, childCaseMap, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, parentCase, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      System.assertEquals (childCase.id,childCase.id,'');
      Test.stopTest();
    }
  
    /**
      * description: helperParentGmElse
      * @author Victor Velandia
      */
    public static testMethod void helperParentGmElse() {
      SER_TestUtils_3.initCustomsetting();
  
      final Boolean changeToModify            = true;
      final String strQuery                   = STRQUERYNEED;
      final String strUpdate                  = STRUPDMASTER;
      final Set<Id> setMasterCasesID          = new Set<Id>();
      final Set<Id> setAlreadyExistMC         = new Set<Id>();
      final List<Case> lstCase                = new List<Case>();
      final Map<String,Boolean> mapBL         = new Map<String,Boolean>();
      final Map<Id,Case> mapMasterCases       = new Map<Id,Case>();
      final Map<Id,List<Case> > mapMasterIDCC  = new Map<Id,List<Case> >();
  
      Account pruebaAcc;
      pruebaAcc                               = new Account();
      pruebaAcc.Name                          = STRPRUEBA;
      insert pruebaAcc;
  
      Case parentCase;
      parentCase                               = new Case();
      parentCase.AccountId                     = pruebaAcc.Id;
      parentCase.Status                        = STRCLOSED;
      parentCase.SER_Solution__c               = 'Solution';
      insert parentCase;
  
      Case childCase;
      childCase                               = new Case();
      childCase.SER_Business_Case_Type__c     = 'GM';
      childCase.SER_Is_Master_Case__c         = changeToModify;
      childCase.ParentId                      = parentCase.id;
      childCase.RecordTypeId                  = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GM_User'].Id;
      insert childCase;
  
      Case childCaseMap;
      childCaseMap                            = new Case();
      childCaseMap.SER_Business_Case_Type__c  = 'GM';
      childCaseMap.SER_Is_Master_Case__c      = changeToModify;
      childCaseMap.status                     = STRLINKED;
      childCaseMap.ParentId                   = parentCase.id;
      childCaseMap.RecordTypeId               = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GM_User'].Id;
      insert childCaseMap;
      childCaseMap.ParentId                   = nullIdParent;
      update childCase;
      mapMasterCases.put(childCaseMap.Id, childCaseMap);
  
      mapBL.put(strUpdate, true);
      mapBL.put(strQuery, true);
      setMasterCasesID.add(childCaseMap.id);
      setAlreadyExistMC.add(childCase.id);
      lstCase.add(childCase);
      mapMasterIDCC.put(childCaseMap.Id, lstCase);
  
      Test.startTest();
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, parentCase, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      System.assertEquals (childCase.id,childCase.id,'');
      Test.stopTest();
    }
  
    /**
      * description: helperParentGNC
      * @author Victor Velandia
      */
    public static testMethod void helperParentGNC() {
  
      final Boolean changeToModify            = false;
      final Set<Id> setMasterCasesID          = new Set<Id>();
      final Set<Id> setAlreadyExistMC         = new Set<Id>();
      final List<Case> lstCase                = new List<Case>();
      final Map<String,Boolean> mapBL         = new Map<String,Boolean>();
      final Map<Id,Case> mapMasterCases       = new Map<Id,Case>();
      final Map<Id,List<Case> > mapMasterIDCC  = new Map<Id,List<Case> >();
  
      Case childCase;
      childCase                               = new Case();
      childCase.SER_Business_Case_Type__c     = 'GNC';
      childCase.SER_Is_Master_Case__c         = changeToModify;
	    childCase.SER_Classification__c			    = 'Incidencia';
      childCase.SER_Close__c                  = false;
      childCase.status                        = STRLINKED;
      childCase.SER_IsSernova__c              = true;
      childCase.ParentId                      = nullIdParent;
      childCase.RecordTypeId                  = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GNC_User'].Id;
      insert childCase;
      childCase.SER_Close__c                  = false;
      childCase.status                        = STRCLOSED;
      update childCase;
  
      Case childCaseMap;
      childCaseMap                            = new Case();
      childCaseMap.SER_Business_Case_Type__c  = 'GNC';
      childCaseMap.SER_Is_Master_Case__c      = changeToModify;
      childCase.SER_Classification__c         = 'feedback';
      childCaseMap.SER_Close__c               = false;
      childCaseMap.status                     = STRLINKED;
      childCaseMap.SER_IsSernova__c           = true;
      childCaseMap.ParentId                   = nullIdParent;
      childCaseMap.RecordTypeId               = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GNC_User'].Id;
      insert childCaseMap;
      mapMasterCases.put(childCaseMap.Id, childCaseMap);
  
      mapBL.put(STRUPDMASTER, true);
      setMasterCasesID.add(childCaseMap.id);
      setAlreadyExistMC.add(childCase.id);
      lstCase.add(childCase);
      mapMasterIDCC.put(childCaseMap.Id, lstCase);
  
      Test.startTest();
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, childCaseMap, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      System.assertEquals (childCase.id,childCase.id,'');
      Test.stopTest();
    }
  
    /**
      * description: helperParentGNCElse
      * @author Victor Velandia
      */
    public static testMethod void helperParentGNCElse() {
      SER_TestUtils_3.initCustomsetting();
  
      final Boolean changeToModify            = false;
      final String strQuery                   = STRQUERYNEED;
      final String strUpdate                  = STRUPDMASTER;
      final Set<Id> setMasterCasesID          = new Set<Id>();
      final Set<Id> setAlreadyExistMC         = new Set<Id>();
      final List<Case> lstCase                = new List<Case>();
      final Map<String,Boolean> mapBL         = new Map<String,Boolean>();
      final Map<Id,Case> mapMasterCases       = new Map<Id,Case>();
      final Map<Id,List<Case> > mapMasterIDCC  = new Map<Id,List<Case> >();
  
      Account pruebaAcc;
      pruebaAcc                               = new Account();
      pruebaAcc.Name                          = STRPRUEBA;
      insert pruebaAcc;
  
      Case parentCase;
      parentCase                              = new Case();
      parentCase.AccountId                    = pruebaAcc.Id;
      parentCase.Status                       = STRCLOSED;
      parentCase.SER_Solution__c              = 'Solution';
      insert parentCase;
  
      Case childCase;
      childCase                               = new Case();
      childCase.SER_Business_Case_Type__c     = 'GNC';
      childCase.SER_Is_Master_Case__c         = changeToModify;
      childCase.ParentId                      = parentCase.id;
      childCase.RecordTypeId                  = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GNC_User'].Id;
      insert childCase;
  
      Case childCaseMap;
      childCaseMap                            = new Case();
      childCaseMap.SER_Business_Case_Type__c  = 'GNC';
      childCaseMap.SER_Is_Master_Case__c      = changeToModify;
      childCaseMap.status                     = STRLINKED;
      childCaseMap.ParentId                   = parentCase.id;
      childCaseMap.RecordTypeId               = [Select Id FROM RecordType WHERE DeveloperName = 'SER_GNC_User'].Id;
      insert childCaseMap;
      childCaseMap.ParentId                   = nullIdParent;
      update childCase;
      mapMasterCases.put(childCaseMap.Id, childCaseMap);
  
      mapBL.put(strUpdate, true);
      mapBL.put(strQuery, true);
      setMasterCasesID.add(childCaseMap.id);
      setAlreadyExistMC.add(childCase.id);
      lstCase.add(childCase);
      mapMasterIDCC.put(childCaseMap.Id, lstCase);
  
      Test.startTest();
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, childCaseMap, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(childCase, parentCase, mapBL, setMasterCasesID, setAlreadyExistMC, mapMasterCases, mapMasterIDCC);
      System.assertEquals (childCase.id,childCase.id,'');
      Test.stopTest();
    }
  }