// CIBGLOBALD-4613 - Opportunity tenor validation with real data changes, rolled back at the end (nothing persists)
String oppId = '006KE000002ooDlYAI';
void printTenorRow(String scenario, String oppId) {
    Account acc = DMT_Passport_Selector.getAccountWithRelatedListsFromOppId(oppId);
    Opportunity opp = acc.Opportunities[0];
    DMT_Opportunity_Client__c client = opp.DMT_MDE_Opportunities_Clients__r.isEmpty() ? new DMT_Opportunity_Client__c() : opp.DMT_MDE_Opportunities_Clients__r[0];
    System.debug(LoggingLevel.ERROR, 'RES|clients on opp: ' + opp.DMT_MDE_Opportunities_Clients__r.size() + ' products: ' + opp.OpportunityLineItems.size());
    String found = 'ROW NOT SHOWN';
    for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations v : DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, client, '[]')) {
        if (v.name.startsWith('Tenors Payment Date')) { found = v.state + ' | ' + v.name + ' | ' + v.message; }
    }
    System.debug(LoggingLevel.ERROR, 'RES|' + scenario + '|' + found);
}
Savepoint sp = Database.setSavepoint();
try {
    printTenorRow('A data as it is', oppId);
    Id rentingId;
    for (OpportunityLineItem o : [SELECT Id, Name FROM OpportunityLineItem WHERE OpportunityId = :oppId]) { if (o.Name.endsWith('Renting')) { rentingId = o.Id; } }
    Date july14 = Date.newInstance(2026, 7, 14);
    DMT_Opportunity_Tenor__c t = [SELECT Id, gf_tenor_date__c FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :rentingId AND gf_tenor_date__c = :july14 LIMIT 1];
    t.gf_tenor_date__c = null;
    update t;
    printTenorRow('B Renting 14-Jul Payment Date emptied', oppId);
    List<OpportunityLineItem> olis = [SELECT Id, DMT_Line_Oneoffdeal__c FROM OpportunityLineItem WHERE OpportunityId = :oppId];
    for (OpportunityLineItem o : olis) { o.DMT_Line_Oneoffdeal__c = (o.Id == rentingId) ? 'Line' : 'One-off deal'; }
    update olis;
    printTenorRow('C same empty date but Renting set to Line, other products One-off', oppId);
    for (OpportunityLineItem o : olis) { o.DMT_Line_Oneoffdeal__c = 'Line'; }
    update olis;
    printTenorRow('D all products set to Line', oppId);
} finally {
    Database.rollback(sp);
}
printTenorRow('E after rollback', oppId);
