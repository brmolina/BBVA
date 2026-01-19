public with sharing class Home_NPS_Button_Controller {

	public Home_NPS_Button_Controller() {
	}

	@AuraEnabled
	public static String getWave(){
        String result;
        result = 'false';
        String dateStart;
        String dateEnd;
        dateStart = '';
        dateEnd = '';
		List<NPS_Wave__c> lNPS = [SELECT Id, name, nps_start_date__c, nps_end_date__c FROM NPS_Wave__c ORDER BY nps_end_date__c DESC LIMIT 1];

        if(lNPS != null && !lNPS.isEmpty()) {
            if(lNPS.get(0).nps_start_date__c != null && lNPS.get(0).nps_start_date__c <= Date.today() && lNPS.get(0).nps_end_date__c != null && lNPS.get(0).nps_end_date__c >= Date.today()) {
                dateStart = lNPS.get(0).nps_start_date__c.year()+'-'+lNPS.get(0).nps_start_date__c.month()+'-'+lNPS.get(0).nps_start_date__c.day();
                dateEnd = lNPS.get(0).nps_end_date__c.year()+'-'+lNPS.get(0).nps_end_date__c.month()+'-'+lNPS.get(0).nps_end_date__c.day();
                result = 'progress\nStart on ' + dateStart + ' | End on ' + dateEnd;
            } else if(lNPS.get(0).nps_start_date__c != null && lNPS.get(0).nps_start_date__c > Date.today()) {
                dateStart = lNPS.get(0).nps_start_date__c.year()+'-'+lNPS.get(0).nps_start_date__c.month()+'-'+lNPS.get(0).nps_start_date__c.day();
                dateEnd = lNPS.get(0).nps_end_date__c.year()+'-'+lNPS.get(0).nps_end_date__c.month()+'-'+lNPS.get(0).nps_end_date__c.day();
                result = 'scheduled\nStart on ' + dateStart + ' | End on ' + dateEnd;
            }
        }
        return result;
	}
}