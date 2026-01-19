@isTest
/**
*
*
* @author Global Desktop
*/
public class RiskInformation_Test {
    /**
    *
    *
    * @author Global Desktop
    */
    @isTest
    public static void riskInformationTest1() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        final CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest1) {
        	final Account acc = utilTestClass.createClient();
        	insert acc;
        	Test.startTest();
        	final List<Consumo_de_Linea__c> listaRisk = RiskInformation.getRiskAccount((String)acc.Id);
            system.assertNotEquals(NULL, listaRisk, 'fallo');
        	Test.stopTest();
        }
    }
    /**
    *
    *
    * @author Global Desktop
    */
    @isTest
    public static void riskInformationTest2() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        final CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest1) {
        	final Account acc = utilTestClass.createClient();
        	insert acc;
        	Test.startTest();
            final List<AggregateResult> listaRisk2 = RiskInformation.getMaxConsumo((String)acc.Id);
            system.assertNotEquals(NULL, listaRisk2, 'fallo');
        	Test.stopTest();
        }
    }
    /**
    *
    *
    * @author Global Desktop
    */
    @isTest
    public static void riskInformationTest3() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        final CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest1) {
        	final Account acc = utilTestClass.createClient();
        	insert acc;
        	Test.startTest();
            final List<Consumo_de_Linea__c> listaRisk3 = RiskInformation.getRisklimit((String)acc.Id);
            system.assertNotEquals(NULL, listaRisk3, 'fallo');
        	Test.stopTest();
        }
    }
}