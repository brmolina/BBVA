@isTest
public class GroupGeographyCntTest {
    @isTest
    public static void GroupGeographyCnt(){
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String prof1 = utilTestClass.createProfile();
        User user1 = utilTestClass.createUser(prof1);
        
        List <Account> accList = new List <Account>();
        Set <Id> accIdList = new Set <Id>();
            
        Account acc1 = utilTestClass.createClient();
        acc1.DES_Country_Client__c = 'AR';
        accList.add(acc1);
        Account acc2 = utilTestClass.createClient();
        acc2.DES_Country_Client__c = 'BE';
        accList.add(acc2);
        Account acc3 = utilTestClass.createClient();
        acc3.DES_Country_Client__c = 'FR';

        accList.add(acc3);   
        
        insert accList;
        
        for (Account acc:accList){
            accIdList.add(acc.Id);
        }

        Account groupAcc = utilTestClass.createGroupClient( 'groupAcc', accIdList, user1.Id );
                
        Test.StartTest();
        
        List<GroupGeographyCnt.Location> reslistLoc = GroupGeographyCnt.getAccount(groupAcc.Id);
        System.assertEquals(3,reslistLoc.size());

        Test.StopTest();

    }

}