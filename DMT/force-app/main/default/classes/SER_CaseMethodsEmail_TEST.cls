/*-----------------------------------------------------------------------------------------------
    Author:        Rodrigo Fdez-Victorio
    Company:       Accenture
    Description:   Test class for Casemethods related to email

    History:
    <Date>          <Author>                <Description>
    11/12/2018      Rodrigo Fdez-Victorio   Initial version
-------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class SER_CaseMethodsEmail_TEST {
    /**Constante 'Email'*/
    public static final String EMAIL = 'Email';
    /**Constante 'Pruebas de CaseCode'*/
    public static final String PRUEBAS = 'Pruebas de CaseCode';

    /*-----------------------------------------------------------------------------------------------
        Author:        Rodrigo Fdez-Victorio
        Company:       Accenture
        Description:   Test method for generateSEREmailToCaseCode. Two cases created with enough info
                        to create code.
        History:
        <Date>          <Author>                <Description>
        11/12/2018      Rodrigo Fdez-Victorio   Initial version
    -------------------------------------------------------------------------------------------------*/
    public static testMethod void  generateSEREmailToCaseCodeTEST() {
        final Account account = UnitTestUtils.GetStandardAccount();
        insert account;

        final List<Case> lstCasos = new List<Case>();
            lstCasos.add(new Case(OwnerId = UserInfo.getUserId(),
                            Origin=EMAIL,
                            SuppliedEmail = 'test@test.com',
                            Subject = PRUEBAS,
                            AccountId = account.id)
                            );
        lstCasos.add(new Case(OwnerId = UserInfo.getUserId(),
                            Origin=EMAIL,
                            Subject = PRUEBAS)
                            );
        lstCasos.add(new Case(OwnerId = UserInfo.getUserId(),
                            Origin=EMAIL,
                            Subject = PRUEBAS,
                            AccountId = account.id)
                            );
        lstCasos.add(new Case(OwnerId = UserInfo.getUserId(),
                            Origin=EMAIL,
                            Subject = PRUEBAS)
                            );
        lstCasos.add(new Case(OwnerId = UserInfo.getUserId(),
                            Origin=EMAIL,
                            AccountId = account.id)
                            );
        SER_CaseMethodsEmail.generateSEREmailToCaseCode(lstCasos);

        System.assert (lstCasos[0].SER_EmailToCaseCode__c!=null && lstCasos[1].SER_EmailToCaseCode__c!=null
                    && lstCasos[2].SER_EmailToCaseCode__c!=null && lstCasos[3].SER_EmailToCaseCode__c!=null
                    && lstCasos[4].SER_EmailToCaseCode__c!=null ,'SER_CaseMethodsEmail_TEST');
    }

    /*-----------------------------------------------------------------------------------------------
        Author:        Rodrigo Fdez-Victorio
        Company:       Accenture
        Description:   Test method for generateSEREmailToCaseCode. A case created without enough info
                        to create code.
        History:
        <Date>          <Author>                <Description>
        11/12/2018      Rodrigo Fdez-Victorio   Initial version
    -------------------------------------------------------------------------------------------------*/
    public static testMethod void  generateSEREmailToCaseCode2TEST() {
        final Account account = UnitTestUtils.GetStandardAccount();
        insert account;

        final List<Case> lstCasos = new List<Case>();
        lstCasos.add(
            new Case(OwnerId = UserInfo.getUserId(),Origin=EMAIL)
                    );

        SER_CaseMethodsEmail.generateSEREmailToCaseCode(lstCasos);

        System.assert (!String.isNotBlank(lstCasos[0].SER_EmailToCaseCode__c),'SER_CaseMethodsEmail_TEST');
    }
}