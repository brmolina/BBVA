/**
*    Author:        Julio L
*    Company:       Accenture
*    Description:   Web Service REST que se expone para consultar los casos.
*
*    <Date>              <Author>                <Description>
*    2018-05-04          Julio L                 Creación de la clase
*    2018-11-26          Javier Touchard         V-2.0
*/
@RestResource(urlMapping='/CasesRelated/*')
global with sharing class SER_CaseRestRelatedCases {

    /*Instancia única de la clase para implementar un patrón Singleton*/
    private static SER_CaseRestRelatedCases instance;

    // CONSTANTES
    /**Constante 'Operation successful.'*/
    private static final String MSG_SUCCESS = 'Operation successful.';
    /**Constante 'Failure.'*/
    private static final String MSG_FAIL    = 'Failure.';
    /**Constante 'Null value found in required fields'. MSG_NULL_VALUE_REQUIRED_FIELDS*/
    private static final String MSG_NULL_VALUE = 'Null value found in required fields';
    /**Constante 'Access from Web Service REST '*/
    private static final String MSG_STR_ACCESS = 'Access from Web Service REST ';
    /**Constante 'Only inform a parameter'. MSG_INFORM_PARAMETER*/
    private static final String MSG_INFORMPARAM = 'Only inform a parameter';
    /**Constante ''dd/MM/yyyy HH:mm:ss''*/
    private static final String DATE_FORMAT = 'dd/MM/yyyy HH:mm:ss';
    /**Constante ''dd/MM/yyyy HH:mm:ss''*/
    private static final String GMT = 'GMT';


    /*
    * @Description: Constructor privado.
    */
    private SER_CaseRestRelatedCases() {}

    /*
    * @Description: devuelve una instancia unica de esta clase. Patron Singleton.
    */
    public static SER_CaseRestRelatedCases getInstance() {
        // lazy load the record type - only initialize if it doesn't already exist
        if(instance == null) {
            instance = new SER_CaseRestRelatedCases();
        }
        return instance;
    }

    /**
    * Consulta los casos asociados a un cliente mediante el cclient
    * o los casos asociados a los clientes con el mismo producto asociado
    * mediante el productReference.
    *
    * @return <tt>Result</tt> objeto con el estado, detalle y listado de casos.
    */
    @HttpGet
    global static Result queryCases() {

        SData data;
        data = new SData();
        String strParameters = '';
        Result result;
        result = new Result();

        try {
            data.idClient = RestContext.request.params.get('idClient');
            data.productReference = RestContext.request.params.get('productReference');

            system.debug('JLB - ENTRADA - idClient: ' + data.idClient);
            system.debug('JLB - ENTRADA - productReference: ' + data.productReference);

            // Info solo para informar el log de error
            strParameters = ' [Cclient: '+data.idClient + ' - productReference: '+data.productReference +']';

            result.lstCasesRelated = new List<caseRelated>();

            Boolean maxMistral;
            maxMistral = !String.isBlank(data.idClient) && String.isBlank(data.productReference);

            // Max Mistral utiliza el idClient. Product reference debe estar vacio
            if (maxMistral) {
                result = queryMMCasuistry (data,result);
            // NetCash y Boss utilizan el productReference. IdClient tiene que ser vacio
            } else if (!String.isBlank(data.productReference) && String.isBlank(data.idClient)) {
                result = queryNBCasuistry(data,result);
            } else if (String.isBlank(data.idClient) && String.isBlank(data.productReference)) {
                // El campo no esta informado
                result.statusCode = '3';
                // Se informa el detalle del error
                result.detail = MSG_NULL_VALUE;
                // Insertamos un log si ha habido algun fallo
                CIB_LogUtils.create_Log(MSG_STR_ACCESS, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strParameters);
            } else if (!String.isBlank(data.idClient) && !String.isBlank(data.productReference)) {
                // Error si los dos campos estan informados
                result.statusCode = '4';
                // Se informa el detalle del error
                result.detail = MSG_INFORMPARAM;
                // Insertamos un log si ha habido algun fallo
                CIB_LogUtils.create_Log(MSG_STR_ACCESS, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strParameters);
            }
        } catch ( Exception ex ) {
            result.statusCode = '2';
            result.detail = MSG_FAIL + ' : ' + ex;
            // Insertamos un log si ha habido algun fallo
            CIB_LogUtils.create_Log(MSG_STR_ACCESS, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strParameters);
        }

        return result;
    }

    /**
    * Retorna los Ids de los clientes asociados al producto.
    *
    * @param productReference <tt>String</tt> codigo del producto de referencia.
    * @return <tt>Set<Id></tt> lista de ids de clientes con un mismo productReference.
    */
    private static Set<Id> getAccounts(final String productReference) {

        System.debug('JLB - getAccounts-productReference: ' + productReference);

        Set<Id> setIdAcc;
        setIdAcc = new Set<Id>();
        for(SER_Transactional__c stt : [select Id, SER_Account__c, SER_Product_Text__c
                                        from SER_Transactional__c
                                        where name = :productReference]) {
            System.debug('JLB - idAcc: ' + stt.Id + ' - Account: '+stt.SER_Account__c);
            setIdAcc.add(stt.SER_Account__c);
        }

        System.debug('JLB - Size Acc-productRef: ' + setIdAcc.size());

        return setIdAcc;

    }

    /**
    * Casuistica de Max Mistral.
    *
    * @param SData data
    * @return Result
    */
    private static Result queryMMCasuistry(SData data, Result result) {
        system.debug('JLB - MAX - idClient: ' + data.idClient);
        Result mmResult;
        mmResult = result;
        for(Account acc :
            [
                select id, name, recordtype.name,ser_cclient__c,
                (select id, caseNumber, CreatedDate, subject, SER_Transactional_Reference__r.name,
                    SER_Product__c, SER_Classification__c, Priority, status, owner.name, Contact.name,
                    SER_User_Code_Web_Service__c, Description, Origin, Contact.Phone, Contact.Email,
                    ClosedDate, SER_Case_Creator__c, SER_Solution__c
                    from cases)
                from account
                where ser_cclient__c = :data.idClient
            ]) {
                system.debug('JLB - MAXM acc.id> ' + acc.id);
                for (Case  caso: acc.cases) {
                    system.debug('JLB - MAXM caso> ' + caso);
                    CaseRelated caseRelated;
                    caseRelated = new CaseRelated();
                    caseRelated.caseId = caso.id;
                    caseRelated.caseNumber = caso.caseNumber;
                    caseRelated.caseStatus = caso.status;
                    caseRelated.caseCreatedDate = caso.CreatedDate.format(DATE_FORMAT,GMT);
                    caseRelated.caseSubject =  caso.subject;
                    caseRelated.caseProductName = caso.SER_Product__c;
                    caseRelated.caseClassification = caso.SER_Classification__c;
                    caseRelated.caseSSTTProduct = caso.SER_Transactional_Reference__r.name;
                    caseRelated.casePriority = caso.Priority;
                    caseRelated.caseOwner = caso.owner.name;
                    caseRelated.caseCreator = caso.SER_Case_Creator__c;
                    //caseRelated.caseContactName = caso.Contact.name;
                    caseRelated.caseUserWS = caso.SER_User_Code_Web_Service__c;
                    if(String.isNotBlank(caso.SER_Solution__c)) {
                        caseRelated.caseDescription = 'Solution: ' + caso.SER_Solution__c + ';\n\r' + caso.Description;
                    } else {
                        caseRelated.caseDescription = caso.Description;
                    }
                    caseRelated.caseOrigin = caso.Origin;
                    caseRelated.caseName = caso.Contact.name;
                    caseRelated.casePhone = caso.Contact.Phone;
                    caseRelated.caseMail = caso.Contact.Email;
                    caseRelated.caseIdClient = acc.ser_cclient__c;
                    caseRelated.clientName = acc.name;
                    if (caso.ClosedDate != null) {
                        caseRelated.caseClosedDate = caso.ClosedDate.format(DATE_FORMAT,GMT);
                    }
                    mmResult.lstCasesRelated.add(caseRelated);
                }
        }
        system.debug('JLB - MAXM lstCases size: ' + mmResult.lstCasesRelated.size());
        mmResult.statusCode = '0';
        mmResult.detail = MSG_SUCCESS;

        return mmResult;
    }

    /**
    * Casuistica de BOSS y Net Cash.
    *
    * @param SData data
    * @return Result
    */
    private static Result queryNBCasuistry(SData data, Result result) {
        Set<Id> setIdAcc;
        setIdAcc = getAccounts(data.productReference);
        system.debug('JLB - NetCash/Boss setIdAcc: ' + setIdAcc);
        Result mmResult;
        mmResult = result;
        for(Account acc :
            [
                select id, name, recordtype.name,ser_cclient__c,
                (select id, caseNumber, CreatedDate, subject, SER_Transactional_Reference__r.name,
                    SER_Product__c, SER_Classification__c, Priority, status, owner.name, Contact.name,
                    SER_User_Code_Web_Service__c, Description, Origin, Contact.Phone, Contact.Email,
                    ClosedDate, SER_Case_Creator__c
                    from cases)
                from account
                where recordtype.name = 'SER Service Account' and id in :setIdAcc
            ]) {

            system.debug('JLB - NetCash/Boss acc.id> ' + acc.id);
            for (Case  caso: acc.cases) {
                system.debug('JLB - NetCash/Boss caso> ' + caso);
                CaseRelated caseRelated;
                caseRelated = new CaseRelated();
                caseRelated.caseId = caso.id;
                caseRelated.caseNumber = caso.caseNumber;
                caseRelated.caseStatus = caso.status;
                caseRelated.caseCreatedDate = caso.CreatedDate.format(DATE_FORMAT,GMT);
                caseRelated.caseSubject =  caso.subject;
                caseRelated.caseProductName = caso.SER_Product__c;
                caseRelated.caseClassification = caso.SER_Classification__c;
                caseRelated.caseSSTTProduct = caso.SER_Transactional_Reference__r.name;
                caseRelated.casePriority = caso.Priority;
                caseRelated.caseOwner = caso.owner.name;
                //caseRelated.caseCreator = caso.SER_Case_Creator__c;
                //caseRelated.caseContactName = caso.Contact.name;

                caseRelated.caseUserWS = caso.SER_User_Code_Web_Service__c;
                caseRelated.caseDescription = caso.Description;
                caseRelated.caseOrigin = caso.Origin;
                caseRelated.caseName = caso.Contact.name;
                caseRelated.casePhone = caso.Contact.Phone;
                caseRelated.caseMail = caso.Contact.Email;
                caseRelated.caseIdClient = acc.ser_cclient__c;
                caseRelated.clientName = acc.name;
                if (caso.ClosedDate != null) {
                    caseRelated.caseClosedDate = caso.ClosedDate.format(DATE_FORMAT,GMT);
                }
                mmResult.lstCasesRelated.add(caseRelated);
            }
        }
        system.debug('JLB - NetCash/Boss lstCases size: ' + mmResult.lstCasesRelated.size());
        mmResult.statusCode = '0';
        mmResult.detail = MSG_SUCCESS;

        return mmResult;
    }


    /**********************************************************
    ***********************   WRAPPER   ***********************
    **********************************************************/

    /*
    * @Description: Estructura objeto entrante.
    */
    global class SData {
        /** Código Cclient MaxMistral*/
        public String idClient {get; set;}
        /** Producto de referencia NetCash y Boss*/
        public String productReference {get; set;}
    }

    /*
    * @Description: Estructura objeto respuesta.
    */
    global class Result {
        /** Codigo de estado 0.- OK y 1.- FALLO*/
        public String statusCode {get; set;}
        /** Detalle del resultado*/
        public String detail {get; set;}
        /** Lista de casos relacionados*/
        public List<caseRelated> lstCasesRelated {get; set;}
    }

    /*
    * @Description: Objeto Caso relacionado.
    */
    global class CaseRelated {
        /** Id del caso*/
        public String caseId {get; set;}
        /** Número del caso*/
        public String caseNumber {get; set;}
        /** Estado del caso*/
        public String caseStatus {get; set;}
        /** Fecha de creación del caso*/
        public String caseCreatedDate {get; set;}
        /** Tema del caso*/
        public String caseSubject {get; set;}
        /** Producto del caso*/
        public String caseProductName {get; set;}
        /** Clasificación del caso*/
        public String caseClassification {get; set;}
        /** Referencia*/
        public String caseSSTTProduct {get; set;}
        /** Prioridad del caso*/
        public String casePriority {get; set;}
        /** Propietario del caso*/
        public String caseOwner {get; set;}
        /** Contacto asociado*/
        //public String caseContactName; {get; set;}

        /** Usuario NetCash, MaxMistral o Boss*/
        public String caseUserWS {get; set;}
        /** Descripción del caso*/
        public String caseDescription {get; set;}
        /** Origen del caso Web form, Max mistral o Boss*/
        public String caseOrigin {get; set;}
        /** Nombre del contacto asociado al caso*/
        public String caseName {get; set;}
        /** Telefono del contacto asociado al caso*/
        public String casePhone {get; set;}
        /** Email del contacto asociado al caso*/
        public String caseMail {get; set;}

        /** Fecha de cierre del caso. Para MaxMistral*/
        public String caseClosedDate {get; set;}
        /** Identificador del cliente. Para MaxMistral*/
        public String caseIdClient {get; set;}

        /** Nombre del cliente en Sf asociado al idclient*/
        public String clientName {get; set;}
        /** Creador del caso*/
        public String caseCreator {get; set;}

    }
}