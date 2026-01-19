@IsTest
private class DES_Batch_BBVAManualSharing_Test {

    private static User createUser(String profileTest, boolean high, boolean medium, boolean low, String notType, Integer intCount) {
        User userTest;
        userTest = new User();
        userTest.ProfileId = profileTest;
        userTest.FirstName = 'User Name Test'+intCount;
        userTest.LastName = 'User Last Name Test'+intCount;
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail'+intCount+'@test.comm';
        userTest.ID_User__c = string.valueOf(system.now() - Math.abs(Math.random()*10));
        userTest.FederationIdentifier = userTest.ID_User__c;
        userTest.username= 'useremail'+intCount+DateTime.now().getTime()+'@test.comm';
        userTest.CommunityNickname = 'ComunityNickNameTest2'+intCount;
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        userTest.almd__notification_priority_high_type__c = high;
        userTest.almd__notification_priority_low_type__c = medium;
        userTest.almd__notification_priority_med_type__c = low;
        userTest.almd__alert_notification_type__c = notType;
        userTest.DES_Disable_Chatter__c = false;
        userTest.IsActive = true;
        return userTest;
    }

    private static Account createClient(Id recordType, String code) {
        Account acc;
        acc = new Account();
        acc.Name = 'Test Client';
        acc.Phone = '646171717';
        acc.DES_Revenue_Update_Engloba__c = '20180912';
        acc.RecordTypeId = recordType;
        acc.DES_Group_Code__c = code;
        acc.SER_CClient__c = code;
        return acc;
    }

    @testSetup
    static void setup(){
        Test.startTest();
        Profile sysAdminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];
        Id subsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        Id groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        List<Account> lAccs = new List<Account>();
        Account acc = createClient(groupRT, 'GC000011');
        lAccs.add(acc);
        Account acc2 = createClient(subsidiaryRT, 'S000011');
        lAccs.add(acc2);
        insert lAccs;
        
        List<User> lUser = new List<User>();
        User user1 = createUser(sysAdminProfile.Id, true, true, true, 'One to One',1);
        lUser.add(user1);
        User user2 = createUser(sysAdminProfile.Id, true, true, false, 'One to One',2);
        lUser.add(user2);
        insert lUser;

        DES_Subsidiary_Group_Relation__c matrix;
        matrix = new DES_Subsidiary_Group_Relation__c();
        matrix.participant_child_id__c = acc2.Id;
        matrix.main_subsidiary_ind_type__c = true;
        matrix.participant_parent_id__c = acc.Id;
        insert matrix;

        DES_BBVA_Management_team__c bbvaMT = new DES_BBVA_Management_team__c();
        bbvaMT.DES_Client__c = acc.Id;
        bbvaMT.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        bbvaMT.DES_Local_Banker_Country__c = 'AR';
        bbvaMT.DES_User__c = user2.Id;
        insert bbvaMT;
        Test.stopTest();
    }
    
    @IsTest
    static void test_Batch_Start_Execute_Finish_withLimit1() {
        User adminUser = [SELECT Id, ProfileId, Alias, Email, Username, LastName, FirstName, CommunityNickname, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
                          FROM User
                          WHERE Profile.Name = 'System Administrator' AND IsActive = true
                          LIMIT 1];

        System.runAs(adminUser) {

            Test.startTest();
            Id jobId = Database.executeBatch(new DES_Batch_BBVAManualSharing(), 1);
            Test.stopTest();
            
            AsyncApexJob job = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                FROM AsyncApexJob
                WHERE Id = :jobId
                LIMIT 1
            ];

            System.assertEquals('Completed', String.valueOf(job.Status),
                'El job del batch debe completar correctamente');
            System.assertEquals(0, job.NumberOfErrors,
                'El batch no debería registrar errores');
            System.assertEquals(1, job.JobItemsProcessed,
                'Debe procesarse exactamente 1 lote por el LIMIT 1 en tests');
            System.assertEquals(1, job.TotalJobItems,
                'Total de lotes esperados = 1 por el LIMIT 1 en tests');
        }
    }
}