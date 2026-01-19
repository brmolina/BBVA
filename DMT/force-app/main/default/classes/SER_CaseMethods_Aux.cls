/*-----------------------------------------------------------------
    Author:        Cintia Carmona
    Company:       Accenture
    Description:   This class contains helper and auxiliar methods
                    to not overload the main casemethods class.

    History:
    <Date>          <Author>                <Description>
    25/06/2020      Cintia Carmona      	Initial Version.
-------------------------------------------------------------------*/
public without sharing class SER_CaseMethods_Aux {

	/*Constante mapTechImBySev*/
	public static map<Id, String> mapTechImBySev;
	/* MAP_TECH_IMPACT for value TechImpact*/
	private static final Map<string,integer> MAP_TECH_IMPACT;
	static {
		MAP_TECH_IMPACT = new Map<string,integer>{
	    	'1. Critical'   => 1,
	    	'2. High'       => 2,
	    	'3. Medium'     => 3,
	    	'4. Low'        => 4,
	    	'5. No Impact'  => 5
		};
	}
  
	private SER_CaseMethods_Aux() {
  	}

/*--------------------------------------------------------------------------
    Author:        Cintia Carmona
    Company:       BBVA
    Description:   fill caseTaskMap.

    IN:        List<Id> caseIdsList
    IN:        Map<Case, List<Task>> caseTaskMap
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    22/06/2020        Cintia Carmona     Initial Version
  ----------------------------------------------------------------------------*/
  	private static void fillCaseMap(List<Id> caseIdsList, Map<Case, List<Task>> caseTaskMap) {
    	List<Task> taskList;
      	taskList = new List<Task>();

      	mapTechImBySev = new map<Id, String>();

      	taskList = [SELECT Id, WhatId, gf_tech_impact_case_name__c, Status FROM Task WHERE WhatId IN :caseIdsList];
      	for(Case caso : [SELECT Id, gf_cust_impact_case_name__c, validation_criticality_type__c FROM Case WHERE Id IN :caseIdsList]) {
        	caseTaskMap.put(caso, new List<Task>());

        	string strPriorityTech;
        	strPriorityTech = '';
        	for(Task tarea : taskList) {
          		if(String.isBlank(strPriorityTech)) {
            		strPriorityTech = tarea.gf_tech_impact_case_name__c;
          		} else if(MAP_TECH_IMPACT.get(tarea.gf_tech_impact_case_name__c) < MAP_TECH_IMPACT.get(strPriorityTech)) {
            		strPriorityTech = tarea.gf_tech_impact_case_name__c;
          		}
        	}
        	mapTechImBySev.put(caso.Id, strPriorityTech);
      	}
  	}

/*--------------------------------------------------------------------------
    Author:        Jose Luis
    Company:       Accenture
    Description:   Update AuxLastModify

    IN:        List<Task> newList
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    17/06/2020        Jose Luis      Initial Version
----------------------------------------------------------------------------*/
	public static void updateAuxLastModify(final List<case> cases) {
    	final datetime myDateTime = datetime.now();
    	String fechaLM;
    	final Integer FORMAT = 10;
    	final Integer month = myDateTime.month();
    	final Integer day = myDateTime.day();
    	final Integer hour = myDateTime.hour();
    	final Integer minutes = myDateTime.minute();
    	final Integer second = myDateTime.second();

    	fechaLM = myDateTime.year()+'-';

    	if (month<FORMAT) {
      		fechaLM = fechaLM+'0'+month+'-';
    	} else {
      		fechaLM = fechaLM+month+'-';
    	}
    	if (day<FORMAT) {
      		fechaLM = fechaLM+'0'+day+' ';
    	} else {
      		fechaLM = fechaLM+day+' ';
    	}
    	if (hour<FORMAT) {
      		fechaLM = fechaLM+'0'+hour+':';
    	} else {
      		fechaLM = fechaLM+hour+':';
    	}
    	if (minutes<FORMAT) {
      		fechaLM = fechaLM+'0'+minutes+':';
    	} else {
      		fechaLM = fechaLM+minutes+':';
    	}
    	if (second<FORMAT) {
      		fechaLM = fechaLM+'0'+second;
    	} else {
      		fechaLM = fechaLM+second;
    	}

    	for(case caso : cases) {
      		caso.AuxLastModDate__c = fechaLM;
    	}
    
  	}

}