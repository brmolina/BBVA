/**********************************************************************************
* @author  		Global Desktop
* @date         01/04/2020
* @description  Clase auxiliar  para el Batch BatchActiveAccounts
* @Revision
**********************************************************************************/
public without sharing class ActiveAccountsHandler {
    private ActiveAccountsHandler() {}

    /**
    * @description 
    * @author Global Desktop | 27/4/2020 
    * @param listAccounts 
    * @return void 
    **/
    public static void desactivateAccounts (List<Account> listAccounts) {
        final List<Account> accountDes = new List<Account>();
        for (Account account: listAccounts) {
            account.gf_prtcpt_act_status_ind_type__c = false;
            accountDes.add(account);
        }
        update accountDes;
    }

}