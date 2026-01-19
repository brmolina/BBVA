@isTest
private class AccountStructure_Test {
	

	@isTest
	public static void AccountStructure_Test() {

		Account SampleAccountParent = UnitTestUtils.GetStandardAccount();
        Insert SampleAccountParent;

		Account SampleAccountChild_1 = UnitTestUtils.GetStandardAccount();
		SampleAccountChild_1.ParentId = SampleAccountParent.Id;
        Insert SampleAccountChild_1;


        test.startTest();
            PageReference AccountHierarchyPage = Page.AccountHierarchyPage;

            test.setCurrentPage(AccountHierarchyPage);
            System.currentPageReference().getParameters().put('id', SampleAccountParent.Id);
            
            AccountStructure ctrlExt = new AccountStructure();
            ctrlExt.getObjectStructure();
            ctrlExt.setcurrentId(SampleAccountParent.Id);            
            ctrlExt.getObjectStructure();
            ctrlExt.formatObjectStructure(SampleAccountParent.Id);
            ctrlExt.asm.get(0).getFixedCode();
            ctrlExt.asm.get(0).setaccount(SampleAccountParent);
            ctrlExt.asm.get(0).getaccount();
            ctrlExt.asm.get(0).getnodeId();
			ctrlExt.asm.get(0).getlevelFlag();
			ctrlExt.asm.get(0).getcloseFlag();
			ctrlExt.asm.get(0).getnodeType();
			ctrlExt.asm.get(0).getcurrentNode();
			ctrlExt.asm.get(0).setnodeId( (String) SampleAccountParent.Id  );	
			ctrlExt.asm.get(0).setlevelFlag(false);
			ctrlExt.asm.get(0).setlcloseFlag(false);
			ctrlExt.asm.get(0).setnodeType('child_end');
			ctrlExt.asm.get(0).getFixedCode();
			ctrlExt.asm.get(0).setcurrentNode(false);



            ctrlExt = new AccountStructure();
            ctrlExt.setcurrentId(SampleAccountChild_1.Id);
            ctrlExt.getObjectStructure();
            ctrlExt.formatObjectStructure(SampleAccountChild_1.Id);      

        test.stopTest();
		
	}	


}