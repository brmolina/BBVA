public with sharing class ONB_AgreementsSyncController {

    public class SyncResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Integer contratosUpserted;
        @AuraEnabled public Integer junctionsInserted;
        @AuraEnabled public List<String> contratoCodes;
    }

    @AuraEnabled
    public static SyncResult syncAgreementsForAccount(Id recordId) {
        SyncResult out = new SyncResult();
        out.success = false;
        out.contratosUpserted = 0;
        out.junctionsInserted = 0;
        out.contratoCodes = new List<String>();

        try {
            if (!shouldUpdate(recordId)) {
                out.message = 'Sync not required or insufficient permissions.';
                return out;
            }

            Account acc = [SELECT Id, ONB_FINSID__c FROM Account WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];

            Map<String, Object> payloadMap = new Map<String, Object>{
                'reqId'   => 'PETICION_AGREEMENT',
                'partyId' => acc.ONB_FINSID__c,
                'role'    => 'CPARTY',
                'branch'  => '6440'
            };

            Map<String, Object> request = new Map<String, Object>();
            request.put('payload', JSON.serialize(payloadMap));

            ONB_AgreementsService.Wrapper res = ONB_AgreementsService.getAgreements(request);

            if (res == null || res.success != true) {
                out.message = 'Service call failed: ' + (res == null ? 'null response' : res.errorMessage);
                return out;
            }

            // 1. Collect all external Party IDs from the JSON to resolve them to Salesforce IDs
            Set<String> externalPartyIds = new Set<String>();
            for (ONB_AgreementsService.AgreementResponse ar : res.data.agreementResponses) {
                if (ar.agmts == null) continue;
                for (ONB_AgreementsService.Agmt ag : ar.agmts) {
                    if (ag.ptys != null) {
                        for(ONB_AgreementsService.Pty p : ag.ptys) externalPartyIds.add(p.id);
                    }
                }
            }

            // 2. Query Accounts to find the Salesforce ID for these external IDs
            Map<String, Id> externalToSfIdMap = new Map<String, Id>();
            for (Account partyAcc : [SELECT Id, ONB_FINSID__c FROM Account WHERE ONB_FINSID__c != '' AND ONB_FINSID__c IN :externalPartyIds WITH SECURITY_ENFORCED]) {
                externalToSfIdMap.put(partyAcc.ONB_FINSID__c, partyAcc.Id);
            }

            Map<String, Contrato_Marco__c> contratoByCode = new Map<String, Contrato_Marco__c>();
            List<JunctionCandidate> candidates = new List<JunctionCandidate>();

            for (ONB_AgreementsService.AgreementResponse ar : res.data.agreementResponses) {
                if (ar.agmts == null) continue;

                for (ONB_AgreementsService.Agmt ag : ar.agmts) {
                    if (ag.finDetl == null) continue;

                    ONB_AgreementsService.FinDetls fd = ag.finDetl;
                    String contractCode = fd.agmtAltId;
                    if (String.isBlank(contractCode)) continue;

                    Contrato_Marco__c cm = new Contrato_Marco__c();
                    cm.ONB_Contract_Code__c = contractCode;
                    cm.ONB_Scan_Code__c=fd.scanCd;
                    cm.gf_agmt_id__c = fd.agmtId;
                    cm.gf_agmt_doc_id__c = fd.agmtDocId;
                    cm.gf_agmt_desc__c = fd.agmtDesc;
                    cm.gf_agree_version_id__c = fd.agmtVerId;
                    cm.gf_deal_signing_date__c = parseIsoDate(fd.agmtDt);
                    cm.gf_agmt_start_date__c = fd.startDt;
                    cm.gf_agmt_end_date__c = fd.endDt;
                    cm.gf_last_update_date__c = fd.lastUpdateDt;
                    cm.gf_last_update_user__c = fd.lastUpdateUser;
                    cm.gf_market_id__c = fd.mktId;
                    cm.gf_market_segment_id__c = fd.mktSegId;
                    cm.gf_market_segment_key__c = fd.mktSegKey;

                    cm.ONB_Geography__c = fd.agmtJrsdctn;
                    cm.ONB_Contract_Status__c = fd.agmtStat;
                    cm.master_agreement_type__c = fd.agmtTyp;

                    // 3. Resolve and assign the Participant Lookup safely
                    if (ag.ptys != null && !ag.ptys.isEmpty()) {
                        ONB_AgreementsService.Pty p = ag.ptys[0];

                        // Map the legacy ID to the Salesforce ID we queried earlier
                        if (externalToSfIdMap.containsKey(p.id)) {
                            cm.participant_id__c = externalToSfIdMap.get(p.id);
                        }

                        cm.source_code_desc__c = p.src;
                        cm.star_counterparty_oper_desc__c = p.agmtRdesc;
                        cm.bbva_entity_name__c = p.admnstrtn;
                    }

                    contratoByCode.put(contractCode, cm);

                    JunctionCandidate jc = new JunctionCandidate();
                    jc.contractCode = contractCode;
                    jc.clientId = acc.Id;
                    candidates.add(jc);
                    out.contratoCodes.add(contractCode);
                }
            }

            if (contratoByCode.isEmpty()) {
                out.message = 'No usable agreements found.';
                return out;
            }

            upsert contratoByCode.values() ONB_Contract_Code__c;
            out.contratosUpserted = contratoByCode.size();

            Map<String, Id> contratoIdByCode = new Map<String, Id>();
            for (Contrato_Marco__c c : [SELECT Id, ONB_Contract_Code__c FROM Contrato_Marco__c WHERE ONB_Contract_Code__c IN :contratoByCode.keySet()]) {
                contratoIdByCode.put(c.ONB_Contract_Code__c, c.Id);
            }

            Map<String, Id> existing = new Map<String, Id>();
            for (ONB_Master_Agreement__c j : [SELECT ONB_Contrato__c FROM ONB_Master_Agreement__c WHERE ONB_Client__c = :acc.Id]) {
                existing.put(acc.Id + '-' + j.ONB_Contrato__c, j.Id);
            }

            List<ONB_Master_Agreement__c> junctionsToInsert = new List<ONB_Master_Agreement__c>();
            for (JunctionCandidate jc : candidates) {
                Id contratoId = contratoIdByCode.get(jc.contractCode);
                if (contratoId == null || existing.containsKey(jc.clientId + '-' + contratoId)) continue;

                ONB_Master_Agreement__c j = new ONB_Master_Agreement__c();
                j.ONB_Client__c = jc.clientId;
                j.ONB_Contrato__c = contratoId;
                junctionsToInsert.add(j);
            }

            if (!junctionsToInsert.isEmpty()) insert junctionsToInsert;
            out.junctionsInserted = junctionsToInsert.size();
            out.success = true;
            out.message = 'Sync completed successfully.';

        } catch (Exception e) {
            out.success = false;
            out.message = e.getMessage() + ' | ' + e.getStackTraceString();
        }
        return out;
    }

    private static Date parseIsoDate(String s) {
        if (String.isBlank(s)) return null;
        try {
            return Date.valueOf(s.substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }

    private class JunctionCandidate {
        public String contractCode;
        public Id clientId;
    }

    private static Boolean shouldUpdate(Id clientId) {
        if (!FeatureManagement.checkPermission('ONB_Onboarding_CP')) return false;

        Account acc = [SELECT ONB_FINSID__c FROM Account WHERE Id = :clientId WITH SECURITY_ENFORCED LIMIT 1];
        if (String.isBlank(acc.ONB_FINSID__c)) return false;

        List<ONB_Master_Agreement__c> agreements = [SELECT LastModifiedDate FROM ONB_Master_Agreement__c WHERE ONB_Client__c = :clientId WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 1];
        return (Test.isRunningTest() || agreements.isEmpty() || agreements[0].LastModifiedDate.addHours(6) < DateTime.now());
    }
}