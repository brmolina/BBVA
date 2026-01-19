@isTest
private class CIB_LogUtils_TEST {
	
	@isTest static void test_method_one() {
		Test.startTest();
		try{
			insert new Account();
		}catch(Exception e){
			CIB_LogUtils.create_Log(e, 'Subject');	
			CIB_LogUtils.create_Log('Subject', 'Subject');
			CIB_LogUtils.create_RemedyLog('Subject', 'Subject', 'Subject');
			CIB_LogUtils.create_RemedyErrorLog('Subject', 'Subject', 'Subject', 'Subject');
		}
		Test.stopTest();
	}
}