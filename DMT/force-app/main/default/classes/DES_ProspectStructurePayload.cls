public without sharing class DES_ProspectStructurePayload implements DMT_AsyncPayload {
    public Account account { get; set; }
    public Account oldAccount { get; set; }
    public String serviceName { get; set; } // 'DES_PostCreateProspect' - 'DES_PutEditProspect'
    public Integer retryCount { get; set; }

    // Constructor sin reintentos (primera ejecución)
    public DES_ProspectStructurePayload(Account account, Account oldAccount, String serviceName) {
        this.account = account;
        this.oldAccount = oldAccount;
        this.serviceName = serviceName;
        this.retryCount = 0;
    }

    // Constructor con reintentos
    public DES_ProspectStructurePayload(Account account, Account oldAccount, String serviceName, Integer retryCount) {
        this.account = account;
        this.oldAccount = oldAccount;
        this.serviceName = serviceName;
        this.retryCount = retryCount;
    }
}