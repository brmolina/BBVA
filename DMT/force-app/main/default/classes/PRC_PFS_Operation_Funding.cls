public with sharing class PRC_PFS_Operation_Funding {
    @AuraEnabled
    public  String fundingType {get;set;}
    @AuraEnabled
    public  userFunding userFunding {get;set;}
    public PRC_PFS_Operation_Funding() {
        this.fundingType = '';
        this.userFunding = new userFunding(0,0);
    }
    public  class userFunding {
        @AuraEnabled
        public  Decimal onBalance {get;set;}
        @AuraEnabled
        public  Decimal offBalance {get;set;}
        public userFunding(Decimal onBalance, Decimal offBalance) {
            this.onBalance = onBalance;
            this.offBalance = offBalance;
        }
        public userFunding(){}
    }
}