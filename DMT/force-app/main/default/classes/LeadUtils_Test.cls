@isTest
private class LeadUtils_Test {
    static testMethod void testData(){
        User sampleFISalesUser = UnitTestUtils.GetFISalesUser();
        insert sampleFISalesUser;

        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        Insert SampleAccount;

        Campaign SampleCampaign = UnitTestUtils.GetCampaign();
        SampleCampaign.Name = 'Test';
        SampleCampaign.StartDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        SampleCampaign.EndDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month())+50);
        SampleCampaign.Status = 'Draft';
        SampleCampaign.Description = 'description';
        SampleCampaign.cond__priority_campaign_type__c = 'Medium';
        insert SampleCampaign;

        Contact SampleContact = UnitTestUtils.GetContact(SampleAccount.id);
        SampleContact.AccountId = SampleAccount.Id;
        SampleContact.OwnerId = sampleFISalesUser.Id;
        insert SampleContact;

        Lead SampleLead = UnitTestUtils.GetLead();
        insert SampleLead;

        CampaignMember SampleCampaignMemberLead = UnitTestUtils.GetAssignedCMLead(SampleCampaign.id, SampleLead.id);
        SampleCampaignMemberLead.ContactId = SampleContact.Id;
        insert SampleCampaignMemberLead;

        set<id> LeadIds = new set<id>();
        set<String> LeadString = new set<String>();

        //WorkAround To field is not writable Lead.ConvertedContactId Also is not Possible insert to campaign member a converted Lead.
        for(CampaignMember CM: [Select LeadId, CampaignId, Lead.ConvertedContactId From CampaignMember LIMIT 10]){
            LeadIds.add(CM.LeadId);
            LeadString.add(CM.CampaignId);
        }

        if (LeadIds.size()>0 ){
            List<Lead> SampleLeadList = [Select id, ConvertedContactId from Lead LIMIT 10];
            if (SampleLeadList.size()>0 ){
                LeadUtils.insertLeads(SampleLeadList);
                list<Campaign__c> CustomCampaignList = [Select id from Campaign__c LIMIT 10];
                //Expected 1 or more records inserted
                LeadUtils.insertNewRecords(LeadString);
                //system.assertNotEquals(CustomCampaignList.size(), 0);
            }
        }
        update SampleLead;
    }
}