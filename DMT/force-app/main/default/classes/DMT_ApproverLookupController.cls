public with sharing class DMT_ApproverLookupController {
    
    // Clase wrapper para los resultados
    public class LookupResult {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String subtitle; // Para mostrar info adicional
        @AuraEnabled public String icon; // Icono SF
        @AuraEnabled public String entific; // Icono SF
        @AuraEnabled public List<MemberInfo> members; // Approver members relacionados
    }
    
    // Clase para la info de los miembros
    public class MemberInfo {
        @AuraEnabled public String name;
        //@AuraEnabled public String role;
        // Agrega más campos según necesites
    }
    
    // Método principal de búsqueda
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> searchApprovers(String searchTerm, Integer maxResults, String appType, String appEntific) {
        List<LookupResult> results = new List<LookupResult>();
        
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results; // No buscar con menos de 2 caracteres
        }
        
        // Preparar término de búsqueda
        String searchPattern = '%' + searchTerm + '%';
        
        // Buscar Approvers cuyo nombre coincida O que tengan Approver Members que coincidan
        List<DMT_Approver__c> approvers = [
            SELECT Id, Name, DMT_ApproverType__r.Name, DMT_Entific__c,
                   (SELECT Id, Name, DMT_User__r.Name 
                    FROM Approver_Members__r 
                    ORDER BY Name)
            FROM DMT_Approver__c
            WHERE  Name  LIKE :searchPattern
            ORDER BY Name
            LIMIT :maxResults
        ];system.debug('approvers'+ approvers.size());
        
        // También buscar directamente en Approver Members
        List<DMT_Approver_Member__c> memberApprovers = [
            SELECT Id, Name, DMT_Approver__r.Id, DMT_Approver__r.Name, 
                   DMT_Approver__r.DMT_ApproverType__r.Name, DMT_User__r.Name, DMT_Approver__r.DMT_Entific__c
            FROM DMT_Approver_Member__c
            WHERE (DMT_User__r.Name LIKE :searchPattern)
               AND DMT_Approver__r.Id NOT IN :approvers
            ORDER BY Name
            LIMIT :maxResults
        ];system.debug('memberApprovers'+ memberApprovers.size());
        
        // Procesar approvers directos
        for (DMT_Approver__c approver : approvers) {
            results.add(createLookupResult(approver));
        }
        
        // Procesar approvers encontrados a través de sus miembros
        Map<Id, DMT_Approver__c> approverMap = new Map<Id, DMT_Approver__c>();
        for (DMT_Approver_Member__c member : memberApprovers) {
            if (!approverMap.containsKey(member.DMT_Approver__r.Id)) {
                DMT_Approver__c approver = new DMT_Approver__c(
                    Id = member.DMT_Approver__r.Id,
                    Name = member.DMT_Approver__r.Name,
                    DMT_ApproverType__c = member.DMT_Approver__r.DMT_ApproverType__c
                );
                approverMap.put(approver.Id, approver);
            }
        }system.debug('approverMap'+ approverMap.size());
        
        // Obtener los approvers completos con sus miembros
        if (!approverMap.isEmpty()) {
            List<DMT_Approver__c> approversFromMembers = [
                SELECT Id, Name, DMT_ApproverType__r.Name, DMT_Entific__c,
                       (SELECT Id, Name, DMT_User__r.Name 
                        FROM Approver_Members__r 
                        ORDER BY Name)
                FROM DMT_Approver__c
                WHERE Id IN :approverMap.keySet()
            ];
            
            for (DMT_Approver__c approver : approversFromMembers) {
                // Solo agregar si no está ya en los resultados
                Boolean alreadyAdded = false;
                for (LookupResult result : results) {
                    if (result.id == approver.Id) {
                        alreadyAdded = true;
                        break;
                    }
                }
                
                if (!alreadyAdded) {
                    results.add(createLookupResult(approver));
                }
            }
        }system.debug('results'+ results.size());
        
        return results;
    }
    
    // Método para crear el resultado del lookup
    private static LookupResult createLookupResult(DMT_Approver__c approver) {
        LookupResult result = new LookupResult();
        result.id = approver.Id;
        result.name = approver.Name;
        result.subtitle = approver.DMT_ApproverType__r.Name;
        result.entific = approver.DMT_Entific__c;
        result.icon = 'standard:people'; // Cambia el icono según tu objeto
        
        // Procesar miembros relacionados
        result.members = new List<MemberInfo>();
        if (approver.Approver_Members__r != null && !approver.Approver_Members__r.isEmpty()) {
            for (DMT_Approver_Member__c member : approver.Approver_Members__r) {
                MemberInfo memberInfo = new MemberInfo();
                memberInfo.name = member.Name;
                result.members.add(memberInfo);
            }
        }
        
        return result;
    }
    
    // Método para obtener un approver específico por ID
    @AuraEnabled(cacheable=true)
    public static LookupResult getApproverById(Id approverId) {
        if (approverId == null) {
            return null;
        }
        
        List<DMT_Approver__c> approvers = [
            SELECT Id, Name, DMT_ApproverType__r.Name, DMT_Entific__c,
                   (SELECT Id, Name, DMT_User__r.Name 
                    FROM Approver_Members__r 
                    ORDER BY Name)
            FROM DMT_Approver__c
            WHERE Id = :approverId
            LIMIT 1
        ];
        
        if (approvers.isEmpty()) {
            return null;
        }
        
        return createLookupResult(approvers[0]);
    }
    
    // Método para obtener los primeros N approvers (para carga inicial)
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> getRecentApprovers(Integer maxResults) {
        List<LookupResult> results = new List<LookupResult>();
        
        List<DMT_Approver__c> approvers = [
            SELECT Id, Name, DMT_ApproverType__r.Name,
                   (SELECT Id, Name, DMT_User__r.Name 
                    FROM Approver_Members__r 
                    ORDER BY Name)
            FROM DMT_Approver__c
            ORDER BY CreatedDate DESC
            LIMIT :maxResults
        ];
        
        for (DMT_Approver__c approver : approvers) {
            results.add(createLookupResult(approver));
        }
        
        return results;
    }
}