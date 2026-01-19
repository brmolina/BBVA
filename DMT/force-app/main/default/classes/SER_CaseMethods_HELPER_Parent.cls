/*-----------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   This class contains helper and auxiliar methods
                    to not overload the main casemethods class of logic parent.

    History:
    <Date>          <Author>                <Description>
    04/07/2017      Juan Carlos Terrón      Initial Version.
    -------------------------------------------------------------------*/
    public without sharing class SER_CaseMethods_HELPER_Parent {

      /*Constante bl_InsertingMasterCases*/
      final static string BL_IMC = 'bl_InsertingMasterCases';
      /*Constante closed*/
      final static string CLOSE = 'Closed';
      /*Constante Resolved*/
      final static string RESOLVED = 'Resolved';
      /*Constante Working*/
      final static string WORKING = 'Working';
      /*Constante bl_queryneeded*/
      final static string BL_QUERYNEEDED = 'bl_QueryNeeded';
      /*Constante bl_updatingmastercases*/
      final static string BL_UPDATINGMC = 'bl_UpdatingMasterCases';
    
      private SER_CaseMethods_HELPER_Parent() {
      }
      /*----------------------------------------------------------------------------
          Author:        Juan Carlos Terrón
          Company:       Accenture
          Description:   Method to filter the type of processing
    
          IN:            Case(CurrentCase),Case(PreviousCase),Maps
          OUT:           void
    
          History:
          <Date>                  <Author>                <Change Description>
          26/09/2017              Juan Carlos Terrón      Initial Version
          12/11/2018              Jose Luis Aranda	    Add GNC
          -------------------------------------------------------------------------------*/
      public static void fillParentChildrenMaps(
        Case caso,
        Case oldcase,
        Map<String,Boolean> mapBL,
        Set<Id> setMasterCasesID,
        Set<Id> setAlreadyExistMC,     //set_AlreadyExistingMasterCases
        Map<Id,Case> mapMasterCases,
        Map<Id,List<Case> > mapMasterIDCC) {
    
        /*UPDATE*/
        if(caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM) {    //GM Bussines logic
          updateChildrenGM  (caso, oldcase, mapBL, setMasterCasesID,setAlreadyExistMC,mapMasterCases,mapMasterIDCC);
        } else if(caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC) {    //GNC Bussines logic
          updateChildrenGNC (caso, oldcase, mapBL, setMasterCasesID,setAlreadyExistMC,mapMasterCases,mapMasterIDCC);
        }
      }
      private static void updateChildrenGM (Case caso,
                                            Case oldcase,
                                            Map<String,Boolean> mapBL,
                                            Set<Id> setMasterCasesID,
                                            Set<Id> setAlreadyExistMC,
                                            Map<Id,Case> mapMasterCases,
                                            Map<Id,List<Case> > mapMasterIDCC) {
        final boolean changeToModify = caso.ParentId == null && caso.SER_Business_Case_Type__c == 'GM' &&
                                        (caso.SER_Classification__c != oldcase.SER_Classification__c
                                        || caso.SER_Asset__c != oldcase.SER_Asset__c
                                        || caso.SER_Type_GM__c != oldcase.SER_Type_GM__c
                                        || caso.SER_Subtype_GM__c != oldcase.SER_Subtype_GM__c
                                        || caso.Subject != oldcase.Subject
                                        || caso.SER_Pre_liquidacion__c != oldcase.SER_Pre_liquidacion__c
                                        || caso.SER_Post_liquidation__c != oldcase.SER_Post_liquidation__c
                                        || caso.Description != oldcase.Description
                                        || caso.Status == CLOSE && oldcase.Status != CLOSE);
    
        if(changeToModify) {
          //Its a parent case(its ParentCase field = null) and at least one of the filtered fields is being changed.
          if(!mapBL.get(BL_UPDATINGMC)) { mapBL.put(BL_UPDATINGMC,true); }
          setMasterCasesID.add(caso.Id);
          mapMasterCases.put(caso.ID, caso);
          mapMasterIDCC.put(caso.Id, new List<Case>());
        } else if(isChildrenCaseGM(caso, oldcase)) {        //Its a children Case, its the same process as STE bussines logic.
          if(!setMasterCasesID.contains(caso.ParentId)) { setMasterCasesID.add(caso.ParentId); }
          if(!setAlreadyExistMC.contains(caso.ParentId)) { setAlreadyExistMC.add(caso.ParentId); }
          if(!mapBL.get(BL_QUERYNEEDED)) { mapBL.put(BL_QUERYNEEDED,true); }
          if(!mapBL.get(BL_UPDATINGMC)) { mapBL.put(BL_UPDATINGMC,true); }
          if(mapMasterIDCC.containsKey(caso.ParentId)) {
            mapMasterIDCC.get(caso.ParentId).add(caso);
          } else {
            mapMasterIDCC.put(caso.ParentId, new List<Case>());
            mapMasterIDCC.get(caso.ParentId).add(caso);
          }
        }
      }
    
      private static boolean isChildrenCaseGM (Case caso, Case oldcase) {
        return caso.ParentId != null
                && (oldcase.ParentId != caso.ParentId
                    || oldcase.ParentId == null);
    
      }
      private static void updateChildrenGNC (Case caso,
                                              Case oldcase,
                                              Map<String,Boolean> mapBL,
                                              Set<Id> setMasterCasesID,
                                              Set<Id> setAlreadyExistMC,
                                              Map<Id,Case> mapMasterCases,
                                              Map<Id,List<Case> > mapMasterIDCC) {
        final boolean changeToModify = caso.ParentId == null
                                        && caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC
                                        && (caso.SER_Classification__c != oldcase.SER_Classification__c
                                            || caso.SER_Type_GNC__c != oldcase.SER_Type_GNC__c
                                            || caso.SER_Subtype_GNC__c != oldcase.SER_Subtype_GNC__c
                                            || caso.Description != oldcase.Description
                                            || caso.SER_Country__c != oldcase.SER_Country__c
                                            || caso.SER_Solution__c != oldcase.SER_Solution__c
                                            || caso.Status == CLOSE && oldcase.Status != CLOSE);
    
        if(changeToModify) {
          //Its a parent case(its ParentCase field = null) and at least one of the filtered fields is being changed.
          if(!mapBL.get(BL_UPDATINGMC)) { mapBL.put(BL_UPDATINGMC,true); }
          setMasterCasesID.add(caso.Id);
          mapMasterCases.put(caso.ID, caso);
          mapMasterIDCC.put(caso.Id, new List<Case>());
        } else if(isChildrenCaseGNC(caso, oldcase)) {        //Its a children Case, its the same process as STE bussines logic.
          if(!setMasterCasesID.contains(caso.ParentId)) { setMasterCasesID.add(caso.ParentId); }
          if(!setAlreadyExistMC.contains(caso.ParentId)) { setAlreadyExistMC.add(caso.ParentId); }
          if(!mapBL.get(BL_QUERYNEEDED)) { mapBL.put(BL_QUERYNEEDED,true); }
          if(!mapBL.get(BL_UPDATINGMC)) { mapBL.put(BL_UPDATINGMC,true); }
          if(mapMasterIDCC.containsKey(caso.ParentId)) {
            mapMasterIDCC.get(caso.ParentId).add(caso);
          } else {
            mapMasterIDCC.put(caso.ParentId, new List<Case>());
            mapMasterIDCC.get(caso.ParentId).add(caso);
          }
        }
      }
      private static boolean isChildrenCaseGNC (Case caso, Case oldcase) {
        return caso.ParentId != null
                && (oldcase.ParentId != caso.ParentId
                    || oldcase.ParentId == null);
    
      }
      /*-------------------------------------------------------------------------------
          Author:        Juan Carlos Terrón
          Company:       Accenture
          Description:   Method to filter the type of processing
    
          IN:            Case(CurrentCase),Case(PreviousCase),Maps
          OUT:           void
    
          History:
          <Date>                  <Author>                <Change Description>
          26/09/2017              Juan Carlos Terrón      Initial Version
                  12/11/2018              Jose Luis Aranda	    Add GNC
          ---------------------------------------------------------------------------------*/
      public static void fillParentChildrenMaps(
        Case caso,
        Map<String,Boolean> mapBL,
        Set<Id> setMasterCasesID,
        Set<Id> setAlreadyExistMC,
        Map<Id,Case> mapMasterCases,
        Map<Id,Case> mapChildrenCases,
        Map<Id,List<Case> > mapMasterIDCC) {
    
        /*INSERT*/
        if(caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM || caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC) {    //GM or GNC Bussines logic
          insertChildrenGMorGNC(caso,mapBL,setMasterCasesID,setAlreadyExistMC,mapMasterCases,mapChildrenCases,mapMasterIDCC);
        }
      }
      private static void insertChildrenGMorGNC(
        Case caso,
        Map<String,Boolean> mapBL,
        Set<Id> setMasterCasesID,
        Set<Id> setAlreadyExistMC,
        Map<Id,Case> mapMasterCases,
        Map<Id,Case> mapChildrenCases,
        Map<Id,List<Case> > mapMasterIDCC) {
        if(caso.ParentId == null) {        //Its a parent case
          setMasterCasesID.add(caso.Id);
          mapMasterCases.put(caso.Id, caso);
          if(!mapBL.get(BL_IMC)) { mapBL.put(BL_IMC,true); }          //Flag set to true
          if(!mapMasterIDCC.containsKey(caso.ID)) { mapMasterIDCC.put(caso.Id, new List<Case>()); }
        } else if(caso.ParentId != null) {        //Its a children case
          if(setMasterCasesID.contains(caso.ParentId)) {          //Its parent case is in the set
            mapChildrenCases.put(caso.Id, caso);
            mapMasterIDCC.get(caso.ParentId).add(caso);
          } else {          //Its parent case isn't in the set -->  we add it.
            mapChildrenCases.put(caso.Id, caso);
            if(!mapBL.get(BL_QUERYNEEDED)) { mapBL.put(BL_QUERYNEEDED,true); }
            if(mapMasterIDCC.containsKey(caso.Parent.Id)) {
              mapChildrenCases.put(caso.Id, caso);
              mapMasterIDCC.get(caso.ParentId).add(caso);
            } else {
              mapMasterIDCC.put(caso.ParentId, new List<Case>());
              mapMasterIDCC.get(caso.ParentId).add(caso);
            }
            setAlreadyExistMC.add(caso.ParentId);
          }
          if(!mapBL.get(BL_IMC)) { mapBL.put(BL_IMC,true); }
        }
      }
    }