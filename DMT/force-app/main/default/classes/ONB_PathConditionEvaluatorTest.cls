@isTest
private class ONB_PathConditionEvaluatorTest {

    @IsTest
    static void evaluate_shouldReturnTrue_whenConditionBlank() {
        Map<String, Object> ctx = new Map<String, Object>();
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate(null, ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('', ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('   ', ctx));
    }

    @IsTest
    static void evaluate_shouldHandleNullContext() {
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('x=true', null));
    }

    @IsTest
    static void evaluate_shouldSupportSimpleKeyEquals() {
        Map<String, Object> ctx = new Map<String, Object>{
            'status' => 'OPEN'
        };

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('status=OPEN', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('status=CLOSED', ctx));

        // String compare es case-sensitive
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('status=open', ctx));

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('status!=CLOSED', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('status!=OPEN', ctx));
    }

    @IsTest
    static void evaluate_shouldSupportAndGroups() {
        Map<String, Object> ctx = new Map<String, Object>{
            'a' => '1',
            'b' => '2'
        };

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('a=1&b=2', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('a=1&b=3', ctx));
    }

    @IsTest
    static void evaluate_shouldSupportOrWithinGroup() {
        Map<String, Object> ctx = new Map<String, Object>{
            'country' => 'ES'
        };

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('country=UK|country=ES', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('country=UK|country=FR', ctx));
    }

    @IsTest
    static void evaluate_shouldSupportAndWithOrGroups() {
        Map<String, Object> ctx = new Map<String, Object>{
            'country' => 'ES',
            'segment' => 'BANK'
        };

        // (country=UK OR country=ES) AND (segment=BANK OR segment=AM)
        System.assertEquals(
            true,
            ONB_PathConditionEvaluator.evaluate('country=UK|country=ES&segment=BANK|segment=AM', ctx)
        );

        // Falla el segundo grupo
        System.assertEquals(
            false,
            ONB_PathConditionEvaluator.evaluate('country=UK|country=ES&segment=FUND', ctx)
        );
    }

    @IsTest
    static void evaluate_shouldCompareBooleans_caseInsensitive() {
        Map<String, Object> ctx = new Map<String, Object>{
            'flag' => true,
            'flag2' => false
        };

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('flag=true', ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('flag=TrUe', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('flag=false', ctx));

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('flag2=false', ctx));
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('flag2=true', ctx));
    }

    @IsTest
    static void evaluate_shouldCompareNumbers() {
        Map<String, Object> ctx = new Map<String, Object>{
            'n1' => 5,
            'n2' => 5.0,              // Decimal
            'n3' => (Long) 10
        };

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('n1=5', ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('n2=5', ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('n3=10', ctx));

        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('n1=6', ctx));

        // Right no parseable como Decimal => cae al fallback string compare
        // String.valueOf(5) = '5' y right='5a' => false
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('n1=5a', ctx));
    }

    private static String getAnyPicklistValue(Schema.SObjectField fieldRef) {
        List<Schema.PicklistEntry> vals = fieldRef.getDescribe().getPicklistValues();
        return vals.isEmpty() ? null : vals[0].getValue();
    }

    @IsTest
    static void evaluate_shouldResolveSObjectDotNotation() {
        String stepValue = getAnyPicklistValue(ONB_Onboarding__c.Step__c);
        System.assertNotEquals(null, stepValue, 'Step__c no tiene valores de picklist disponibles');

        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Name = 'Test Onb',
            Step__c = stepValue,
            Any_Master_Agreement__c = 'Yes',
            ONB_Onboarding_Client_Type__c = 'Bank'
        );
        insert onb;

        ONB_Onboarding__c onbDb = [
            SELECT Id, Step__c, Any_Master_Agreement__c, ONB_Onboarding_Client_Type__c
            FROM ONB_Onboarding__c
            WHERE Id = :onb.Id
        ];

        Map<String, Object> ctx = new Map<String, Object>{
            'ONB_Onboarding__c' => onbDb
        };

        System.assertEquals(
            true,
            ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.Step__c=' + stepValue, ctx)
        );

        System.assertEquals(
            false,
            ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.Step__c=___NON_EXISTENT___', ctx)
        );

        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.Any_Master_Agreement__c=Yes', ctx));
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.ONB_Onboarding_Client_Type__c=Bank', ctx));

        System.assertEquals(
            true,
            ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.Any_Master_Agreement__c!=No', ctx)
        );
        System.assertEquals(
            false,
            ONB_PathConditionEvaluator.evaluate('ONB_Onboarding__c.Any_Master_Agreement__c!=Yes', ctx)
        );
    }


    @IsTest
    static void evaluate_shouldReturnFalse_onMalformedClauses() {
        Map<String, Object> ctx = new Map<String, Object>{ 'a' => '1' };

        // sin '='
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('a', ctx));

        // demasiados '=' (split devuelve >2 => parts.size != 2)
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('a=1=2', ctx));

        // left vacío
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('=1', ctx));

        // right vacío
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('a=', ctx));

        // left inválido por '!'
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('a!=1=2', ctx));

        // operador duplicado
        System.assertEquals(false, ONB_PathConditionEvaluator.evaluate('a!=1!=2', ctx));
    }

    @IsTest
    static void evaluate_shouldIgnoreEmptyGroupsAndClauses() {
        Map<String, Object> ctx = new Map<String, Object>{ 'a' => '1' };

        // Grupos vacíos deben ignorarse, y el resultado debe depender de lo que queda
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate('  & a=1 &  ', ctx));

        // Clausulas vacías dentro de OR deben ignorarse
        System.assertEquals(true, ONB_PathConditionEvaluator.evaluate(' | a=1 | ', ctx));
    }
}