/**
* @description Tests for Arc_Gen_ContentVersion_TrgHandler.
*/
@isTest
private class Arc_Gen_ContentVersion_TrgHandler_Test {
    /** Allowed extensions for testing */
    private static final String ALLOWED_EXTENSIONS = 'png, jpeg, jpg, gif, svg, pdf, docx, xlsx, pptx, doc, xls, ppt';
    /** Maximum file size in megabytes for testing */
    private static final Integer MAX_SIZE_MB = 5;
    /** A sample file path for testing */
    private static final String PATH = 'proposal.pdf';

    @TestSetup
    static void makeData() {
        User testUser = createTestUser();

        PermissionSet proposalFilesPermissionSet = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'ARCE_Proposal_Files'
            LIMIT 1
        ];

        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = proposalFilesPermissionSet.Id
        );
    }

    @isTest
    static void testInsertContentVersionWithValidations() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion(PATH);

            Test.startTest();
            insert contentVersion;
            Test.stopTest();

            Assert.isFalse(contentVersion.hasErrors(), 'Inserting a valid ContentVersion should not add errors');
        }
    }

    /**
    * @description Validates run leaves a valid file without errors.
    */
    @isTest
    static void testRunValidContentVersionNoErrors() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion(PATH);

            Test.startTest();
            new Arc_Gen_ContentVersion_TrgHandler().run(new List<ContentVersion>{ contentVersion });
            Test.stopTest();

            Assert.isFalse(contentVersion.hasErrors(), 'run should not add errors for a valid file');
        }
    }

    /**
    * @description Validates checkMaxSize accepts a file exactly at the configured limit.
    */
    @isTest
    static void testCheckMaxSizeBoundaryNoError() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion(PATH);

            Test.startTest();
            Arc_Gen_ContentVersion_TrgHandler.checkMaxSize(contentVersion, String.valueOf(MAX_SIZE_MB));
            Test.stopTest();

            Assert.isFalse(contentVersion.hasErrors(), 'checkMaxSize should accept files exactly at the size limit');
        }
    }

    /**
    * @description Validates checkExtension accepts allowed extensions regardless of case.
    */
    @isTest
    static void testCheckExtensionAllowedCaseInsensitiveNoError() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion('PROPOSAL.PDF');

            Test.startTest();
            Arc_Gen_ContentVersion_TrgHandler.checkExtension(contentVersion, ALLOWED_EXTENSIONS);
            Test.stopTest();

            Assert.isFalse(contentVersion.hasErrors(), 'checkExtension should accept allowed extensions in any case');
        }
    }

    /**
    * @description Validates checkExtension adds an error for a disallowed extension.
    */
    @isTest
    static void testCheckExtensionInvalidExtensionAddsError() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion('proposal.exe');

            Test.startTest();
            Arc_Gen_ContentVersion_TrgHandler.checkExtension(contentVersion, ALLOWED_EXTENSIONS);
            Test.stopTest();

            Assert.isTrue(
                contentVersion.hasErrors() && contentVersion.getErrors()[0].getMessage() == System.Label.Arc_Gen_NotAllowExtension,
                'checkExtension should add the invalid extension error for disallowed files'
            );
        }
    }

    /**
    * @description Validates checkExtension rejects files without a client path.
    */
    @isTest
    static void testCheckExtensionNullPathAddsError() {
        User testUser = getTestUser();

        System.runAs(testUser) {
            final ContentVersion contentVersion = buildContentVersion(null);

            Test.startTest();
            Arc_Gen_ContentVersion_TrgHandler.checkExtension(contentVersion, ALLOWED_EXTENSIONS);
            Test.stopTest();

            Assert.isTrue(
                contentVersion.hasErrors() && contentVersion.getErrors()[0].getMessage() == System.Label.Arc_Gen_NotAllowExtension,
                'checkExtension should add the invalid extension error when the path is missing'
            );
        }
    }

    /**
    * @description Helper method to build a ContentVersion record for testing.
    * @param pathOnClient The file name with extension to set on the ContentVersion.
    * @return A ContentVersion record with the specified path and size, and a default title and version data.
    */
    private static ContentVersion buildContentVersion(String pathOnClient) {
        final ContentVersion contentVersion = new ContentVersion(
            Title = 'Proposal file',
            PathOnClient = pathOnClient,
            VersionData = Blob.valueOf('test data')
        );

        return contentVersion;
    }

    private static User getTestUser() {
        return [
            SELECT Id
            FROM User
            WHERE Alias = 'arcuser'
            LIMIT 1
        ];
    }

    private static User createTestUser() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        String uniqueValue = String.valueOf(System.currentTimeMillis());

        User testUser = new User(
            FirstName = 'Arc',
            LastName = 'User',
            Alias = 'arcuser',
            Email = 'arcuser' + uniqueValue + '@test.com',
            Username = 'arcuser' + uniqueValue + '@test.com',
            CommunityNickname = 'arcuser' + uniqueValue,
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId = profile.Id
        );

        insert testUser;

        return testUser;
    }
}