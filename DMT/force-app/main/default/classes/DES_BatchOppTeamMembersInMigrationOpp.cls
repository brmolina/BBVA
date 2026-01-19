/******************************************************************************************************************************************************************
Name:            DES_BatchOppTeamMembersInMigrationOpp
Description:     Clase Batch para lanzar justo despues de la carga masiva de Opp de los datos de migración. Luego nunca más se utilizará.
				 Para cada Opp de una Account, se traerá al OppTeam todo el AccountTeam de la jerarquía
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
1.0            22/06/2018                        Class creation    
2.0            05/07/2018                        Modificada la query del proceso batch    
*******************************************************************************************************************************************************************/

public without sharing class DES_BatchOppTeamMembersInMigrationOpp implements Database.Batchable<Sobject>, Database.Stateful {	
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private Integer relationshipsCreated = 0;
  private Set<String> setAccIdHierarchyForOpp = new Set<String>(); //Set used to avoid duplicate id's
  private String query = 'SELECT Id, StageName, AccountId, DES_Countries__c FROM Opportunity '+ (Test.isRunningTest() ? ' LIMIT 1' : '')+ (!Test.isRunningTest() ? 'Where StageName != \'Draft Opp\' AND AccountId != \'\' AND createdBy.Username  = \'integrator@bbva.com\'': ''); //owner.Profile.Name = \'Desktop Integration\' ';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_BatchOppTeamMembersInMigrationOpp() {
    system.debug('Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Opportunity> scope) {    
   	accHierarchyTeamCopyToOppTeam(scope);    
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('SUMMARY: ');
    System.debug('  Records Processed: ' + recordsProcessed);
    System.debug('  Relationships Created: ' + relationshipsCreated);
    System.debug('  Batches Created: ' + job.JobItemsProcessed);
    System.debug('  Number of Errors: ' + job.NumberOfErrors);
    System.debug('  Status: ' + job.Status);
  }




// --------------------------------- PRIVATE METHODS ---------------------------------
    private DES_Opportunity_Management_member__c generarOppTeamMember(Opportunity auxOpp, DES_BBVA_Management_team__c auxClientTM){
        system.debug('>>>>> INPUT auxOpp : ' + auxOpp);
        system.debug('>>>>> INPUT auxClientTM : ' + auxClientTM);
        DES_Opportunity_Management_member__c auxOppTM = new DES_Opportunity_Management_member__c();
        auxOppTM.DES_Opportunity__c = auxOpp.Id;
        auxOppTM.DES_User__c = auxClientTM.DES_User__c;
        auxOppTM.DES_Opportunity_member_role__c = auxClientTM.DES_Member_Role__c;
        auxOppTM.DES_Scope__c = auxClientTM.DES_Local_Banker_Country__c;
        system.debug('>>>>> auxOppTM RETURN : ' + auxOppTM);
        return auxOppTM;
    }

   private void accHierarchyTeamCopyToOppTeam(List<Opportunity> listaOportunidades){
        List <DES_Opportunity_Management_member__c> listaOppTeamMembersToInsert = new List <DES_Opportunity_Management_member__c>();
        
        // aunque se mete en un FOR este método está pensado para un BatchSize = 1 para que no de límite de queries
        for (Opportunity opp : listaOportunidades){
        	recordsProcessed++;
            setAccIdHierarchyForOpp.clear();
            
            if(opp.AccountId != null) { //para las opp de Lead no se aplica la lógica
                recursiveFxn(opp.AccountId);

                // recojo los DES_BBVA_Management_team__c de la jerarquía de cuentas de la Opp setAccIdHierarchyForOpp 
                List<DES_BBVA_Management_team__c> listaClientTeamMembers = new List<DES_BBVA_Management_team__c>([
                            SELECT  Id,
                                    DES_User__c,
                                    DES_Client__c,
                                    DES_Member_Role__c,
                                    DES_Local_Banker_Country__c/*,
                                    DES_PS_Product__c*/
                            FROM DES_BBVA_Management_team__c
                            WHERE DES_Client__c IN :setAccIdHierarchyForOpp
                ]);
                system.debug('>>>>>>>> listaClientTeamMembers: ' + listaClientTeamMembers);

                // por cada Oportunidad, recorro los DES_BBVA_Management_team__c traidos de la cuenta de la opp y todas sus cuentas padres, y se añaden al equipo de la Opp. 
                for(DES_BBVA_Management_team__c auxClientTM : listaClientTeamMembers){
                            system.debug('>>>>> auxClientTM: ' + auxClientTM);
                            DES_Opportunity_Management_member__c oppTM;
                            //SI EL MIEMBRO QUE SE VA A COPIAR ES PRODUCT SPECIALIST, TRANSACTIONAL BANKER Y/O LOCAL BANKER TENGO QUE COMPROBAR SI EL PAÍS COINCIDE
                            if(auxClientTM.DES_Member_Role__c == Label.DES_Role_Product_Specialist
                             || auxClientTM.DES_Member_Role__c == Label.DES_Role_Transactional_Banker
                             || auxClientTM.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER){
                                //Si opp.DES_Country__c contiene más de 1 país
                                if(opp.DES_Countries__c != null && opp.DES_Countries__c.contains(';')){
                                    //Guardo la lista de paises en una matriz para comprobar si el pais coincide o no
                                    List<String> paises = opp.DES_Countries__c.split(';');
                                    system.debug('>>>>> paises: ' + paises);
                                    for(String pais : paises){
                                        if(pais == auxClientTM.DES_Local_Banker_Country__c){
                                            //Si coincide el país, llamo a una funcion para crear un miembro de la Opp
                                            oppTM = generarOppTeamMember(opp, auxClientTM);
                                            //Paro la ejecución del FOR, ya que no necesito seguir recorriendo la lista de paises 
                                            break;
                                        }
                                    }
                                }else{//SI SOLO TIENE 1 PAÍS
                                    if(opp.DES_Countries__c != null && auxClientTM.DES_Local_Banker_Country__c == opp.DES_Countries__c){
                                        //Si coincide el país, llamo a una funcion para crear un miembro de la Opp
                                        oppTM = generarOppTeamMember(opp, auxClientTM);
                                    }
                                }
                            }else{//Si no es ninguno de los roles anteriores se copia sin validar nada
                                oppTM = generarOppTeamMember(opp, auxClientTM);
                            }
                            system.debug('>>>>> oppTM: ' + oppTM);
                           // auxOppTM.DES_PS_Product__c = auxClientTM.DES_PS_Product__c;
                            if(oppTM != null && !checkDuplicates(listaOppTeamMembersToInsert,oppTM)){
                                listaOppTeamMembersToInsert.add(oppTM);
                            }
                            system.debug('>>>>> listaOppTeamMembersToInsert: ' + listaOppTeamMembersToInsert);

                }// FIN FOR
            }//FIN IF opp.AccountId != null                
        }// FIN FOR

        try {
            insert listaOppTeamMembersToInsert;
        }catch(Exception e){
             system.debug('>>>>> Exception: ' + e);    
        }           

    } // FIN Method


  //Recursive function to add the AccTeamMembers of the Account hierarchy for a given opportunity
  //starting from Opportunity.AccountId
  private void recursiveFxn(string accId) {
    if (accId != null) {
        system.debug('Adding Account Id >> Acc:' + accId);
        setAccIdHierarchyForOpp.add(accId);
    }

    //Retrieve the parents for the account passed
    List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id, dwp_acmh__Parent_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c = :accId];

    //iterate to recursively add the opportunity to each parent in the hierarchy
    for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
      recursiveFxn(accRel.dwp_acmh__Parent_Account__c);
    }
  }    

    private Boolean checkDuplicates(List<DES_Opportunity_Management_member__c> currentList, DES_Opportunity_Management_member__c newBBVAManagement){        
        // recorro la lista incial (currentList) y la comparo con la lista recogida (listaBBVAMT). Si hay alguna pareja repetida el metodo devuelve FALSE y no se añade a currentList
        Boolean hayDuplicado = false;
        
        for(DES_Opportunity_Management_member__c oppBBVAmember : currentList){ 
                if(oppBBVAmember.DES_Opportunity__c == newBBVAManagement.DES_Opportunity__c && oppBBVAmember.DES_User__c == newBBVAManagement.DES_User__c && oppBBVAmember.DES_Opportunity_member_role__c == newBBVAManagement.DES_Opportunity_member_role__c){
                    // Global Banker, Industry Head y Risk Analyst
                    if (oppBBVAmember.DES_Opportunity_member_role__c== Label.DES_ROLE_GLOBAL_BANKER || oppBBVAmember.DES_Opportunity_member_role__c== Label.DES_ROLE_INDUSTRY_HEAD || oppBBVAmember.DES_Opportunity_member_role__c== Label.DES_Role_Risk_Analyst){
                        hayDuplicado = true;    
                        
                    // Local Banker y Transactional Banker
                    } else if (oppBBVAmember.DES_Scope__c == newBBVAManagement.DES_Scope__c
                               && (oppBBVAmember.DES_Opportunity_member_role__c== Label.DES_ROLE_LOCAL_BANKER || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_Role_Transactional_Banker)){
                                    hayDuplicado = true;    
                               }
                    // Product Specialist
                    else if ( /*oppBBVAmember.DES_PS_Product__c == newBBVAManagement.DES_PS_Product__c 
                                &&*/ oppBBVAmember.DES_Opportunity_member_role__c== Label.DES_Role_Product_Specialist){
                                    hayDuplicado = true;    
                                }
                }// FIN IF

        }// FIN FOR

        return hayDuplicado;
    } // FIN checkDuplicates()      

	
}