@isTest
private class SearchPhoneController_Test{
    
    
    static testMethod void test01() {   
        //Data needed
        
        
        //Test
        test.startTest(); 
            PageReference searchPhoneRedir = Page.SearchPhoneRedir;

            test.setCurrentPage(searchPhoneRedir);
            System.currentPageReference().getParameters().put('phone', '666666666');        
        
            SearchPhoneController controller = new SearchPhoneController();
            controller.doRedirectToSearchPage();
        test.stopTest();
        

        //Verify the expressions are the same
        System.assertEquals('666666666', controller.phoneNumber);
                
    }
    
    
    
    
}