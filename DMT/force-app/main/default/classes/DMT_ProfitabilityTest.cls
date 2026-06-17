@isTest
public with sharing class DMT_ProfitabilityTest {
    @TestSetup
    static void setUp() {
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateTaxonomies();
        DMT_Test_DataFactory.generateOpportunity();

    }

    @isTest
    static void testOrderCatalogs_Handler() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'test' => new List<Object>{
                new Map<String, Object>{'label' => 'B', 'orden' => 2},
                new Map<String, Object>{'label' => 'A', 'orden' => 1},
                new Map<String, Object>{'label' => 'C', 'orden' => null}
            }
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Object result = (new DMT_Profitability_Handler()).call('orderCatalogs', args);

        List<Object> sorted = (List<Object>)((Map<String, Object>)result).get('test');
        System.assertEquals('A', ((Map<String, Object>)sorted[0]).get('label'));
        System.assertEquals('B', ((Map<String, Object>)sorted[1]).get('label'));
        System.assertEquals('C', ((Map<String, Object>)sorted[2]).get('label'));
    }

    @isTest
    static void testGetTaxonomyValues() {
        List<DMT_Taxonomy_Values__c> values = DMT_Profitability_Helper.getTaxonomyValues();
        System.assertNotEquals(null, values);
    }

    @isTest
    static void testCalculateIsPercentageValue() {
        DMT_Profitability_Axis__c axis = new DMT_Profitability_Axis__c(
            gf_axis_data_type_desc__c = 'TestAxis',
            gf_percentage_1_sign_type__c = true
        );
        insert axis;

        Map<String, Boolean> result = DMT_Profitability_Helper.calculateIsPercentageValue('TestAxis', '', '');
        System.assertEquals(true, result.get('x'),'Deberia devolver true para el eje X');
        System.assertEquals(false, result.get('y'),'Deberia devolver false para el eje Y');
        System.assertEquals(false, result.get('c'),'Deberia devolver false para el eje Central');
    }

    @isTest
    static void testCallProfitabilityMatrix_Handler() {
        // ratingCatalog simulado
        List<Object> ratingCatalog = new List<Object>{
            new Map<String, Object>{'value' => 'AAA', 'orden' => 1},
            new Map<String, Object>{'value' => 'AA', 'orden' => 2}
        };

        Map<String, Object> overrideFields = new Map<String, Object>{
            'entificNew' => 'ENT123',
            'bookingNew' => 'BOOK1',
            'clientTypeNew' => 'Corporate',
            'intClientRatingNew' => 'AAA',
            'extClientRatingNew' => 'AA',
            'startDateNew' => Date.today(),
            'endDateNew' => Date.today().addYears(1),
            'countryRiskNew' => 'Spain',
            'countryRatingNew' => 'AA',
            'currencyNew' => 'EUR',
            'amortizationTypeNew' => 'Linear',
            'paymentFrequencyNew' => 'Monthly',
            'paymentDateNew' => Date.today().addMonths(1),
            'nominalAmountNew' => 100000,
            'nominalFbNew' => 95000,
            'spreadAmountNew' => 150,
            'spreadFbNew' => 120,
            'nonaccrualfeeNew' => 500,
            'accrualfeeNew' => 50
        };

        Map<String, Object> input = new Map<String, Object>{
            'oppId' => '006XXXXXXXXXXXX',
            'version' => '1',
            'prodId' => '01tXXXXXXXXXXXX',
            'axisX' => 'Tenor',
            'axisY' => 'Rating',
            'axisCentral' => 'Spread',
            'minX' => '1000',
            'maxX' => '5000',
            'minY' => '1000',
            'maxY' => '2000',
            'xminString' => 'AAA',
            'xmaxString' => 'AAA',
            'yminString' => 'AAA',
            'ymaxString' => 'AAA',
            'catalogRating' => ratingCatalog,
            'overrideFields' => overrideFields
        };

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Profitability_Handler()).call('callProfitabilityMatrix', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assert(resultMap.containsKey('result'));
    }
     @isTest
    static void testCallProfitabilityMatrix_HandlerFormatException() {
        // ratingCatalog simulado
        List<Object> ratingCatalog = new List<Object>{
            new Map<String, Object>{'value' => 'AAA', 'orden' => 1},
            new Map<String, Object>{'value' => 'AA', 'orden' => 2}
        };

        Map<String, Object> overrideFields = new Map<String, Object>{
            'entificNew' => 'ENT123',
            'bookingNew' => 'BOOK1',
            'clientTypeNew' => 'Corporate',
            'intClientRatingNew' => 'AAA',
            'extClientRatingNew' => 'AA',
            'startDateNew' => Date.today().format(),
            'endDateNew' => Date.today().addYears(1),
            'countryRiskNew' => 'Spain',
            'countryRatingNew' => 'AA',
            'currencyNew' => 'EUR',
            'amortizationTypeNew' => 'Linear',
            'paymentFrequencyNew' => 'Monthly',
            'paymentDateNew' => Date.today().addMonths(1),
            'nominalAmountNew' => 100000,
            'nominalFbNew' => 95000,
            'spreadAmountNew' => 150,
            'spreadFbNew' => 120,
            'nonaccrualfeeNew' => 500,
            'accrualfeeNew' => 50
        };

        Map<String, Object> input = new Map<String, Object>{
            'oppId' => '006XXXXXXXXXXXX',
            'version' => '1',
            'prodId' => '01tXXXXXXXXXXXX',
            'axisX' => 'Tenor',
            'axisY' => 'Rating',
            'axisCentral' => 'Spread',
            'minX' => '1000',
            'maxX' => '5000',
            'minY' => '1000',
            'maxY' => '2000',
            'xminString' => 'AAA',
            'xmaxString' => 'AAA',
            'yminString' => 'AAA',
            'ymaxString' => 'AAA',
            'catalogRating' => ratingCatalog,
            'overrideFields' => overrideFields
        };

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Profitability_Handler()).call('callProfitabilityMatrix', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals(false, ((Map<String, Object>)result).get('result'));
        System.assertEquals('Invalid date format for overridefield: startDateNew. Value: ' + Date.today().format(), ((Map<String, Object>)result).get('message'));
    }
    @isTest
    static void testInvokeMethod_Exception() {
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Object result = (new DMT_Profitability_Handler()).call('noExiste', args);

        System.assertEquals(null, ((Map<String, Object>)result).get('result'));
    }

    @isTest
    static void testGetPassportByOpp() {
        // Test 1: Normal case - Passport exists for opportunity
        final Opportunity opp = [SELECT ID,DMT_Opp_Id__c, Name FROM Opportunity WHERE RecordType.DeveloperName='DMT_Opportunity' LIMIT 1];
        Test.startTest();
        final Passport__c result = DMT_Profitability_Helper.getPassportByOpp(opp.DMT_Opp_Id__c);
        System.assert(!result.DMT_Is_Obsoleted_Passport_Save__c,'Error, expected non obsolerted passport');
        Test.stopTest();
        
    }    

    @IsTest
    static void testCallOrderCatalogs_ordersByOrden() {

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{ 'label' => 'C', 'value' => 'C', 'orden' => 3 },
            new Map<String, Object>{ 'label' => 'A', 'value' => 'A', 'orden' => 1 },
            new Map<String, Object>{ 'label' => 'NR', 'value' => 'NR', 'orden' => 2 }
        };

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_Helper.callOrderCatalogs(items);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe devolver un mapa');
        List<Object> out = (List<Object>) result.get('data');
        System.assertEquals(3, out.size(), 'Debe devolver los 3 elementos');

        Map<String, Object> first  = (Map<String, Object>) out[0];
        Map<String, Object> second = (Map<String, Object>) out[1];
        Map<String, Object> third  = (Map<String, Object>) out[2];

        System.assertEquals(1, (Integer) first.get('orden'), 'Primero debe ser orden=1');
        System.assertEquals(2, (Integer) second.get('orden'), 'Segundo debe ser orden=2');
        System.assertEquals(3, (Integer) third.get('orden'), 'Tercero debe ser orden=3');
    }
    

}