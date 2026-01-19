/**********************************************************************************
* @author  		ANS
* @date         14/12/2021
* @description  Batch marca account plan
* @Revision
**********************************************************************************/
public without sharing class MassiveBlockUnblockAPBatch implements Database.Batchable<Sobject> {
   
    private Set<Id> SetInUsers;
    private Boolean unlock;

    public void BatchParameters(Set<Id> ParSetInUsers,Boolean ParUnlock) {
        SetInUsers=ParSetInUsers;
        unlock=ParUnlock;
    }
    /*
     *  @author     Global Desktop
     *  @description    Constructor
    **/
    public MassiveBlockUnblockAPBatch() {
        SetInUsers = new Set<Id>();
        unlock=false;
    }

    /*
     *  @author     Global Desktop
     *  @description    batch START method
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Set<Id> Users=SetInUsers;
        String pQuery = 'SELECT Id FROM User where id in:Users';
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  @author     Global Desktop
     *  @description    batch EXECUTE method
    **/
    public void execute(Database.BatchableContext batchContext, List<User> lstUser) {
		
		//System.debug('bloqueo masivo ===='+lstUser.size()+'=='+lstUser);
        // recojo el registro de configuración y envío notificaciones con el mensaje definido
        final List<AP_notif__c> apPeriod = [SELECT Id, gf_admin_notif_lock_mgr_desc__c, gf_admin_notif_unlock_mgr_desc__c FROM AP_notif__c LIMIT 1];
        for(User apTeamIdAux : lstUser) {
            if(unlock) {
                System.debug('bloqueo masivo - unlock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux.id, apPeriod.get(0).gf_admin_notif_unlock_mgr_desc__c);
            } else {
                System.debug('bloqueo masivo - lock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux.id, apPeriod.get(0).gf_admin_notif_lock_mgr_desc__c);
            }
        }

    }//FIN execute

    /*
     *  @author     Global Desktop
     *  @description    batch FINISH method
    **/
    public void finish(Database.BatchableContext batchContext) {
    }


}