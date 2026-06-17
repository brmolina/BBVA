/**
* @description Test class for Arc_Gen_ArceCore_Constants.
*/
@isTest
private class Arc_Gen_ArceCore_Constants_Test {
    /**
    * @description Validates string constants (COLON_SPACE, SPACE_PIPE_SPACE, etc.) are correctly defined.
    */
    @isTest
    static void testStringConstantsNotNull() {
        Test.startTest();
        final String colonSpace = Arc_Gen_ArceCore_Constants.COLON_SPACE;
        final String spacePipe = Arc_Gen_ArceCore_Constants.SPACE_PIPE_SPACE;
        final String spaceDash = Arc_Gen_ArceCore_Constants.SPACE_DASH_SPACE;
        final String backDot = Arc_Gen_ArceCore_Constants.BACKSLASHES_DOT;
        final String alphaMeta = Arc_Gen_ArceCore_Constants.ALPHAMETA;
        final String dataConst = Arc_Gen_ArceCore_Constants.DATA;
        Test.stopTest();

        Assert.isTrue(colonSpace.equals(': ') &&
                      spacePipe.equals(' | ') &&
                      spaceDash.equals(' - ') &&
                      backDot.equals('\\.') &&
                      alphaMeta.equals('AlphaCode') &&
                      dataConst.equals('data'),
            'All string constants should match their expected values');
    }

    /**
    * @description Validates identifier constants (BANK_BRANCH_L_ID, BANK_ID, etc.) are non-blank.
    */
    @isTest
    static void testIdentifierConstantsAccessible() {
        Test.startTest();
        final String bankBranchLId = Arc_Gen_ArceCore_Constants.BANK_BRANCH_L_ID;
        final String bankBranchId = Arc_Gen_ArceCore_Constants.BANK_BRANCH_ID;
        final String bankId = Arc_Gen_ArceCore_Constants.BANK_ID;
        final String businessAgent = Arc_Gen_ArceCore_Constants.BUSINESS_AGENT_ID;
        final String participantId = Arc_Gen_ArceCore_Constants.PARTICIPANT_ID;
        final String economicGrpId = Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID;
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(bankBranchLId) &&
                      String.isNotBlank(bankBranchId) &&
                      String.isNotBlank(bankId) &&
                      String.isNotBlank(businessAgent) &&
                      String.isNotBlank(participantId) &&
                      String.isNotBlank(economicGrpId),
            'All identifier constants should be non-blank');
    }

    /**
    * @description Validates status constants (SUCCESS, ACTIVE, VOID_METHOD, etc.) match expected values.
    */
    @isTest
    static void testStatusConstantsExpectedValues() {
        Test.startTest();
        final String success = Arc_Gen_ArceCore_Constants.SUCCESS;
        final String badResp = Arc_Gen_ArceCore_Constants.ASSERT_BAD_RESP;
        final String active = Arc_Gen_ArceCore_Constants.ACTIVE;
        final String voidMethod = Arc_Gen_ArceCore_Constants.VOID_METHOD;
        Test.stopTest();

        Assert.isTrue(success.equals('SUCCESS') &&
                      badResp.equals('Bad response') &&
                      active.equals('ACTIVE') &&
                      voidMethod.equals('void method'),
            'All status constants should match their expected values');
    }

    /**
    * @description Validates analysis constants (REL_PARENT_SUBS, MOD_REN_VAR, MONOGROUP, etc.) are correct.
    */
    @isTest
    static void testAnalysisConstantsAccessible() {
        Test.startTest();
        final String relParentSubs = Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS;
        final String modRenVar = Arc_Gen_ArceCore_Constants.MOD_REN_VAR;
        final String newSubsStr = Arc_Gen_ArceCore_Constants.NEW_SUBS_STR;
        final String analysisId = Arc_Gen_ArceCore_Constants.ANALYSIS_ID;
        final String monoOn = Arc_Gen_ArceCore_Constants.MONOGROUP_ON;
        final String monoOff = Arc_Gen_ArceCore_Constants.MONOGROUP_OFF;
        Test.stopTest();

        Assert.isTrue(relParentSubs.equals('relationParentSubsidiary') &&
                      modRenVar.equals('modRenVar') &&
                      newSubsStr.equals('newFilialesStr') &&
                      analysisId.equals('analysisId') &&
                      monoOn.equals('1') &&
                      monoOff.equals('2'),
            'All analysis constants should match their expected values');
    }
}