public with sharing class SearchPhoneController {
	public String phoneNumber {get;set;} 
	
	
	public SearchPhoneController(){
		this.phoneNumber = apexpages.currentpage().getparameters().get('phone'); 		
	}
	
	
	
	public PageReference doRedirectToSearchPage(){
        PageReference pageRef = new PageReference('/_ui/search/ui/UnifiedSearchResults?str=' + this.phoneNumber);
        pageRef.setRedirect(true);
		return pageRef; 
	}

}