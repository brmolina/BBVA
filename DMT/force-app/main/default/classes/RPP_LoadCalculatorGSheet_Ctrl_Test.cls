/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Container_Ctrl_Test
* Test class for RPP_LoadCalculatorGSheet_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-05-08
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class RPP_LoadCalculatorGSheet_Ctrl_Test {
    @testSetup
    private static void testSetup() {
        List <igoogle__Google_Active_Configuration__c> configurations = new List <igoogle__Google_Active_Configuration__c>();
        igoogle__Google_Active_Configuration__c gdrive = new igoogle__Google_Active_Configuration__c();
        gdrive.Name = 'GDriveDEV';
        gdrive.igoogle__Service_Type__c = 'GDrive';
        configurations.add (gdrive);
        igoogle__Google_Active_Configuration__c gsheets = new igoogle__Google_Active_Configuration__c();
        gsheets.Name = 'GSheetsDEV';
        gsheets.igoogle__Service_Type__c = 'GSheets';
        configurations.add (gsheets);
        insert configurations;
    }
    @IsTest
    static void testInitialData(){   
        Id profileId = userinfo.getProfileId();
        Profile profile = [SELECT Id, Name FROM Profile where Id = :profileId];
        User testUser = TestFactory.createUser('testUserNameRPP', profile.Name);        
        Test.startTest();
            Map<String, Object> retMap = new Map<String, Object>();
            System.runAs(testUser) {
                retMap = RPP_LoadCalculatorGSheet_Ctrl.initialData();
            }
            System.assertEquals(retMap.get('hasPermission'), false,'testInitialData - OK');
        Test.stopTest();
    }
    @IsTest
    static void testLoadGSheetDataOK(){   
        Id profileId = userinfo.getProfileId();
        Profile profile = [SELECT Id, Name FROM Profile where Id = :profileId];
        User testUser = TestFactory.createUser('testUserNameRPP', profile.Name);        
        gsheets__GSheets_Config__c gSheetsConfig = new gsheets__GSheets_Config__c();
        gSheetsConfig.Name = testUser.Username;
        gSheetsConfig.gsheets__Asynchronous_Execution__c = true;
        gSheetsConfig.gsheets__Batch_Size__c = 200;
        gSheetsConfig.gsheets__FileId__c = 'Test01';
        gSheetsConfig.gsheets__GDrive_Processed_Files_Folder_Id__c = 'Test02';
        gSheetsConfig.gsheets__GSheet_Key_Fields__c = 'FIELD01';
        gSheetsConfig.gsheets__Object__c = 'RPP_Calculator_Google_Sheet_Log__c';
        gSheetsConfig.gsheets__Read_from_Drive_Path__c = true;
        gSheetsConfig.gsheets__SF_Key_Field__c = 'External_Id__c';
        gSheetsConfig.gsheets__Tab_Name__c = 'SALESFORCE';
        gSheetsConfig.gsheets__Transformation_Data_Class__c = 'RPP_Calculator_GSheets_Transformation';
        insert gSheetsConfig;
        Test.setMock(HttpCalloutMock.class, new RPP_GSheets_Mock_Generator());
        igoogle.IGoogle_Mock.setMock(new RPP_GSheets_Mock_Generator());
        Test.startTest();
            System.runAs(testUser) {
                RPP_LoadCalculatorGSheet_Ctrl.loadGSheetData();
            }
            List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogs = [SELECT Id FROM RPP_Calculator_Google_Sheet_Log__c];
            System.assertEquals(RPPCalculatorGoogleSheetLogs.size(), 0,'testLoadGSheetDataOK - OK');
        Test.stopTest();
    }
    @IsTest
    static void testLoadGSheetDataNOK(){   
        Id profileId = userinfo.getProfileId();
        Profile profile = [SELECT Id, Name FROM Profile where Id = :profileId];
        User testUser = TestFactory.createUser('testUserNameRPP', profile.Name);        
        gsheets__GSheets_Config__c gSheetsConfig = new gsheets__GSheets_Config__c();
        gSheetsConfig.Name = 'TEST';
        gSheetsConfig.gsheets__Asynchronous_Execution__c = true;
        gSheetsConfig.gsheets__Batch_Size__c = 200;
        gSheetsConfig.gsheets__FileId__c = 'Test01';
        gSheetsConfig.gsheets__GDrive_Processed_Files_Folder_Id__c = 'Test02';
        gSheetsConfig.gsheets__GSheet_Key_Fields__c = 'FIELD01';
        gSheetsConfig.gsheets__Object__c = 'RPP_Calculator_Google_Sheet_Log__c';
        gSheetsConfig.gsheets__Read_from_Drive_Path__c = true;
        gSheetsConfig.gsheets__SF_Key_Field__c = 'External_Id__c';
        gSheetsConfig.gsheets__Tab_Name__c = 'SALESFORCE';
        gSheetsConfig.gsheets__Transformation_Data_Class__c = 'RPP_Calculator_GSheets_Transformation';
        insert gSheetsConfig;
        Test.setMock(HttpCalloutMock.class, new RPP_GSheets_Mock_Generator());
        igoogle.IGoogle_Mock.setMock(new RPP_GSheets_Mock_Generator());
        Test.startTest();
            System.runAs(testUser) {
                RPP_LoadCalculatorGSheet_Ctrl.loadGSheetData();
            }
            List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogs = [SELECT Id FROM RPP_Calculator_Google_Sheet_Log__c];
            System.assertEquals(RPPCalculatorGoogleSheetLogs.size(), 0,'testLoadGSheetDataNOK - OK');
        Test.stopTest();
    }
}