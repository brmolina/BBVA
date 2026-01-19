global class DES_Engloba_Data_Info {
    
    @AuraEnabled
    public static String getEnglobaData(){
        DES_Booking__c book = [
                            SELECT Id,
                                    DES_Engloba_Date_Info__c
                            FROM DES_Booking__c
                            LIMIT 1
        ];
        return book.DES_Engloba_Date_Info__c;
    }
    
}