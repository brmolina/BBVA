@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class ONB_AgreementsService {

    public static Wrapper getAgreements(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        HttpResponse response = ONB_Utils.callService('ONB_Agreements', request);

        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            res = (Wrapper) JSON.deserialize(response.getBody(), Wrapper.class);
            res.success = true;
        } else {
            res.success = false;
            res.errorMessage = String.valueOf(response.getBody());
        }
        return res;
    }

    public class Wrapper {
        @AuraEnabled public Data data { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }

    public class Data {
        @AuraEnabled public List<AgreementResponse> agreementResponses { get; set; }
    }

    public class AgreementResponse {
        @AuraEnabled public List<Agmt> agmts { get; set; }
    }

    public class Agmt {
        @AuraEnabled public String mstrAgmtInd { get; set; }
        @AuraEnabled public List<Pty> ptys { get; set; }
        @AuraEnabled public FinDetls finDetl { get; set; }
    }

    public class Pty {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String src { get; set; }
        @AuraEnabled public String admnstrtn { get; set; }
        @AuraEnabled public String agmtRdesc { get; set; }
        @AuraEnabled public List<Sub> subs { get; set; }
    }

    public class Sub {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Integer typ { get; set; }
    }

    public class FinDetls {
        @AuraEnabled public String agmtDesc { get; set; }
        @AuraEnabled public String agmtId { get; set; }
        @ AuraEnabled public String agmtDt { get; set; }
        @AuraEnabled public String scanCd { get; set; }
        @AuraEnabled public String startDt { get; set; }
        @AuraEnabled public String endDt { get; set; }
        @AuraEnabled public String agmtTyp { get; set; }
        @AuraEnabled public String agmtStat { get; set; }
        @AuraEnabled public String agmtAltId { get; set; }
        @AuraEnabled public String agmtVerId { get; set; }
        @AuraEnabled public String agmtDocId { get; set; }
        @AuraEnabled public String agmtJrsdctn { get; set; }
        @AuraEnabled public String lastUpdateDt { get; set; }
        @AuraEnabled public String lastUpdateUser { get; set; }
        @AuraEnabled public String mktId { get; set; }
        @AuraEnabled public String mktSegId { get; set; }
        @AuraEnabled public String mktSegKey { get; set; }
    }
}