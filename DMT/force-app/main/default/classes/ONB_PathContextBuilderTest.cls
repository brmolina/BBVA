@isTest
private class ONB_PathContextBuilderTest {

    private static String getAnyPicklistValue(Schema.SObjectField fieldRef) {
        List<Schema.PicklistEntry> vals = fieldRef.getDescribe().getPicklistValues();
        return vals.isEmpty() ? null : vals[0].getValue();
    }

     @IsTest
    static void buildForOnboarding_shouldReturnContextAndOnboarding() {

        String stepValue = getAnyPicklistValue(ONB_Onboarding__c.Step__c);
        System.assertNotEquals(null, stepValue);
        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Name = 'Test Onboarding',
            Step__c = stepValue,
            Any_Master_Agreement__c = 'Yes',
            ONB_Onboarding_Client_Type__c = 'Bank'
        );
        insert onb;

        Test.startTest();
            ONB_PathContextBuilder.BuildResult result = ONB_PathContextBuilder.buildForOnboarding(onb.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.ctx);
        System.assertNotEquals(null, result.onboarding);

        // Validar que el onboarding retornado es el correcto
        System.assertEquals(onb.Id, result.onboarding.Id);
        System.assertEquals(stepValue, result.onboarding.Step__c);
        System.assertEquals('Yes', result.onboarding.Any_Master_Agreement__c);
        System.assertEquals('Bank', result.onboarding.ONB_Onboarding_Client_Type__c);
        System.assert(result.ctx.containsKey('ONB_Onboarding__c'));

        ONB_Onboarding__c ctxOnb = (ONB_Onboarding__c) result.ctx.get('ONB_Onboarding__c');

        System.assertEquals(onb.Id, ctxOnb.Id);
    }
}