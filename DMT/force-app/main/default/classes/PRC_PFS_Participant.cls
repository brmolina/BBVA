public with sharing class PRC_PFS_Participant {
    @AuraEnabled
    public String id {get;set;}
    @AuraEnabled
    public String groupType {get;set;}
    @AuraEnabled
    public String rating {get;set;}
    @AuraEnabled
    public String economicGroupRating {get;set;}
    //@AuraEnabled
    //public String clientIndustry {get;set;}
    @AuraEnabled
    public sector sector {get;set;}
    /* @AuraEnabled
    public String country {get;set;} */
    @AuraEnabled
    public country country {get;set;}
    /* @AuraEnabled
    public String branch {get;set;} Obsoleto por V3.0 API su correspondencia e sun campo nuevo en request y response*/

    
    @AuraEnabled
    public totalSells totalSells {get;set;}
    public PRC_PFS_Participant() {
        this.id = '';
        this.groupType = '';
        this.rating = '';
        this.economicGroupRating = '';
        //this.clientIndustry = '';
        /* this.country = ''; */
        this.country = new country();
        this.sector = new sector();
        this.totalSells = new totalSells(0,'EUR');
    }
    public class totalSells {
        @AuraEnabled
        public Decimal amount {get;set;}
        @AuraEnabled
        public String currenc_y {get;set;}
        public totalSells() {}
        public totalSells(Decimal amount,String currenc_y) {
            this.amount = amount;
            this.currenc_y = currenc_y;
        }
    }
    public class sector {
        @AuraEnabled
        public String id {get;set;}
        public sector(){}
    }
    public class country {
        @AuraEnabled
        public String id {get;set;}
        public country() {
            this.id = '';
        }
        public country(String Id) {
            this.id = Id;
        }
    }
}