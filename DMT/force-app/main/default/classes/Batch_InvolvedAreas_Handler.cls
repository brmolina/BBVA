/******************************************************************************************************************************************************
*   @author: GlobalDesktop
*   @Method: Batch_InvolvedAreas_Handler
*   @Description: Batch to update Involved Areas based on their visit management team

*   @Versions:
        v1 - 2019/01/28 - Initial version
******************************************************************************************************************************************************/
public with sharing class Batch_InvolvedAreas_Handler {
    //CONSTRUCTOR
    private Batch_InvolvedAreas_Handler() {
    }

    //SINGLETON PATTERN
    private static Batch_InvolvedAreas_Handler instance;
   /*
    *	@author GlobalDesktop 
    * 
    **/
    public static Batch_InvolvedAreas_Handler getInstance() {
        if (instance == null) instance = new Batch_InvolvedAreas_Handler();
        return instance;
    }
    
    /*
    *	@author GlobalDesktop 
    * 
    **/
    public void logicSetInvolvedAreas(List<dwp_kitv__Visit_Management_Team__c> scope) {
      Map<Id, Set<String>> mapVisitInvAreas;//MAPA CON IdVisita - Set de departamentos de la visita
      mapVisitInvAreas = new Map<Id, Set<String>>();

      //MAPA METADATOS CORRESPONDENCIA USERDEPARTMENT - VISITINVOLVEDAREAS
      Map<String, String> mapUsrDeptInvArea = gtMapUsrDeptInvArea();

      for(dwp_kitv__Visit_Management_Team__c visitMT : scope) {
        Set<String> setDepts;
        setDepts = new Set<String>();
        if(mapVisitInvAreas.get(visitMT.dwp_kitv__visit_id__c) == null) {
          setDepts.add(mapUsrDeptInvArea.get(visitMT.dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c));
        } else {
          setDepts = mapVisitInvAreas.get(visitMT.dwp_kitv__visit_id__c);
          if(!setDepts.contains(mapUsrDeptInvArea.get(visitMT.dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c))) {
            setDepts.add(mapUsrDeptInvArea.get(visitMT.dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c));
          }
        }
        mapVisitInvAreas.put(visitMT.dwp_kitv__visit_id__c, setDepts);
      }

      List<dwp_kitv__Visit__c> lstVisitToUpd;
      lstVisitToUpd = new List<dwp_kitv__Visit__c>();
      for(Id visitId : mapVisitInvAreas.keySet()) {
        lstVisitToUpd.add(new dwp_kitv__Visit__c(Id = visitId, dwp_kitv__solution_name_path_desc__c = String.join((Iterable<String>)mapVisitInvAreas.get(visitId), ';')));
      }

      system.debug('>>>>>> lstVisitToUpd : ' + lstVisitToUpd);
      if(!lstVisitToUpd.isEmpty()) {
        update lstVisitToUpd;
      }
    }
    
    /*
    *	@author GlobalDesktop 
    * 
    **/
    public Map<String, String> gtMapUsrDeptInvArea() {
      final List<dwp_kitv__User_department_areas__mdt> userDepartmentAreas = new List<dwp_kitv__User_department_areas__mdt>([SELECT dwp_kitv__User_department__c, dwp_kitv__User_profile__c, dwp_kitv__Visit_involved_area__c FROM dwp_kitv__User_department_areas__mdt]);
      system.debug('Valor de userDepartmentAreas: ' +userDepartmentAreas);
      Map<String, String> departmentRelatedArea;
      departmentRelatedArea = new Map<String, String>();
      for(dwp_kitv__User_department_areas__mdt uda : userDepartmentAreas) {
        departmentRelatedArea.put(uda.dwp_kitv__User_department__c, uda.dwp_kitv__Visit_involved_area__c);
      }
      return departmentRelatedArea;
    }
}