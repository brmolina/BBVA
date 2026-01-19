public class DES_HistoricRarEvaRorcTriggerHandler{

    public static void checkDateHistoricUpdate(List<DES_Historic_RAR_EVA_RORC__c> historicInputList){
        set<Id> idsAccount = new set<Id>();
        for(DES_Historic_RAR_EVA_RORC__c h : historicInputList){
            idsAccount.add(h.DES_Client__c);
        }

        list<Account> accList = [SELECT id,
                                        Name,
                                        DES_RAR_EVA_RORC_Update_Engloba__c,
                                        DES_Previous_RAR_EVA_RORC_Update_Engloba__c
                                 FROM Account
                                 WHERE id IN: idsAccount];

        if(accList[0].DES_RAR_EVA_RORC_Update_Engloba__c != accList[0].DES_Previous_RAR_EVA_RORC_Update_Engloba__c){
            List<User> userDesktopList = [SELECT Name,
                                                 DES_First_Login_After_Historic_Update__c
                                          FROM User
                                          WHERE (Profile.Name = 'BBVA Desktop CIB Management'
                                                OR Profile.Name = 'BBVA Desktop GCC Business Development'
                                                OR Profile.Name = 'BBVA Desktop GCC Management'
                                                OR Profile.Name = 'BBVA Desktop GCC Standard'
                                                OR Profile.Name = 'BBVA Desktop IBF Business Development'
                                                OR Profile.Name = 'BBVA Desktop IBF Standard'
                                                OR Profile.Name = 'BBVA Desktop GM Business Development'
                                                OR Profile.Name = 'BBVA Desktop GM Standard'
                                                OR Profile.Name = 'BBVA Desktop GTB Business Development'
                                                OR Profile.Name = 'BBVA Desktop GTB Standard')
                                                AND DES_First_Login_After_Historic_Update__c = false];
            for(User u : userDesktopList){
                    u.DES_First_Login_After_Historic_Update__c = true;
            }
                if(userDesktopList.size()>0 & !Test.isRunningTest()){
                    update userDesktopList;
                }
            }
    }

}