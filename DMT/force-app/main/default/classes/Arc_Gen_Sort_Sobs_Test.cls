/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Sort_Sobs_Test
* @Author   david.crespo.bordoncontractor@bbva.com
* @Date     Created: 31/01/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description test for method class Arc_Gen_Sort_Sobs.
* -----------------------------------------------------------------------------------------------
* @Changes
* -----------------------------------------------------------------------------------------------
*/
@isTest
private class Arc_Gen_Sort_Sobs_Test {

@isTest static void testStringField() {
    final Account[] accs = new Account[]{};
    for (Integer i = 0; i < 200; i++) {
        accs.add(new Account(
            Name = generateRandomString(30)
        ));
    }

    Test.startTest();
    Arc_Gen_Sort_Sobs.ascending(accs, Account.Name);
    Test.stopTest();

    final Account previousAccount = accs.remove(0);
    for (Account acc : accs) {
        System.assert(previousAccount.Name <= acc.Name,'OK');
    }
}
@isTest static void testNumberField() {
    final Account[] accs = new Account[]{};
    for (Integer i = 0; i < 200; i++) {
        accs.add(new Account(
            AnnualRevenue = Math.random() * 1000
        ));
    }

    Test.startTest();
    Arc_Gen_Sort_Sobs.ascending(accs, Account.AnnualRevenue);
    Test.stopTest();

    final Account previousAccount = accs.remove(0);
    for (Account acc : accs) {
        System.assert(previousAccount.AnnualRevenue <= acc.AnnualRevenue,'OK');
    }
}

@isTest static void testDateField() {
    final Opportunity[] opps = new Opportunity[]{};
    for (Integer i = 0; i < 200; i++) {
        opps.add(new Opportunity(
            CloseDate = Date.today().addDays((Integer)Math.random() * 1000)
        ));
    }

    Test.startTest();
    Arc_Gen_Sort_Sobs.ascending(opps, Opportunity.CloseDate);
    Test.stopTest();

    final Opportunity previousOppo = opps.remove(0);
    for (Opportunity opp : opps) {
        System.assert(previousOppo.CloseDate <= opp.CloseDate,'OK');
    }
}

@isTest static void testDatetimeField() {
    final Task[] tasks = new Task[]{};
    for (Integer i = 0; i < 200; i++) {
        tasks.add(new Task(
                ReminderDateTime = DateTime.now().addDays((Integer)Math.random() * 1000)
        ));
    }

    Test.startTest();
    Arc_Gen_Sort_Sobs.ascending(tasks, Task.ReminderDateTime);
    Test.stopTest();

    final Task previousTask = tasks.remove(0);
    for (Task ts : tasks) {
        System.assert(previousTask.ReminderDateTime <= ts.ReminderDateTime,'OK');
    }
}

private static String generateRandomString(Integer len) {
    String randStr = '';
    while (randStr.length() < len) {
    final Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz'.length());
    randStr += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz'.substring(idx, idx+1);
    }
    return randStr;
}
}