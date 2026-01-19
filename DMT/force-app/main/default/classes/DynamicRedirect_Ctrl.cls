public with sharing class DynamicRedirect_Ctrl {

	@AuraEnabled
    public static String getSessionId(){
    	String userId = UserInfo.getUserId();
    	String sessionId = UserInfo.getSessionId();
    	Map<String,String> jsonMap = new Map<String,String>();
    	jsonMap.put('userId',userId);
    	jsonMap.put('sessionId',sessionId);
        return JSON.serialize(jsonMap);
    }
    
}