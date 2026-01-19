/**
 * Author	:	Global Desktop
 * Desc		:	DES_AP_CommActionsTableController controller
 * */
public with sharing class DES_AP_CommActionsTableController {
	/* Declarando variable */
    public static final String STNA = 'N.A';
    /* Declarando variable */
    public static final String STPER = '%';
    /* Declarando variable */
    public static final String NUMONE = '01';
    /* Declarando variable */
    public static final String NUMTWO = '02';
    
    /**
	* Calculates the information needed in DES_AP_CommActionsTable
	**/
    @auraEnabled
  	public static String getRelatedCA(String gaId) {
        final List<DES_Denorm_AccountVisits__c> relatedCA = getData(gaId);
        Integer numCallYear = 0;
        Integer numCallLast = 0;
        Integer numVisitYear = 0;
        Integer numVisitLast = 0;
        for(DES_Denorm_AccountVisits__c dCA : relatedCA) {
                if(dCA.DES_Visit_new__r.dwp_kitv__visit_start_date__c.year() == system.Today().year()) {
                    if(dCA.DES_Visit_new__r.dwp_kitv__visit_channel__c == NUMTWO) {
                          numCallYear = numCallYear + 1;
                        } else {
                          numVisitYear = numVisitYear + 1;
                        }
                    } else if(dCA.DES_Visit_new__r.dwp_kitv__visit_start_date__c.year() == system.Today().year() -1) {
                    if(dCA.DES_Visit_new__r.dwp_kitv__visit_channel__c == NUMONE) {
                          numVisitLast = numVisitLast + 1;
                        } else {
                          numCallLast = numCallLast + 1;
                        }
                } 
        }

       	final Decimal perVisitYOY = calculatePerVisitYOY(numVisitYear, numVisitLast);
        final Decimal perCallYOY = calculatePerCallYOY(numCallYear, numCallLast);
        return calculateStringYear(perVisitYOY, perCallYOY, numVisitYear, numVisitLast, numCallYear, numCallLast);
    }
    
    /**
	* Obtains data
	**/
    public static List<DES_Denorm_AccountVisits__c> getData(String gaId) {
        final String accId = [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :gaId].participant_id__c;
        return [SELECT Name, DES_Visit_new__r.dwp_kitv__visit_channel__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__visit_start_date__c
                  		   FROM DES_Denorm_AccountVisits__c WHERE DES_Client__c  =: accId                           
                         AND ((DES_Visit_new__r.dwp_kitv__visit_start_date__c = LAST_YEAR) 
                                OR (DES_Visit_new__r.dwp_kitv__visit_start_date__c = THIS_YEAR))];
    }
    
    /**
	* Calculates PerVisitYOY
	**/
    public static Decimal calculatePerVisitYOY(Integer numVisitYear, Integer numVisitLast) {
        Decimal perVisitYOY;
        if(numVisitLast != null && numVisitLast != 0) {
              perVisitYOY = 100*(Decimal.valueOf(numVisitYear)-Decimal.valueOf(numVisitLast))/Decimal.valueOf(numVisitLast);
              perVisitYOY = perVisitYOY.setScale(2);
          }
        return perVisitYOY;
    }
    
    /**
	* Calculates PerCallYOY
	**/
    public static Decimal calculatePerCallYOY(Integer numCallYear, Integer numCallLast) {
        Decimal perCallYOY;
        if(numCallLast != null && numCallLast != 0) {
              perCallYOY = 100*(Decimal.valueOf(numCallYear)-Decimal.valueOf(numCallLast))/Decimal.valueOf(numCallLast);
              perCallYOY = perCallYOY.setScale(2);
          }
        return perCallYOY;
    }
    
    /**
	* Calculates StringYear
	**/
    public static String calculateStringYear(Decimal perVisitYOY, Decimal perCallYOY, Integer numVisitYear, Integer numVisitLast, 
                                             Integer numCallYear, Integer numCallLast) {
        String stringYear;
        if(perVisitYOY != null && perCallYOY != null) {
              stringYear = numVisitYear + ','
                          + numVisitLast + ',' 
                          + perVisitYOY + STPER + ','
                          + numCallYear + ','
                          + numCallLast + ','
                          + perCallYOY + STPER;
          } else if(perVisitYOY == null && perCallYOY != null) {
              stringYear = numVisitYear + ',' + numVisitLast + ',' + STNA + STPER + ','
                          + numCallYear + ',' + numCallLast + ',' + perCallYOY + STPER;
          } else if(perVisitYOY != null && perCallYOY == null) {
              stringYear = numVisitYear + ',' + numVisitLast + ',' + perVisitYOY + STPER + ','
                          + numCallYear + ',' + numCallLast + ',' + STNA + STPER;
          } else {
              stringYear = numVisitYear + ','
                         + numVisitLast + ','
                         + STNA + STPER + ','
                         + numCallYear + ','
                         + numCallLast + ','
                         + STNA + STPER;
          }
        return stringYear;
    }

}