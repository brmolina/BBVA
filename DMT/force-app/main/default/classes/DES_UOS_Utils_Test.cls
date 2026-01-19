@isTest 
public with sharing class DES_UOS_Utils_Test {
    @TestSetup
    static void loadTestData() {
        List<User> userTestList = new List<User>();

        User userTest1 = new User();
        userTest1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT'].Id;
        userTest1.FirstName = 'User Name Test 1';
        userTest1.LastName = 'Without Permissions';
        userTest1.Alias = 'ATest1';
        userTest1.Email = 'useremail@test.comm';
        userTest1.username= String.valueof(DateTime.now().getTime()) + 'useremail1@test.comm';
        userTest1.CommunityNickname = 'useremail1@test.comm';
        userTest1.EmailEncodingKey = 'UTF-8';
        userTest1.Timezonesidkey='Europe/London';
        userTest1.Localesidkey ='en_US';
        userTest1.languagelocalekey='en_US';
        userTest1.ID_User__c ='idUserTest'+Integer.valueof((Math.random() * 100000000));
        userTest1.DES_LevelUO_1__c='AA003906';
        userTest1.DES_LevelUO_2__c='AA003906';
        userTest1.DES_LevelUO_3__c='AA080136';
        userTest1.DES_LevelUO_4__c='AA011181';
        userTest1.DES_LevelUO_5__c='00037817';
        userTest1.DES_LevelUO_6__c='AA081237';
        userTest1.DES_LevelUO_7__c='AA081237';
        userTest1.DES_LevelUO_8__c='AA081237';
        userTest1.DES_LevelUO_9__c='AA081237';
        userTest1.DES_LevelUO_10__c='AA081237';

        userTestList.add(userTest1);

        User userTest2 = new User();
        userTest2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT'].Id;
        userTest2.FirstName = 'User Name Test 2';
        userTest2.LastName = 'Without Permissions';
        userTest2.Alias = 'ATest2';
        userTest2.Email = 'useremail@test.comm';
        userTest2.username= String.valueof(DateTime.now().getTime()) + 'useremail2@test.comm';
        userTest2.CommunityNickname = 'useremail2@test.comm';
        userTest2.EmailEncodingKey = 'UTF-8';
        userTest2.Timezonesidkey='Europe/London';
        userTest2.Localesidkey ='en_US';
        userTest2.languagelocalekey='en_US';
        userTest2.ID_User__c ='idUserTest'+Integer.valueof((Math.random() * 100000000));
        userTest2.DES_LevelUO_1__c='00000063';
        userTest2.DES_LevelUO_2__c='AA080136';
        userTest2.DES_LevelUO_3__c='00037703';
        userTest2.DES_LevelUO_4__c='00134629';
        userTest2.DES_LevelUO_5__c='00234629';
        userTest2.DES_LevelUO_6__c='AA011181';
        userTest2.DES_LevelUO_7__c='AA011181';
        userTest2.DES_LevelUO_8__c='AA011181';
        userTest2.DES_LevelUO_9__c='AA011181';
        userTest2.DES_LevelUO_10__c='AA011181';

        userTestList.add(userTest2);

        User userTest3 = new User();
        userTest3.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT'].Id;
        userTest3.FirstName = 'User Name Test 3';
        userTest3.LastName = 'Without Permissions';
        userTest3.Alias = 'ATest3';
        userTest3.Email = 'useremail@test.comm';
        userTest3.username= String.valueof(DateTime.now().getTime()) + 'useremail3@test.comm';
        userTest3.CommunityNickname = 'useremail3@test.comm';
        userTest3.EmailEncodingKey = 'UTF-8';
        userTest3.Timezonesidkey='Europe/London';
        userTest3.Localesidkey ='en_US';
        userTest3.languagelocalekey='en_US';
        userTest3.ID_User__c ='idUserTest'+Integer.valueof((Math.random() * 100000000));
        userTest3.DES_LevelUO_1__c='00080137';
        userTest3.DES_LevelUO_2__c='AA081237';
        userTest3.DES_LevelUO_3__c='00080135';
        userTest3.DES_LevelUO_4__c='AA080136';
        userTest3.DES_LevelUO_5__c='AA011181';
        userTest3.DES_LevelUO_6__c='00006374';
        userTest3.DES_LevelUO_7__c='00025539';
        userTest3.DES_LevelUO_8__c='AA003906';
        userTest3.DES_LevelUO_9__c='AA003906';
        userTest3.DES_LevelUO_10__c='AA080136';

        userTestList.add(userTest3);

        User userTest4 = new User();
        userTest4.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT'].Id;
        userTest4.FirstName = 'User Name Test 4';
        userTest4.LastName = 'Without Permissions';
        userTest4.Alias = 'ATest4';
        userTest4.Email = 'useremail@test.comm';
        userTest4.username= String.valueof(DateTime.now().getTime()) + 'useremail4@test.comm';
        userTest4.CommunityNickname = 'useremail4@test.comm';
        userTest4.EmailEncodingKey = 'UTF-8';
        userTest4.Timezonesidkey='Europe/London';
        userTest4.Localesidkey ='en_US';
        userTest4.languagelocalekey='en_US';
        userTest4.ID_User__c ='idUserTest'+Integer.valueof((Math.random() * 100000000));
        userTest4.DES_LevelUO_1__c='AA003906';
        userTest4.DES_LevelUO_2__c='AA003906';
        userTest4.DES_LevelUO_3__c='AA080136';
        userTest4.DES_LevelUO_4__c='AA011181';
        userTest4.DES_LevelUO_5__c='00037817';
        userTest4.DES_LevelUO_6__c='00981937';
        userTest4.DES_LevelUO_7__c='00081939';
        userTest4.DES_LevelUO_8__c='AA081237';
        userTest4.DES_LevelUO_9__c='AA081237';
        userTest4.DES_LevelUO_10__c='AA081237';

        userTestList.add(userTest4);

        insert userTestList;
    }
    /**
    * @description Test method: method getUsersByUos cant find users by uos
    * @author BBVA DMT | 26-12-2024 
    **/
@isTest
    static void testUsersByUos1(){
        List<User> uList = [SELECT ID, NAME FROM User WHERE Name LIKE '%User Name Test%'];
        System.debug('*** Usuarios *** '+uList);
        List<DES_UOS_Utils.WRAPPER_UOSUSER> filteredUsers = new List<DES_UOS_Utils.WRAPPER_UOSUSER>();
            Test.startTest();    
            filteredUsers = DES_UOS_Utils.getUsersByUos('AA003906');
            Test.stopTest();
        
        System.assertEquals(0, filteredUsers.size(),'Expected dont find user');
    }

    /**
    * @description test method: finding only 1 user by UOs code.
    * @author BBVA DMT | 26-12-2024 
    **/
    @isTest
    static void testUsersByUos2(){
        List<DES_UOS_Utils.WRAPPER_UOSUSER> filteredUsers = new List<DES_UOS_Utils.WRAPPER_UOSUSER>();
            Test.startTest();    
            filteredUsers = DES_UOS_Utils.getUsersByUos('AA011181');
            Test.stopTest();
        
        System.assertEquals(1, filteredUsers.size(),'Non expected user found or more tha one user found');
    }

    /**
    * @description Test method: it will find two users by uos
    * @author BBVA DMT | 26-12-2024 
    **/
    @isTest
    static void testUsersByUos3(){
        List<DES_UOS_Utils.WRAPPER_UOSUSER> filteredUsers = new List<DES_UOS_Utils.WRAPPER_UOSUSER>();
            Test.startTest();    
            filteredUsers = DES_UOS_Utils.getUsersByUos('AA081237');
            Test.stopTest();
        
        System.assertEquals(2, filteredUsers.size(),'Expected two users found');
    }

    /**
    * @description test find user without uos code repeated, code only in the last level field
    * @author BBVA DMT | 26-12-2024 
    **/
    @isTest
    static void testUsersByUos4(){
        List<DES_UOS_Utils.WRAPPER_UOSUSER> filteredUsers = new List<DES_UOS_Utils.WRAPPER_UOSUSER>();
            Test.startTest();    
            filteredUsers = DES_UOS_Utils.getUsersByUos('AA080136');
            Test.stopTest();
        
        System.assertEquals(1, filteredUsers.size(),'Non expected user found');
    }

    //TODO: Mas variedad de pruebas busqueda por nivel, que encuentre usuarios de uos pero no del nivel busado
    @isTest
    static void testUsersByUosAndLevel(){
        DES_UOS_Utils des = new DES_UOS_Utils();
        List<User> filteredUsers = new List<User>();
            Test.startTest();    
            filteredUsers = des.getUsersByUosAndUOLevel('AA081237',6);
            Test.stopTest();
        
        System.assertEquals(1, filteredUsers.size(),'Non expected user found');
    }

    @isTest
    static void testUsersByUosAndLevel2(){
        DES_UOS_Utils des = new DES_UOS_Utils();
        List<User> filteredUsers = new List<User>();
            Test.startTest();    
            filteredUsers = des.getUsersByUosAndUOLevel('AA081237',7);
            Test.stopTest();
        
        System.assertEquals(0, filteredUsers.size(),'Non expected user found');
    }
}