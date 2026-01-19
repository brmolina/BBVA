@isTest
public class DMT_AttachmentControllerTest {
    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateTestTreasuryLines();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateCase(null,opp.Id,UserInfo.getUserId());

    }

    @isTest
    static void testAttachmentOperations() {

        // Crear un registro de línea
        DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c LIMIT 1];

        // Crear un Attachment de prueba
        Attachment att = new Attachment(
            ParentId = line.Id,
            Name = 'TestFile.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Dummy content')
        );
        insert att;

        // Test getAttachments
        Test.startTest();
        List<DMT_AttachmentController.AttachmentWrapper> result = DMT_AttachmentController.getAttachments(line.Id);
        System.assertEquals(1, result.size());
        System.assertEquals('TestFile.pdf', result[0].name);

        // Test uploadAttachment
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('New file content'));
        
        DMT_AttachmentController.uploadAttachment(line.Id, 'NewUpload.txt', base64Data);
        

        List<Attachment> uploaded = [SELECT Name FROM Attachment WHERE ParentId = :line.Id];
        System.assert(uploaded.size() > 1);

        // Test deleteAttachment
        
        DMT_AttachmentController.deleteAttachment(att.Id);
        Test.stopTest();

        Attachment deleted = [SELECT Id, IsDeleted FROM Attachment WHERE Id = :att.Id ALL ROWS];
        System.assertEquals(true, deleted.IsDeleted);
    }

    @isTest
    static void testHasEditAccess_owner() {
        DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c LIMIT 1];

        Test.startTest();
        Boolean result = DMT_AttachmentController.hasEditAccess(line.Id);
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @isTest
    static void testHasEditAccess_teamMember() {

        DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c LIMIT 1];

        // Miembro con acceso Edit
        DMT_TeamMember__c member = new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = line.OwnerId,
            AccessLevel__c = 'Edit'
        );
        insert member;

        Test.startTest();
        Boolean result = DMT_AttachmentController.hasEditAccess(line.Id);
        Test.stopTest();
        System.assertEquals(true, result);
    }
    @isTest
    static void testHasEditAccess_ownerOpportunity() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];

        Test.startTest();
        Boolean result = DMT_AttachmentController.hasEditAccess(opp.Id);
        Test.stopTest();
        System.assertEquals(true, result);
    }
    @isTest
    static void testHasEditAccess_teamMemberOpportunity() {

        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];

        // Miembro con acceso Edit
        DMT_TeamMember__c member = new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = opp.OwnerId,
            AccessLevel__c = 'Edit'
        );
        insert member;

        Test.startTest();
        Boolean result = DMT_AttachmentController.hasEditAccess(opp.Id);
        Test.stopTest();
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testAttachmentOpportunity() {

        // Crear un registro de línea
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];

        // Crear un Attachment de prueba
        Attachment att = new Attachment(
            ParentId = opp.Id,
            Name = 'TestFile.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Dummy content')
        );
        insert att;

        // Test getAttachments
        Test.startTest();
        List<DMT_AttachmentController.AttachmentWrapper> result = DMT_AttachmentController.getAttachments(opp.Id);
        System.assertEquals(1, result.size());
        System.assertEquals('TestFile.pdf', result[0].name);

        // Test uploadAttachment
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('New file content'));
        
        DMT_AttachmentController.uploadAttachment(opp.Id, 'NewUpload.txt', base64Data);
        

        List<Attachment> uploaded = [SELECT Name FROM Attachment WHERE ParentId = :opp.Id];
        System.assert(uploaded.size() > 1);

        // Test deleteAttachment
        
        DMT_AttachmentController.deleteAttachment(att.Id);
        Test.stopTest();

        Attachment deleted = [SELECT Id, IsDeleted FROM Attachment WHERE Id = :att.Id ALL ROWS];
        System.assertEquals(true, deleted.IsDeleted);
    }
    @isTest
    static void testHasEditAccess_ownerCase() {
        Case caso = [SELECT Id, OwnerId FROM Case LIMIT 1];

        Test.startTest();
        Boolean result = DMT_AttachmentController.hasEditAccess(caso.Id);
        Boolean resultRole = DMT_AttachmentController.hasEditCaseRole('RoleTest');
        Test.stopTest();
        System.assertEquals(true, result);
    }
    
    
    @isTest
    static void testAttachmentCase() {

        // Crear un registro de línea
        Case caso = [SELECT Id, OwnerId FROM Case LIMIT 1];

        // Crear un Attachment de prueba
        Attachment att = new Attachment(
            ParentId = caso.Id,
            Name = 'TestFile.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Dummy content')
        );
        insert att;

        // Test getAttachments
        Test.startTest();
        List<DMT_AttachmentController.AttachmentWrapper> result = DMT_AttachmentController.getAttachments(caso.Id);
        System.assertEquals(1, result.size());
        System.assertEquals('TestFile.pdf', result[0].name);

        // Test uploadAttachment
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('New file content'));
        
        DMT_AttachmentController.uploadAttachment(caso.Id, 'NewUpload.txt', base64Data);
        

        List<Attachment> uploaded = [SELECT Name FROM Attachment WHERE ParentId = :caso.Id];
        System.assert(uploaded.size() > 1);

        // Test deleteAttachment
        
        DMT_AttachmentController.deleteAttachment(att.Id);
        Test.stopTest();

        Attachment deleted = [SELECT Id, IsDeleted FROM Attachment WHERE Id = :att.Id ALL ROWS];
        System.assertEquals(true, deleted.IsDeleted);
    }
}