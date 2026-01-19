/**
* @author       Global Desktop
* @date         12/06/2020
* @description  Retrieves information about opportunities related to the client analysed on the Group Analysis
**/

/*Queries for different scopes of opportunities*/
public with sharing class DES_AP_OppSummaryInfoCnt {
    
    /* Declarando variable */
    public static final String WONLY = 'WonLastYear';
    /* Declarando variable */
    public static final String LOSTLY = 'LostLastYear';
    /* Declarando variable */
    public static final String OPENLY = 'OpenLastYear';
    /* Declarando variable */
    public static final String WONL4M = 'WonLast4M';
    /* Declarando variable */
    public static final String LOSTL4M = 'LostLast4M';
    /* Declarando variable */
    public static final String CREATEDLY = 'CreatedLastYear';
    /* Declarando variable */
    public static final String CREATEDL4M = 'CreatedLast4M';

    /* Declarando variable */
    public static final String QUERY = 'Query';
    /* Declarando variable */
    public static final String WONCLOSED = 'WonClosed';
    /* Declarando variable */
    public static final String CROSSBORDER = 'CrossBorder';
    /* Declarando variable */
    public static final String TOTALS = 'Totals';
    /* Declarando variable */
    public static final String TABLE = 'Table';
    
    /* Declarando variable */
    public static final String STNA = 'N.A';
    /* Declarando variable */
    public static final String STM = ' M ';
    /* Declarando variable */
    public static final String STPER = ' % ';
	
    @auraEnabled
    /*Queries for different scopes of opportunities described on the Lightning component*/
    public static String getRelatedOpportunities(String gaId, String qType, String sumType, String configType) {
        final String accId = [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :gaId].participant_id__c;
        // 1. calcular la fecha de -4 meses
        final Date todayDate = date.today();
        final Date last4MDate = todayDate.addMonths(-4);
        System.debug('last4MDate: ' + last4MDate);
        
        final Date todayLastYear = todayDate.addYears(-1);
        Date lastYear4MDate;
        lastYear4MDate = todayDate.addMonths(-4);
        lastYear4MDate = lastYear4MDate.addYears(-1);
        
        final List<dwp_acmh__Denorm_Account_Opportunity__c> relatedOpps = gtRelatedOpps(accId, qType, todayDate, todayLastYear, last4MDate, lastYear4MDate);
        
        Decimal revenueYear = 0;
        Decimal revenueLast = 0;
        Decimal avgRvYear = 0;
        Decimal avgRvLast = 0;
        Integer numYear = 0;
        Integer numLast = 0;
        Integer numWonYear = 0;
        Integer numWonLast = 0;
        Integer numXBYear = 0;
        Integer numXBLast = 0;
        System.debug(revenueYear + '' + revenueLast + '' + avgRvYear + '' + avgRvLast + '' + numYear + '' + numLast + '' 
                     + numWonYear + '' + numWonLast + '' + numXBYear + '' + numXBLast);
        
        final String defaultCurrency = UserInfo.getDefaultCurrency();
        for(dwp_acmh__Denorm_Account_Opportunity__c dOpp : relatedOpps) {
            if(qType == WONLY || qType == LOSTLY || qType == OPENLY) {
                if(dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c != null && dOpp.dwp_acmh__OpportunityId__r.CloseDate.year() == system.Today().year()) {
                    revenueYear = revenueYear + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    numYear = numYear + 1;
                } else {
                    revenueLast = revenueLast + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    numLast = numLast + 1;
                }
            }
            if(qType == WONL4M || qType == LOSTL4M) {
                if(dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c != null && dOpp.dwp_acmh__OpportunityId__r.CloseDate >= last4MDate) {
                    revenueYear = revenueYear + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    numYear = numYear + 1;
                } else {
                    revenueLast = revenueLast + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    numLast = numLast + 1;
                }
            }
            if(qType == CREATEDLY) {
                if(dOpp.dwp_acmh__OpportunityId__r.CreatedDate.year() == system.Today().year()) {
                    numYear = numYear + 1;
                    revenueYear = revenueYear + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    if(dOpp.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won) {
                        numWonYear = numWonYear + 1;
                        if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                            numXBYear = numXBYear + 1;
                        }
                    } else if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                        numXBYear = numXBYear + 1;
                    }
                } else {
                    numLast = numLast + 1;
                    revenueLast = revenueLast + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    if(dOpp.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won) {
                        numWonLast = numWonLast + 1;
                        if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                            numXBLast = numXBLast + 1;
                        }
                    } else if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                        numXBLast = numXBLast + 1;
                    }
                }
            }
            if(qType == CREATEDL4M) {
                if(dOpp.dwp_acmh__OpportunityId__r.CreatedDate >= last4MDate) {
                    numYear = numYear + 1;
                    revenueYear = revenueYear + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    if(dOpp.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won) {
                        numWonYear = numWonYear + 1;
                        if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                            numXBYear = numXBYear + 1;
                        }
                    } else if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                        numXBYear = numXBYear + 1;
                    }
                } else {
                    numLast = numLast + 1;
                    revenueLast = revenueLast + dOpp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
                    if(dOpp.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won) {
                        numWonLast = numWonLast + 1;
                        if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                            numXBLast = numXBLast + 1;
                        }
                    } else if(dOpp.dwp_acmh__OpportunityId__r.DES_Cross_border__c == true) {
                        numXBLast = numXBLast + 1;
                    }
                }
            }
        }
        
        String stringYear;
        String stringTable;
        String stringTotals;
        String stringWon;
        String stringXB;
        
        if(qType == CREATEDLY || qType == CREATEDL4M) { 
            Decimal perYearWon;
            if(numYear != null && numYear != 0) {
                perYearWon = 100*(Decimal.valueOf(numWonYear))/Decimal.valueOf(numYear);
                perYearWon = perYearWon.setScale(2);
            }else{
                perYearWon = 0;
            }
            
            Decimal perLastWon;
            if(numLast != null && numLast != 0) {
                perLastWon = 100*(Decimal.valueOf(numWonLast))/Decimal.valueOf(numLast);
                perLastWon = perLastWon.setScale(2);
            }
            Decimal perWonYOY;
            if(perLastWon != null && perLastWon != 0) {
                perWonYOY = 100*(perYearWon - perLastWon)/perLastWon;
                perWonYOY = perWonYOY.setScale(2);
            }
            
            if(perYearWon != null && perWonYOY != null) {
                stringWon = perYearWon + STPER + ','
                    + perWonYOY + stPer;
            } else if(perYearWon != null && perWonYOY == null) {
                stringWon = perYearWon + STPER + ',' + STNA + STPER;
            } else if(perYearWon == null && perWonYOY != null) {
                stringWon = STNA + STPER + ',' + perWonYOY + STPER;
            } else {
                stringWon = STNA + STPER + ','
                    + STNA + STPER;
            }
            
            Decimal perYearXB;
            if(numYear != null && numYear != 0) {
                perYearXB = Decimal.valueOf(numXBYear)/Decimal.valueOf(numYear);
                perYearXB = perYearXB.setScale(2);
            }
            Decimal perLastXB;
            if(numLast != null && numLast != 0) {
                perLastXB = Decimal.valueOf(numXBLast)/Decimal.valueOf(numLast);
                perLastXB = perLastXB.setScale(2);
            }
            Decimal perXBYOY;
            if(perLastXB != null && perLastXB != 0) {
                perXBYOY = 100*(perYearXB - perLastXB)/perLastXB;
                perXBYOY = perXBYOY.setScale(2);
            }
            
            if(perYearXB != null && perXBYOY != null) {
                stringXB = perYearXB + STPER + ',' + perXBYOY + STPER;
            } else if(perYearXB == null && perXBYOY != null) {
                stringXB = STNA + STPER + ',' + perXBYOY + STPER;
            } else if(perYearXB != null && perXBYOY == null) {
                stringXB = perYearXB + STPER + ','
                    + STNA + STPER;
            } else {
                stringXB = STNA + STPER + ','
                    + STNA + STPER;
            }
            
        } else {
            Decimal percentVal;
            if(revenueLast != null && revenueLast != 0) {
                percentVal = 100*(revenueYear - revenueLast)/revenueLast;
                percentVal = percentVal.setScale(2);
            }
            
            Decimal perAvgVal;
            if(numYear != null && numYear != 0) {
                avgRvYear = revenueYear/numYear;
            }
            if(numLast != null && numLast != 0) {
                avgRvLast = revenueLast/numLast;
            }
            
            if(avgRvLast != null && avgRvLast != 0) {
                perAvgVal = 100*(avgRvYear-avgRvLast)/avgRvLast;
                perAvgVal = perAvgVal.setScale(2);
            }
            avgRvYear = avgRvYear/1000000;
            avgRvYear = avgRvYear.setScale(2);
            avgRvLast = avgRvLast/1000000;
            avgRvLast = avgRvLast.setScale(2);  
            
            if(perAvgVal != null) {
                stringTotals = avgRvYear + STM + defaultCurrency + ',' + perAvgVal + STPER;
            } else {
                stringTotals = avgRvYear + STM + defaultCurrency + ','
                    + STNA + STPER;
            }
        }
        
        Decimal perTableNum;
        if(numLast != null && numLast != 0) {
            perTableNum = 100*(Decimal.valueOf(numYear)-Decimal.valueOf(numLast))/Decimal.valueOf(numLast);
            perTableNum = perTableNum.setScale(2);
        }
        
        Decimal perTableRev;
        if(revenueLast != null && revenueLast != 0) {
            perTableRev = 100*(revenueYear-revenueLast)/revenueLast;
            perTableRev = perTableRev.setScale(2);
        }
        
        revenueYear = revenueYear/1000000;
        revenueYear = revenueYear.setScale(2);
        revenueLast = revenueLast/1000000;
        revenueLast = revenueLast.setScale(2);
        
        if(perTableNum != null && perTableRev != null) {
            stringTable = numYear + ',' + numLast + ',' + perTableNum + STPER + ',' + revenueYear + STM
                + defaultCurrency + ',' + revenueLast + STM + defaultCurrency + ',' + perTableRev + STPER;
        } else if(perTableNum == null && perTableRev != null) {
            stringTable = numYear + ',' + numLast + ',' + STNA + STPER + ',' + revenueYear + STM 
                + defaultCurrency + ',' + revenueLast + STM + defaultCurrency + ',' + perTableRev + STPER;
        } else if(perTableNum != null && perTableRev == null) {
            stringTable = numYear + ','
                + numLast + ','
                + perTableNum + STPER + ','
                + revenueYear + STM + defaultCurrency + ','
                + revenueLast + STM + defaultCurrency + ','
                + STNA + STPER;
        } else {
            stringTable = numYear + ','
                + numLast + ','
                + STNA + STPER + ','
                + revenueYear + STM + defaultCurrency + ','
                + revenueLast + STM + defaultCurrency + ','
                + STNA + STPER;
        }
        
        if (sumType == query && configType == totals) {
            stringYear = stringTotals;
        } else if (sumType == wonClosed && configType == totals) {
            stringYear = stringWon;
        } else if (sumType == crossBorder && configType == totals) {
            stringYear = stringXB;
        } else if (configType == table) {
            stringYear = stringTable;
        }
        System.debug(stringWon + ' ' + stringXB + ' ' + stringTable);
        return stringYear;
    }
    
    /*
	* @author Global Desktop
	* @description Obtiene la lista de oportunidades
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtRelatedOpps(String accId, String qType, Date todayDate, Date todayLastYear, Date last4MDate, Date lastYear4MDate) {
        List<dwp_acmh__Denorm_Account_Opportunity__c> relatedOpps;
        relatedOpps = new List<dwp_acmh__Denorm_Account_Opportunity__c>();
        if(qType == WONLY) {
            relatedOpps = gtWONLYOpp(accId);
        } else if(qType == LOSTLY) {
            relatedOpps = gtLOSTLYOpp(accId);
        } else if(qType == OPENLY) {
            relatedOpps = gtOPENLYOpp(accId);
        } else if(qType == WONL4M) {
            relatedOpps = gtWONL4MOpp(accId, todayDate, todayLastYear, last4MDate, lastYear4MDate);
        } else if(qType == LOSTL4M) {
            relatedOpps = gtLOSTL4MOpp(accId, todayDate, todayLastYear, last4MDate, lastYear4MDate);
        } else if(qType == CREATEDLY) {
            relatedOpps = gtCREATEDLYOpp(accId, todayDate, todayLastYear, last4MDate, lastYear4MDate);
        } else if(qType == CREATEDL4M) {
            relatedOpps = gtCREATEDL4MOpp(accId, todayDate, todayLastYear, last4MDate, lastYear4MDate);
        }
        return relatedOpps;
    }
    
    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = WONLY
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtWONLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                           convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                           FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                           AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Won
                           AND (dwp_acmh__OpportunityId__r.CloseDate = THIS_YEAR OR dwp_acmh__OpportunityId__r.CloseDate = LAST_YEAR)];
    }
    
    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = LOSTLY
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtLOSTLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                           convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                           FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                           AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Lose
                           AND (dwp_acmh__OpportunityId__r.CloseDate = THIS_YEAR OR dwp_acmh__OpportunityId__r.CloseDate = LAST_YEAR)];
    }
    
    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = OPENLY
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtOPENLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                AND (dwp_acmh__OpportunityId__r.CreatedDate = THIS_YEAR OR dwp_acmh__OpportunityId__r.CreatedDate = LAST_YEAR)];	
    } 
    
   /*
	* @author Global Desktop
	* @description Recupera las oportunidades qType = WONL4M
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtWONL4MOpp(String accId, Date todayDate, Date todayLastYear, Date last4MDate, Date lastYear4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND ((dwp_acmh__OpportunityId__r.CloseDate >= :lastYear4MDate AND dwp_acmh__OpportunityId__r.CloseDate <= :todayLastYear) 
                     OR (dwp_acmh__OpportunityId__r.CloseDate >= :last4MDate AND dwp_acmh__OpportunityId__r.CloseDate <= :todayDate))
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Won];
    } 

    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = LOSTL4M
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtLOSTL4MOpp(String accId, Date todayDate, Date todayLastYear, Date last4MDate, Date lastYear4MDate ) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND ((dwp_acmh__OpportunityId__r.CloseDate >= :lastYear4MDate AND dwp_acmh__OpportunityId__r.CloseDate <= :todayLastYear) 
                     OR (dwp_acmh__OpportunityId__r.CloseDate >= :last4MDate AND dwp_acmh__OpportunityId__r.CloseDate <= :todayDate))
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Lose];
    } 
        
   /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = CREATEDLY
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtCREATEDLYOpp(String accId, Date todayDate, Date todayLastYear, Date last4MDate, Date lastYear4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                           convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.DES_Cross_border__c,
                           dwp_acmh__OpportunityId__r.StageName, dwp_acmh__OpportunityId__r.CreatedDate 
                           FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                           AND ((dwp_acmh__OpportunityId__r.CreatedDate = LAST_YEAR AND dwp_acmh__OpportunityId__r.CreatedDate <= :todayLastYear) 
                                OR (dwp_acmh__OpportunityId__r.CreatedDate = THIS_YEAR AND dwp_acmh__OpportunityId__r.CreatedDate <= :todayDate))];    
        } 
   /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = CREATEDL4M
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtCREATEDL4MOpp(String accId, Date todayDate, Date todayLastYear, Date last4MDate, Date lastYear4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.DES_Cross_border__c,
                dwp_acmh__OpportunityId__r.StageName, dwp_acmh__OpportunityId__r.CreatedDate 
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND ((dwp_acmh__OpportunityId__r.CreatedDate >= :lastYear4MDate AND dwp_acmh__OpportunityId__r.CreatedDate <= :todayLastYear) 
                     OR (dwp_acmh__OpportunityId__r.CreatedDate >= :last4MDate AND dwp_acmh__OpportunityId__r.CreatedDate <= :todayDate))];    
    }    
}