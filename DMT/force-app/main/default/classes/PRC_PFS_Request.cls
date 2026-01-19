public with sharing class PRC_PFS_Request {
    @AuraEnabled
    public requestbody engineWorksWith {get;set;}
    public PRC_PFS_Request() {
        this.engineWorksWith = new requestbody();
    }

    public class requestbody {
        @AuraEnabled
        public String engineWorksWithType {get;set;}
        //@AuraEnabled
        //public String investmentBankingProposalId {get;set;}
        @AuraEnabled
        public Datetime valueDate {get;set;}
        @AuraEnabled
        public List<crossSellAmount> crossSellAmounts {get;set;}
        @AuraEnabled
        public PRC_PFS_Participant participant {get;set;}
        @AuraEnabled
        public List<PRC_PFS_Matrix> matrices {get;set;}
        @AuraEnabled
        public List<PRC_PFS_Operation> operations {get;set;}
        @AuraEnabled
        public originationBranch originationBranch {get;set;}
        @AuraEnabled
        public String currenc_y {get;set;}
        public requestbody() {
            //this.investmentBankingProposalId = 'investmentBankingProposalId';
            this.valueDate = Datetime.now();
            this.crossSellAmounts = new List<crossSellAmount>{new crossSellAmount()};
            this.participant = new PRC_PFS_Participant();
            this.matrices = new List<PRC_PFS_Matrix>{new PRC_PFS_Matrix()};
            this.operations = new List<PRC_PFS_Operation>{new PRC_PFS_Operation(true)};
            this.engineWorksWithType = 'OPPORTUNITY';
        }        
    }
    public class crossSellAmount {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public Decimal amount {get;set;}
        @AuraEnabled
        public String currenc_y {get;set;}

        public crossSellAmount() {
            this.id = 'CROSS_SELL_AMOUNT';
            this.amount = 0;
            this.currenc_y = 'EUR';
        }
    }
    public class originationBranch {
        @AuraEnabled
        public String id {get;set;}
        public originationBranch() {
            this.Id = '';
        }
        public originationBranch(String Id) {
            this.Id = Id;
        }
    }
}