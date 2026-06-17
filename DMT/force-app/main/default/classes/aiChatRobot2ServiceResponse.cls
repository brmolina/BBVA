/**
 * @description       : Clase auxiliar de construcción de estructura común de respuesta de servicios
 * @author            : Matias Maquieira
 * @group             : NEORIS
 * @last modified on  : 12-02-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   29-01-2026   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
**/
public class aiChatRobot2ServiceResponse {
    /** The content of the service response */
    @AuraEnabled public Object data;
    /** Indicates that something has gone wrong. It covers from unexpected HTTP status codes to Apex exceptions */
    @AuraEnabled public Boolean isError;
    /** A brief error message. It should not be shown to non-technical users */
    @AuraEnabled public String errorMessage;
    /** A map of error parameter names and values. It should be serialized into non-pretty-printed JSON for easy transmission and analysis */
    @AuraEnabled public Map<String, Object> errorDetails;
    
    /**
     * Constructor por defecto que inicializa la respuesta sin error
     */
    public aiChatRobot2ServiceResponse() {
        this.isError = false;
        this.data = null;
        this.errorMessage = null;
        this.errorDetails = null;
    }

    /**
     * Constructor en caso de excepción
     */
    public aiChatRobot2ServiceResponse(Exception ex) {
        this.isError = true;
        this.data = null;
        this.errorMessage = ex.getMessage();
        this.errorDetails = new Map<String, Object>{
                                'stackTrace' => ex.getStackTraceString(),
                                'type' => ex.getTypeName()
                            };
    }
}