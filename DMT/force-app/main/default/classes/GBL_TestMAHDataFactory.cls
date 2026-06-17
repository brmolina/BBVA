@isTest
public class GBL_TestMAHDataFactory {
  @isTest public static List<Account> setupAccounts() {
    //This method creates the following records:
    //  · Parent Account
    //  · Child Account for Negocio
    //  · Child Account for Riesgos
    //  · 1 Case + 1 Opty + 1 Contact for each Child Account above

    List<Account> accts = new List<Account>();

    //Create Parent and Child Accounts
    Account parentA = new Account(Name='Parent Account');
    Account childA =  new Account(Name='Negocio Child Account');
    Account childB =  new Account(Name='Riesgos Child Account');
    accts.add(parentA);
    accts.add(childA);
    accts.add(childB);

    insert accts;

    //Create relationships in the MultiHierarchy Object
    childA.ParentId=parentA.Id;
    childB.ParentId=parentA.Id;
    update accts;

    List<AMH_GBL_Account_Relationship__c> relMHAs = new List<AMH_GBL_Account_Relationship__c>();

    AMH_GBL_Account_Relationship__c relAA = new AMH_GBL_Account_Relationship__c (AMH_Parent_Account__c=parentA.Id,
                                                                          AMH_Child_Account__c=childA.Id,
                                                                          AMH_Type__c = '03 - Filial',
                                                                          AMH_Vision__c = 'Negocio');

    AMH_GBL_Account_Relationship__c relAB  = new AMH_GBL_Account_Relationship__c (AMH_Parent_Account__c=parentA.Id,
                                                                          AMH_Child_Account__c=childB.Id,
                                                                          AMH_Type__c = '03 - Filial',
                                                                          AMH_Vision__c = 'Riesgos');
    relMHAs.add(relAA);
    relMHAs.add(relAB);

    insert relMHAs;

    //Create test related records for each Child account
    List<Opportunity> opts = new List<Opportunity>();
    Opportunity optA = new Opportunity(Name=childA.Name + ' Opportunity',
                                        StageName='Prospeting',
                                        CloseDate=System.today().addMonths(1),
                                        Amount=5000,
                                        AccountId=childA.Id);
    Opportunity optB = new Opportunity(Name=childB.Name + ' Opportunity',
                                        StageName='Prospeting',
                                        CloseDate=System.today().addMonths(1),
                                        Amount=4500,
                                        AccountId=childB.Id);
    opts.add(optA);
    opts.add(optB);
    insert opts;

    List<Case> cases = new List<Case>();
    Case caseA = new Case (Subject=childA.Name + ' Case',
                            Origin='Phone',
                            Status='New',
                            AccountId=childA.Id);
    Case caseB = new Case (Subject=childB.Name + ' Case',
                            Origin='Phone',
                            Status='New',
                            AccountId=childB.Id);
    cases.add(caseA);
    cases.add(caseB);
    insert cases;

    List<Contact> contacts = new List<Contact>();
    Contact conA = new Contact (FirstName=childA.Name,
                                LastName='Contact', Phone = '12345679',
                                AccountId=childA.Id);
    Contact conB = new Contact (FirstName=childB.Name,
                                LastName='Contact', Phone = '12345678',
                                AccountId=childB.Id);
    contacts.add(conA);
    contacts.add(conB);
    insert contacts;

    //Create test related records in the Denormalization Object for each Account/Opportunity
    //OpportunityA related to ChildA and ParentA accounts
    //OpportunityB related to ChildB and ParentA accounts
    List<AMH_Denorm_Account_Opportunity__c> pListAccOpty = new List<AMH_Denorm_Account_Opportunity__c>();

    AMH_Denorm_Account_Opportunity__c accOptypAoA = new AMH_Denorm_Account_Opportunity__c(AMH_AccountId__c=parentA.Id, AMH_OpportunityId__c=optA.Id);
    pListAccOpty.add(accOptypAoA);
    AMH_Denorm_Account_Opportunity__c accOptycAoA = new AMH_Denorm_Account_Opportunity__c(AMH_AccountId__c=childA.Id, AMH_OpportunityId__c=optA.Id);
    pListAccOpty.add(accOptycAoA);
    AMH_Denorm_Account_Opportunity__c accOptypAoB = new AMH_Denorm_Account_Opportunity__c(AMH_AccountId__c=parentA.Id, AMH_OpportunityId__c=optB.Id);
    pListAccOpty.add(accOptypAoB);
    AMH_Denorm_Account_Opportunity__c accOptycBoB = new AMH_Denorm_Account_Opportunity__c(AMH_AccountId__c=childB.Id, AMH_OpportunityId__c=optB.Id);
    pListAccOpty.add(accOptycBoB);

    insert pListAccOpty;
    system.assertEquals(1, 1);
    return accts;
  }
}