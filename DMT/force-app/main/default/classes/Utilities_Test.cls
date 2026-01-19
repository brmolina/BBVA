@isTest
private class Utilities_Test {
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    private static Account accMX = new Account();
    private static Account accES = new Account();
    private static Pricebook2 p = new Pricebook2();
    private static Pricebook2 pb22 = new Pricebook2();
    /*********************************************************************************************************
     * @name            setup
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de configuración de prueba para crear e insertar datos ficticios de `Account` y
     *                  `Pricebook2`, incluyendo cuentas de México (MX) y España (ES).
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @testSetup
    static void setup() {
        List<Account> listaAccounts = new List<Account>();
        List<Pricebook2> listaPricebook2 = new List<Pricebook2>();

        accMX = utilTestClass.createClient();
        accMX.DES_BBVA_Segmentation__c = 'C';
        accMX.DES_Country_Client__c = 'MX';
        listaAccounts.add(accMX);

        accES = utilTestClass.createClient();
        accES.DES_BBVA_Segmentation__c = 'C';
        accES.DES_Country_Client__c = 'ES';
        listaAccounts.add(accES);
        insert listaAccounts;

        p.Name = 'Testbook';
        listaPricebook2.add(p);

        pb22.Name = 'testDIE';
        listaPricebook2.add(pb22);
        insert listaPricebook2;
    }

    /*********************************************************************************************************
     * @name            getData
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método que obtiene y clasifica los registros de `Account` y `Pricebook2` de acuerdo a
     *                  valores específicos como país y nombres.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    private static void getData() {
        List<Account> accountList = [SELECT Id, DES_BBVA_Segmentation__c, DES_Structure_Type__c, DES_Main_Parent__c, DES_Country_Client__c
                                     FROM Account];
        List<Pricebook2> listaPricebook2 = [SELECT Id, Name
                                            FROM Pricebook2];
        for (Account acc : accountList) {
            if (acc.DES_Country_Client__c == 'MX') {
                accMX = acc;
            } else if (acc.DES_Country_Client__c == 'ES') {
                accES = acc;
            }
        }
        for (Pricebook2 pb : listaPricebook2) {
            if (pb.Name == 'Testbook') {
                p = pb;
            } else if (pb.Name == 'testDIE') {
                pb22 = pb;
            }
        }
    }

    @isTest
    private static void getInstance() {
        String instance = '';
        Organization o = [SELECT OrganizationType, InstanceName
                          FROM Organization
                          limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;

        //Set this header to test it
        ApexPages.currentPage().getHeaders().put('Host', insName + '.visual.force.com');

        if (orgType == 'Developer Edition') {
            List<String> parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
            instance = parts[parts.size() - 4] + '.';
        }

        Utilities.getInstance();
    }

    @isTest
    private static void getSubdomainPrefix() {
        //This will always be empty unless it's sandbox
        Utilities.getSubdomainPrefix();
    }

    /*********************************************************************************************************
     * @name            checkIsMexicoContactTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que el contacto creado asociado a una cuenta de México
     *                  tenga el campo 'IsOnlyMexico__c' como verdadero.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsMexicoContactTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        Contact con;
        con = testClass.createContact(accMX);
        insert con;
        con = [SELECT Id, IsOnlyMexico__c
               FROM Contact
               LIMIT 1];
        System.assert(con.IsOnlyMexico__c, 'Algo no ha salido bien el Contacto deberia ser de Mexico');
        Test.stopTest();
    }

    /*********************************************************************************************************
     * @name            checkIsNOTMexicoContactTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que el contacto creado asociado a una cuenta que no es de
     *                  México tenga el campo 'IsOnlyMexico__c' como falso.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsNOTMexicoContactTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        Contact con;
        con = testClass.createContact(accES);
        insert con;
        con = [SELECT Id, IsOnlyMexico__c
               FROM Contact
               LIMIT 1];
        System.assert(!con.IsOnlyMexico__c, 'Algo no ha salido bien el Contacto NO deberia ser de Mexico');
        Test.stopTest();
    }

    /*********************************************************************************************************
     * @name            checkIsMexicoOppTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que la oportunidad creada asociada a una cuenta de México
     *                  tenga el campo 'IsOnlyMexicoOpportunity__c' como verdadero.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsMexicoOppTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        Opportunity testOpportunity = new Opportunity(
            StageName = 'Draft Opp', 
            CloseDate = Date.today(), 
            AccountId = accMX.Id, 
            Name = 'Test Opportunity Triggers', 
            Pricebook2Id = pb22.id
        );
        insert testOpportunity;
        testOpportunity = [SELECT Id, IsOnlyMexicoOpportunity__c
                           FROM Opportunity
                           LIMIT 1];
        System.assert(testOpportunity.IsOnlyMexicoOpportunity__c, 'Algo no ha salido bien la Oportunidad deberia ser de Mexico');
        Test.stopTest();
    }

    /*********************************************************************************************************
     * @name            checkIsNOTMexicoOppTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que la oportunidad creada asociada a una cuenta que no es
     *                  de México tenga el campo 'IsOnlyMexicoOpportunity__c' como falso.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsNOTMexicoOppTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        Opportunity testOpportunity = new Opportunity(
            StageName = 'Draft Opp', 
            CloseDate = Date.today(), 
            AccountId = accES.Id, 
            Name = 'Test Opportunity Triggers', 
            Pricebook2Id = pb22.id
        );
        insert testOpportunity;
        testOpportunity = [SELECT Id, IsOnlyMexicoOpportunity__c
                           FROM Opportunity
                           LIMIT 1];
        System.assert(!testOpportunity.IsOnlyMexicoOpportunity__c, 'Algo no ha salido bien la Oportunidad NO deberia ser de Mexico');
        Test.stopTest();
    }

    /*********************************************************************************************************
     * @name            checkIsMexicoVisitTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que la visita creada asociada a una cuenta de México
     *                  tenga el campo 'IsOnlyMexicoVisit__c' como verdadero.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsMexicoVisitTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        dwp_kitv__Visit__c newVisit;
        newVisit = new dwp_kitv__Visit__c();
        newVisit.dwp_kitv__disclosure_info_type__c = 'Not applicable';
        newVisit.Name = 'Test Visit';
        newVisit.dwp_kitv__visit_start_date__c = Date.valueOf('2020-05-20T06:47:00.000+0000');
        newVisit.dwp_kitv__account_id__c = accMX.Id;
        newVisit.dwp_kitv__visit_duration_number__c = '15';
        insert newVisit;
        newVisit = [SELECT Id, IsOnlyMexicoVisit__c
                    FROM dwp_kitv__Visit__c
                    LIMIT 1];
        System.assert(newVisit.IsOnlyMexicoVisit__c, 'Algo no ha salido bien la Visita deberia ser de Mexico');
        Test.stopTest();
    }

    /*********************************************************************************************************
     * @name            checkIsNOTMexicoVisitTest
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método de prueba para verificar que la visita creada asociada a una cuenta que no es de
     *                  México tenga el campo 'IsOnlyMexicoVisit__c' como falso.
     * @param           N/A
     * @return          N/A
     **********************************************************************************************************/
    @isTest
    private static void checkIsNOTMexicoVisitTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Test.startTest();
        getData();
        dwp_kitv__Visit__c newVisit;
        newVisit = new dwp_kitv__Visit__c();
        newVisit.dwp_kitv__disclosure_info_type__c = 'Not applicable';
        newVisit.Name = 'Test Visit';
        newVisit.dwp_kitv__visit_start_date__c = Date.valueOf('2020-05-20T06:47:00.000+0000');
        newVisit.dwp_kitv__account_id__c = accES.Id;
        newVisit.dwp_kitv__visit_duration_number__c = '15';
        insert newVisit;
        newVisit = [SELECT Id, IsOnlyMexicoVisit__c
                    FROM dwp_kitv__Visit__c
                    LIMIT 1];
        System.assert(!newVisit.IsOnlyMexicoVisit__c, 'Algo no ha salido bien la Visita NO deberia ser de Mexico');
        Test.stopTest();
    }

}