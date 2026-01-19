public with sharing class BannerAccountController {

    public Account account {get; set;}
    public String accountCodeName {get; set;}
    public String accountCode {get; set;}
    
    // Contactos y oportunidades relacionadas con la cuenta actual
    public List<Contact> contacts {get; set;}
    public List<Opportunity> oppys {get; set;}

    public String displayFX {get; set;}
    public String displayRA {get; set;}
    public String displayCR {get; set;}
    public String displayEQ {get; set;}
    public String displayGT {get; set;}

    /** Formatted franchises **/
    public String YTD_Total_Franchise {get; set;}
    public String FX_YTD_Total_Franchise {get; set;}
    public String RATES_YTD_Total_Franchise {get; set;}
    public String CREDIT_YTD_Total_Franchise {get; set;}
    public String EQUITY_YTD_Total_Franchise {get; set;}
    public String GTB_YTD_Total_Franchise {get; set;}
    //public String FI_Franchise {get; set;}
    public String MTD_Total_Franchise {get; set;}
    public String FX_MTD_Total_Franchise {get; set;}
    public String RATES_MTD_Total_Franchise {get; set;}
    public String CREDIT_MTD_Total_Franchise {get; set;}
    public String EQUITY_MTD_Total_Franchise {get; set;}
    public String GTB_MTD_Total_Franchise {get; set;}
    //public String FX_Franchise {get; set;}
    public String PY_Franchise {get; set;}
    public String PY_Franchise_FX {get; set;}
    public String PY_Franchise_RATES {get; set;}
    public String PY_Franchise_CREDIT {get; set;}
    public String PY_Franchise_EQUITY {get; set;}
    public String PY_Franchise_GTB {get; set;}
    //public String CE_Franchise {get; set;}
    public String PYTD_Franchise {get; set;}
    public String PYTD_Franchise_FX {get; set;}
    public String PYTD_Franchise_RATES {get; set;}
    public String PYTD_Franchise_CREDIT {get; set;}
    public String PYTD_Franchise_EQUITY {get; set;}
    public String PYTD_Franchise_GTB {get; set;}

    /** Profile Ids **/
/*    
    private final static Id ID_PROFILE_FI = '00e24000000QOiv';
    private final static Id ID_PROFILE_FX = '00e24000000QOj0';
    private final static Id ID_PROFILE_EQ = '00e24000000QOiq';
    private final static Id ID_PROFILE_FI_FX = '00e24000000QOil';
*/
    private final static String ASSETCLASS_FI = 'FI';       
    private final static String ASSETCLASS_FX = 'FX';
    private final static String ASSETCLASS_EQ = 'EQ';
    private final static String ASSETCLASS_FI_FX = 'FI;FX';
 
    
    private static Map<Integer, String> monthsOfYear = new Map<Integer, String> {
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10=> 'October',
        11=> 'November',
        12=> 'December'
    };
    
    public BannerAccountController(ApexPages.StandardController controller) {
        try{
        account = [
            select Id, Name, Client_STAR_ID__c, NSV_Code__c, Sector__c, Phone, Website, YTD_Total_Franchise__c, 
            FX_YTD_Total_Franchise__c, SAL_YTD_Franchise_Rates__c, CE_YTD_Total_Franchise__c, SAL_YTD_Franchise_GTB__c,
            MTD_Total_Franchise__c, FX_MTD_Total_Franchise__c,SAL_MTD_Franchise_Rates__c,SAL_MTD_Franchise_Credit__c,
            CE_MTD_Total_Franchise__c,SAL_MTD_Franchise_GTB__c,Prior_Year_Franchise__c, Prior_Year_Franchise_FX__c, 
            SAL_PY_Franchise_Rates__c,SAL_PY_Franchise_Credit__c, Prior_Year_Franchise_CE__c, SAL_PY_Franchise_GTB__c, 
            SAL_PYTD_Franchise_Total__c, SAL_PYTD_Franchise_FX__c, SAL_PYTD_Franchise_Rates__c, SAL_PYTD_Franchise_Credit__c, 
            SAL_PYTD_Franchise_Equities__c, SAL_PYTD_Franchise_GTB__c, SAL_YTD_Franchise_Credit__c
            from Account
            Where Id = :controller.getID()
        ];
        
        contacts = [Select Id From Contact Where AccountId = :account.Id];
        oppys = [Select Id From Opportunity Where AccountId = :account.Id];

        accountCodeName = 'Client code';
        accountCode = account.Client_STAR_ID__c;

        /* Se comenta este trozo de código para que siempre muestre la tabla resumen con todas las celdas, independientemente del AssetClass del user
        String userAssetClass = [Select Asset_Class__c From User where id = :UserInfo.getUserId() LIMIT 1][0].Asset_Class__c;
        if (userAssetClass == ASSETCLASS_FI) {
            displayFI = 'table-cell';
            displayFX = 'none';
            displayCE = 'none';
        }else if (userAssetClass == ASSETCLASS_FX) {
            displayFI = 'none';
            displayFX = 'table-cell';
            displayCE = 'none';
        } else if (userAssetClass == ASSETCLASS_EQ) {
            accountCodeName = 'NSV Code';
            accountCode = account.NSV_Code__c;
            displayFI = 'none';
            displayFX = 'none';
            displayCE = 'table-cell';
        } else if (userAssetClass == ASSETCLASS_FI_FX) {
            displayFI = 'table-cell';
            displayFX = 'table-cell';
            displayCE = 'none';
        } else {
            displayFI = 'table-cell';
            displayFX = 'table-cell';
            displayCE = 'table-cell';
        }
        */
        
        displayFX = 'table-cell';
        displayRA = 'table-cell';
        displayCR = 'table-cell';
        displayEQ = 'table-cell';
        displayGT = 'table-cell';
        formatFranchises();
       }catch (exception ex){
           if (Account==null){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
             }else{
             System.debug('Error: ' + ex.getMessage());
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));  
           }
        }
    }
    
    // Recupera actividades del año en curso agrupadas por mes, tanto de la cuenta seleccionada como de
    // sus contactos y oportunidades relacionadas
    public String getActivitiesByDate() {
        try{
        Map<Integer, Integer> results = new Map<Integer, Integer>();
        
        for (AggregateResult ar: [
            Select count(id) total, CALENDAR_MONTH(ActivityDateCloned__c) month
            From Task
            Where CALENDAR_YEAR(ActivityDateCloned__c) = :Date.today().year()
                And WhatId In (
                    Select Id
                    From Activity__c
                    Where Account__c = :account.Id Or Contact__c In :contacts Or Opportunity__c In :oppys
                )
            Group By CALENDAR_MONTH(ActivityDateCloned__c)
            Order By CALENDAR_MONTH(ActivityDateCloned__c)
        ]) {
            results.put((Integer) ar.get('month'), (Integer) ar.get('total'));
        }
        
        for (AggregateResult ar: [
            Select count(id) total, CALENDAR_MONTH(StartDateTime) month
            From Event
            Where CALENDAR_YEAR(StartDateTime) = :Date.today().year()
                And WhatId In (
                Select Id
                From Activity__c
                Where Account__c = :account.Id Or Contact__c In :contacts Or Opportunity__c In :oppys
            ) 
            Group By CALENDAR_MONTH(StartDateTime)
            Order By CALENDAR_MONTH(StartDateTime)
        ]) {
            Integer temp = results.get((Integer) ar.get('month'));
            if (temp != null)
                temp += (Integer) ar.get('total');
            else
                temp = (Integer) ar.get('total');
                
            results.put((Integer) ar.get('month'), temp);
        }

        return toMonthList(results);
       }catch (exception ex){
           if (Account==null){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
            return null;
           }else{
             System.debug('Error: ' + ex.getMessage());
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));  
             return null;
           }
        }
    }
    
    public String getOpenActivitiesBySubject() {
        try{
		Map<String, DataItem> results = new Map<String, DataItem>();

        for (AggregateResult ar: [
            Select count(id) total, SubjectCloned__c
            From Task
            Where Status != 'Completed' And WhatId In (
                Select Id
                From Activity__c
                Where Account__c = :account.Id Or Contact__c In :contacts Or Opportunity__c In :oppys
            )
            Group By SubjectCloned__c
            Order By count(id) Desc
        ]) {
			String subject = ( (String) ar.get('SubjectCloned__c') != null ?  (String) ar.get('SubjectCloned__c') : '  ' );
			results.put(subject, new DataItem(subject, (Integer) ar.get('total')));
		}
		
		for (AggregateResult ar: [
			Select Count(Id) total, SubjectCloned__c
			From Event
			Where ActivityDate >= TODAY And WhatId In (
				Select Id
				From Activity__c
				Where Account__c = :account.Id Or Contact__c In :contacts Or Opportunity__c In :oppys
			)
			Group By SubjectCloned__c	
			Order By count(id) Desc
		]) {
			String subject = ( (String) ar.get('SubjectCloned__c') != null ?  (String) ar.get('SubjectCloned__c') : '  ' );
			Integer total = (Integer) ar.get('total');
			DataItem di = results.get(subject);
			
			if (di != null) {
				di.value += total;
			} else {
				di = new DataItem(subject, total);
			}
			
			results.put(subject, di);
        }

		List<DataItem> resultList = results.values();
		resultList.sort();

		return listToChain(resultList);
        }catch (exception ex){
            if (Account==null){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
            return null;
             }else{
             System.debug('Error: ' + ex.getMessage());
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));  
             return null;
           }
        }
    }
    @TestVisible
    private static String toMonthList(Map<Integer, Integer> results) {
        try{
        String output = '[';
        
        for (Integer i = 1; i <= 12; i++) {
            Integer r = results.get(i);
            String m = monthsOfYear.get(i);
            
            if (r == null)
                output += '[\'' + m + '\', 0]';
            else
                output += '[\'' + m + '\', ' + r + ']';
                
            if (i < 12)
                output += ', ';
        }
        
        output += ']';
        
        return output;
            }catch (exception ex){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage())); 
            return null;
        }
    }
    @TestVisible
    private static String listToChain(List<DataItem> results) {
        try{
        String output = '[';

        for (Integer i = 0; i < results.size(); i++) {
            output += '[\'' + results[i].name + '\', ' + results[i].value + ']';

            if (i < results.size() - 1)
                output += ', ';
        }

        output += ']';

        return output;
        }catch (exception ex){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,  ex.getMessage()));
            return null;
        }
    }
    @TestVisible
    private void formatFranchises() {
        try{
        /*YTD_Total_Franchise = formatFranchise(account.YTD_Total_Franchise__c);
        MTD_Total_Franchise = formatFranchise(account.MTD_Total_Franchise__c);
        Prior_Year_Franchise = formatFranchise(account.Prior_Year_Franchise__c);
        //FI_Franchise = formatFranchise(account.FI_Franchise__c);
        FI_YTD_Total_Franchise = formatFranchise(account.Cash_Bond_YTD_Total_Franchise__c);
        FI_MTD_Total_Franchise = formatFranchise(account.Cash_Bond_MTD_Total_Franchise__c);
        Prior_Year_Franchise_FI = formatFranchise(account.Prior_Year_Franchise_Cash_Bond__c);
        //FX_Franchise = formatFranchise(account.FX_Franchise__c);
        FX_YTD_Total_Franchise = formatFranchise(account.FX_YTD_Total_Franchise__c);
        FX_MTD_Total_Franchise = formatFranchise(account.FX_MTD_Total_Franchise__c);
        Prior_Year_Franchise_FX = formatFranchise(account.Prior_Year_Franchise_FX__c);
        //CE_Franchise = formatFranchise(account.CE_Franchise__c);
        CE_YTD_Total_Franchise = formatFranchise(account.CE_YTD_Total_Franchise__c);
        CE_MTD_Total_Franchise = formatFranchise(account.CE_MTD_Total_Franchise__c);
        Prior_Year_Franchise_CE = formatFranchise(account.Prior_Year_Franchise_CE__c);*/

        YTD_Total_Franchise = formatFranchise(account.YTD_Total_Franchise__c);
        FX_YTD_Total_Franchise = formatFranchise(account.FX_YTD_Total_Franchise__c);
        RATES_YTD_Total_Franchise = formatFranchise(account.SAL_YTD_Franchise_Rates__c);
        CREDIT_YTD_Total_Franchise = formatFranchise(account.SAL_YTD_Franchise_Credit__c);
        EQUITY_YTD_Total_Franchise = formatFranchise(account.CE_YTD_Total_Franchise__c);
        GTB_YTD_Total_Franchise = formatFranchise(account.SAL_YTD_Franchise_GTB__c);

        MTD_Total_Franchise = formatFranchise(account.MTD_Total_Franchise__c);
        FX_MTD_Total_Franchise = formatFranchise(account.FX_MTD_Total_Franchise__c);
        RATES_MTD_Total_Franchise = formatFranchise(account.SAL_MTD_Franchise_Rates__c);
        CREDIT_MTD_Total_Franchise = formatFranchise(account.SAL_MTD_Franchise_Credit__c);
        EQUITY_MTD_Total_Franchise = formatFranchise(account.CE_MTD_Total_Franchise__c);
        GTB_MTD_Total_Franchise = formatFranchise(account.SAL_MTD_Franchise_GTB__c);

        PY_Franchise = formatFranchise(account.Prior_Year_Franchise__c);
        PY_Franchise_FX = formatFranchise(account.Prior_Year_Franchise_FX__c);
        PY_Franchise_RATES = formatFranchise(account.SAL_PY_Franchise_Rates__c);
        PY_Franchise_CREDIT = formatFranchise(account.SAL_PY_Franchise_Credit__c);
        PY_Franchise_EQUITY = formatFranchise(account.Prior_Year_Franchise_CE__c);
        PY_Franchise_GTB = formatFranchise(account.SAL_PY_Franchise_GTB__c);

        PYTD_Franchise = formatFranchise(account.SAL_PYTD_Franchise_Total__c);
        PYTD_Franchise_FX = formatFranchise(account.SAL_PYTD_Franchise_FX__c);
        PYTD_Franchise_RATES = formatFranchise(account.SAL_PYTD_Franchise_Rates__c);
        PYTD_Franchise_CREDIT = formatFranchise(account.SAL_PYTD_Franchise_Credit__c);
        PYTD_Franchise_EQUITY = formatFranchise(account.SAL_PYTD_Franchise_Equities__c);
        PYTD_Franchise_GTB = formatFranchise(account.SAL_PYTD_Franchise_GTB__c);

        }catch (exception ex){
            if (Account==null){
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
            }else{
             System.debug('Error: ' + ex.getMessage());
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));  
           }
        }
    }
    @TestVisible
    private static String formatFranchise(Decimal value) {
        if (value == null || value == 0 ){
            return 'N/A';
        }else{
        	return value.intValue().format() + '*';     	
        }
/*        
        Decimal v = value;
        Integer counter = 0;
        while (v > 1000 && counter < 3) {
            v = Math.round(v / 10);
            v /= 100;
            counter++;
        }

        String measure;
        if (counter == 1)
            measure = 'K';
        else if (counter == 2)
            measure = 'M';
        else if (counter == 3)
            measure = 'B';
        
        if (measure != null)
        return '€' + v + measure ;
        else
        return '€' + v;
*/
    }

	class DataItem implements Comparable {
        public String name {get; set;}
        public Integer value {get; set;}

        public DataItem(String name, Integer value) {
            this.name = name;
            this.value = value;
        }
		
		public Integer compareTo(Object obj) {
			DataItem di = (DataItem) obj;
			
			return di.value - this.value; 
		}
    }
}