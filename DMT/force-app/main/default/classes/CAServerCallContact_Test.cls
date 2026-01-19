/*
*Author         JSS
*Date           2016/08/01
*Description    Clase test para el controller CAServerCallContact
*Revision
*               2019/02/27 Para solucionar errores en los test se añade cambio para rellenar el owner de los contacts
*/
@isTest
private class CAServerCallContact_Test {


    static testMethod void test_pageController() {
        //Data needed


        //Test
        test.startTest();
            PageReference searchPhonePage = Page.CAServerSearchPhone;

            test.setCurrentPage(searchPhonePage);
            System.currentPageReference().getParameters().put('phone', '666666666');

            CAServerCallContact controller = new CAServerCallContact();
            controller.doFindPhoneNumber();
        test.stopTest();


        //Verify the expressions are the same
        System.assertEquals('666666666', controller.phoneNumber);

    }

    static testMethod void test_getContactName01() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        insert SampleAccount;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleFISalesUser.id);
        insert SampleAccShare;
        Contact sampleContact = UnitTestUtils.GetContact(SampleAccount.id);
        sampleContact.Phone = '666666666';
        sampleContact.OwnerId = SampleFISalesUser.Id;
        insert sampleContact;

        CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();

        //Test
        System.runAs(SampleFISalesUser) {
            test.startTest();
            result = CAServerCallContact.getContactName('666666666');
            test.stopTest();
        }


        //Verify the expressions are the same
        Contact contactIni = [select id, Name From Contact where id = :sampleContact.id limit 1].get(0);
        Account clientIni = [select id, Name From Account where id = :SampleAccount.id limit 1].get(0);
        System.assertEquals(contactIni.Name, result.contactName);
        System.assertEquals(clientIni.Name, result.clientName);

    }

    static testMethod void test_getContactName02() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        SampleAccount.Phone = '666666666';
        insert SampleAccount;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleFISalesUser.id);
        insert SampleAccShare;

        CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();

        //Test
        System.runAs(SampleFISalesUser) {
            test.startTest();
            result = CAServerCallContact.getContactName('666666666');
            test.stopTest();

        }


        //Verify the expressions are the same
        Account clientIni = [select id, Name From Account where id = :SampleAccount.id limit 1].get(0);
        System.assertEquals('', result.contactName);
        System.assertEquals(clientIni.Name, result.clientName);

    }


    static testMethod void test_getContactName03() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;
        System.runAs(SampleFISalesUser) {
            //Data needed
            Lead SampleLead = UnitTestUtils.GetLead();
            SampleLead.Phone = '666666666';
            insert SampleLead;
            CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();

            //Test
            test.startTest();
                result = CAServerCallContact.getContactName('666666666');
            test.stopTest();

            //Verify the expressions are the same
            Lead leadIni = [select id, Name, Company From Lead where id = :SampleLead.id limit 1].get(0);
            System.assertEquals(leadIni.Name, result.contactName);
            System.assertEquals(leadIni.Company, result.clientName);

        }

    }







    static testMethod void test_getRecordByPhoneNumber01() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        insert SampleAccount;
        Contact sampleContact = UnitTestUtils.GetContact(SampleAccount.id);
        sampleContact.Phone = '666666666';
        sampleContact.OwnerId = SampleFISalesUser.Id;
        insert sampleContact;

        CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();


        //Test
        System.runAs(SampleFISalesUser) {
            test.startTest();
            result = CAServerCallContact.getRecordByPhoneNumber('666666666');
            test.stopTest();
        }

        //Verify the expressions are the same
        Contact contactIni = [select id, Name From Contact where id = :sampleContact.id limit 1].get(0);
        System.assertEquals(contactIni.Name, result.contactName);
        System.assertEquals(contactIni.Id, result.id);


    }

    static testMethod void test_getRecordByPhoneNumber02() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;


        CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();

        //Test
        System.runAs(SampleFISalesUser) {
            Account SampleAccount = UnitTestUtils.GetStandardAccount();
            SampleAccount.Phone = '666666666';
            insert SampleAccount;

            test.startTest();
            result = CAServerCallContact.getRecordByPhoneNumber('666666666');
            test.stopTest();


            //Verify the expressions are the same
            Account clientIni = [select id, Name From Account where id = :SampleAccount.id limit 1].get(0);
            System.assertEquals(clientIni.Id, result.id);
            System.assertEquals(clientIni.Name, result.contactName);
        }

    }


    static testMethod void test_getRecordByPhoneNumber03() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;


        CAServerCallContact.ContactDetails result = new CAServerCallContact.ContactDetails();

        //Test
        System.runAs(SampleFISalesUser) {
            Lead SampleLead = UnitTestUtils.GetLead();
            SampleLead.Phone = '666666666';
            insert SampleLead;

            test.startTest();
            result = CAServerCallContact.getRecordByPhoneNumber('666666666');
            test.stopTest();



            //Verify the expressions are the same
            Lead leadIni = [select id, Name, Company From Lead where id = :SampleLead.id limit 1].get(0);
            System.assertEquals(leadIni.Id, result.id);
            System.assertEquals(leadIni.Name, result.contactName);
        }
    }

    static testMethod void test_getUrl() {
        Test.startTest();
            String url = CAServerCallContact.getUrl();
        Test.stopTest();

    }

    static testMethod void test_createContact() {
        //Data needed
        user SampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleFISalesUser;

        System.runAs(SampleFISalesUser) {
            Test.startTest();
                CAServerCallContact.createContact('111111111');
            Test.stopTest();
        }
    }

}