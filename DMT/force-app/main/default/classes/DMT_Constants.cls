/*
Autor: vido
Fecha: 2024-02-27
*/

// Clase que contiene constantes utilizadas en la aplicación
@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_Constants {

    //Decoradores
    public static final String ALWAYS = 'always';

    //Class Names
    public static final String DMT_IP_WRAPPER = 'DMT_IP_Wrapper';

    //Method Names
    public static final String GET_CUSTOMER_HPGS = 'getCustomerHPGS';
    public static final String GET_FEATURES = 'getFeatures';

    //Attributes
    public static final String INPUT = 'input';
    public static final String OUTPUT = 'output';
    public static final String OPTIONS = 'options';
    public static final String CUSTOMER_ID = 'customerId';
    public static final String CLIENT_ID = 'clientId';
    public static final String CUSTOMER_HPG = 'CustomerHPG';
    public static final String COUNTRY_ID = 'countryId';
    public static final String COUNTRIES_TOTAL = 'countriesTotal';
    public static final String COUNTRIES = 'countries';

    public static final String CLIENT_POSITIONS_TYPE = 'clientPositionsType';
    public static final String GROUP_ID = 'groupId';
    public static final String PAGINATION_KEY = 'paginationKey';
    public static final String PAGE_SIZE = 'pageSize';
    public static final String SEARCH_DATE = 'searchDate';
    public static final String PAYLOAD = 'payload';
    public static final String TOTAL_CLIENTS ='TOTAL CLIENTS';
    public static final String USER_ID = 'userId';
    public static final String DES_GROUP_CODE = 'XXXXXXXXXXXX';

    //Contries
    public static final String CONTRY_ES = 'ES';
    public static final String CONTRY_MX = 'MX';
    public static final String CONTRY_PE = 'PE';
    public static final String CONTRY_CO = 'CO';
    public static final String CONTRY_TR = 'TR';
    public static final String CONTRY_AR = 'AR';
    public static final String CONTRY_VN = 'VN';
    public static final String CONTRY_VE = 'VE';

    public static final String SPAIN ='Spain';

    //geography
    public static final String GEOGRAPHY_ESP = 'ESP';

    //Int
    public static final Integer SERVICE_200 = 200;
    public static final Integer SERVICE_201 = 201;

    //Char
    public static final String CHAR_Y = 'Y';
    public static final String CHAR_COMMA = ',';
    public static final String CHAR_DOUBLE_QUOTES = '"';
    public static final String CHAR_SLASH = '/';
    public static final String CHAR_X = 'X';

    //Replace
    public static final String REPLACE = '[^\\s]';

    //Empty
    public static final String STRG_EMPTY = '';

    //Types
    public static final String TYPE_GROUP = 'Group';
    public static final String TYPE_SUPRA_GROUP = 'Supragroup';
    public static final String TYPE_SUBSIDIARY = 'Subsidiary';
    public static final String TYPE_CUSTOM = 'Custom';
    //public static final String TYPE_SER_SERVICE_ACCOUNT = 'SER Service Account';
    public static final String TYPE_SUBSIDIARY_COMMERCIAL_ACCOUNT = 'Subsidiary Commercial Client';

    public static final String TYPE_GROUP_QUEUE = 'Queue';

    //
    public static final String MD5 = 'MD5';

    //servicios
    public static final String HPG_COMMON_ENDPOINT = 'HPG_CommonEndPoint';
    public static final String GRANTING_TICKET_GLOBAL_INT = 'GrantingTicketGlobal_INT';

    //ENDPOINTS
    public static final String ENDPOINT_1 = 'https://aso-int-global.work-01.platform.bbva.com/risk-position/v0';
    public static final String ENDPOINT_2 = 'https://aso-int-global.work-01.platform.bbva.com/TechArchitecture/grantingTickets/V02';

    //Partitions
    public static final String IASO_PARTITION = 'iaso.ServicesPartition';

    //StaticResource
    public static final String DMT_HPG_200 = 'DMT_HPG_200';
    public static final String HPG_GLOBAL_POSITION = 'HPG_GlobalPosition';

    //Status
    public static final String DRAFT = 'Draft';
    public static final String PROPOSAL = 'Proposal';
    public static final String READYTOCLOSE = 'Ready to close';
    public static final String COMPLETE = 'Complete';
    public static final String CLOSED = 'Closed';
    public static final String WON = 'Won';
    public static final String PENDING = 'Pending';
    public static final String NOTSTARTED = 'Not Started';
    public static final String ACTIVE = 'ACTIVE';
    public static final String APPROVAL = 'Approval';
    public static final String FINISHED ='Finished';
    public static final String CANCELLED = 'Cancelled';
    public static final String COMPLETED = 'Completed';

    //CLIENT TYPE
    public static final String CLIENT = 'CLIENT';
    public static final String GROUP_CLIENT = 'GROUP';
    public static final String CUSTOM = 'CUSTOM';
    public static final String GOLDEN = 'GOLDEN';

    //Origin
    public static final String AMIWEB = 'AMIWEB';

    //Profile
    public static final String BBVA_DESKTOP_ARCE = 'BBVA Desktop ARCE';

    //ProductCodes
    public static final String PRODUCT_DERI ='1600000000';
    public static final String PRODUCT_DEPO ='1611170000';
    public static final String PRODUCT_EQUI ='1610000000';
    public static final String PRODUCT_REPO ='1611190000';

    //TIPO CLASIFICACION NIVEL RIESGO MODELO GLOBAL
    public static final String RSK_LVL_SETTLEMENT_FD ='100100';
    public static final String RSK_LVL_SETTLEMENT_DVP ='100200';
    public static final String RSK_LVL_TREASURY ='40000';
    
    public static final String RSK_DERIVATIVES ='Derivatives';
    public static final String RSK_DEPOS ='Depos';
    public static final String RSK_EQUITY ='Equities';
    public static final String RSK_SINGULAR ='Singular';

    //gf_group_priority_line_id
    public static final String GROUP_PRIORITY_FD ='01y01';
    public static final String GROUP_PRIORITY_DVP ='02y01';
    public static final String GROUP_PRIORITY_REPOS ='03y03u01';
    public static final String GROUP_PRIORITY_REPOSNOFLOW ='03y03u02';
    public static final String GROUP_PRIORITY_TERM ='03y02';
    public static final String GROUP_PRIORITY_TERM_DEPOS ='04y02';
    public static final String GROUP_PRIORITY_TERM_EQUITIES ='05y02';
    public static final String GROUP_PRIORITY_RESTRIC ='03y03';
    public static final String GROUP_PRIORITY_RESTRIC_FD ='01y02';
    public static final String GROUP_PRIORITY_RESTRIC_DVP ='02y02';

    //Feature General Consideration
    public static final String FEATURE_NAME_ISGDTCLIENT ='Clients found in GDT';
    public static final String FEATURE_NAME_ISCURRENTLINE ='Clients already included in other lines';
    public static final String FEATURE_NAME_RESTRICGREATERTERM ='Maximum consumption and maturities relationship';
    public static final String FEATURE_NAME_DERIRESTRICNOFDDVP ='Settlement and Derivatives product restrictions consistency';
    public static final String FEATURE_NAME_NOSETTLEMENTAMOUNT ='Settlement amount informed for restrictions';
    public static final String FEATURE_NAME_STARTDATE ='Line period review';
    public static final String FEATURE_NAME_LIMITCONSISTENCY ='Repos limit consistency';
    public static final String FEATURE_NAME_COUNTERPARTY = 'Client counterparty code availability';
    public static final String FEATURE_NAME_RATING = 'Rating availability';
    public static final String FEATURE_NAME_ISDA = 'ISDA contract availability';
    public static final String FEATURE_NAME_AMOUNTHIGHER = 'Product amount consistency';
    public static final String FEATURE_NAME_CLIENTS_SELECTED = 'Clients selected';
    public static final String FEATURE_GC_ID ='100';
    public static final String FEATURE_GC_NAME ='General Validations';
    public static final String FEATURE_GC_PASSPORTSANCTION ='passport';
    public static final String FEATURE_GC_ACTIVE ='Y';
    public static final String FEATURE_GC_MOTORDESC ='Salesforce';
    public static final String FEATURE_GC_STATE_RED ='RED';
    public static final String FEATURE_GC_STATE_GREEN ='GREEN';
    public static final String FEATURE_GC_STATE_YELLOW ='YELLOW';
    public static final String AMOUNT_HIGHER_REDMESSAGE = 'The following products have a higher amount than the line: ';
    public static final String NO_GDT_CLIENT_REDMESSAGE ='The following local clients were not found in Global Desktop: ';
    public static final String CURRENT_CLIENT_LINE_REDMESSAGE ='The following clients are already included in other current lines: ';
    public static final String GREATER_RESTRIC_TERM_REDMESSAGE ='There are maturities in the product restrictions longer than the maximum consumption limit: ';
    public static final String DERIVATIVES_NOFDDVP_REDMESSAGE ='In product restrictions, settlement selections are not consistent with the current allowed derivatives products in the line: ';
    public static final String NO_SETTLEMENT_REDMESSAGE ='without amount and has operational restrictions for the following products: ';
    public static final String START_DATE_REDMESSAGE = 'Start date of the line is earlier than today';
    public static final String LIMIT_CONSISTENCY_REDMESSAGE = 'Limit for repos total is lower than limit for no-flow repos';
    public static final String COUNTERPARTY_REDMESSAGE = 'The following local clients do not have a counterparty code: ';
    public static final String RATING_REDMESSAGE = 'The following local clients do not have a valid rating (expired or unexisting): ';
    public static final String ISDA_REDMESSAGE = 'The following local clients do not have a signed ISDA contract: ';
    public static final String CLIENT_SELECTED_REDMESSAGE = 'The line has been created, but you must select at least two customers.';
    public static final String NO_GDT_CLIENT_GREENMESSAGE ='All the selected local clients exist in Global Desktop';
    public static final String CURRENT_CLIENT_LINE_GREENMESSAGE ='None of the clients are already included in another current line';
    public static final String GREATER_RESTRIC_TERM_GREENMESSAGE ='All the maturities in the product restrictions are shorter than the maximum consumption limit';
    public static final String DERIVATIVES_NOFDDVP_GREENMESSAGE ='In product restrictions, settlement selections are consistent with the current allowed derivatives products in the line';
    public static final String NO_SETTLEMENT_GREENMESSAGE ='Neither Free Delivery nor Delivery versus Payment have no operational restrictions and amount 0.';
    public static final String NO_SETTLEMENT_GREENMESSAGE_AR = 'Delivery versus Payment have no operational restrictions and amount 0.';
    public static final String START_DATE_GREENMESSAGE = 'Start date of the line is not earlier than today';
    public static final String LIMIT_CONSISTENCY_GREENMESSAGE = 'Limit for repos total is equal or higher than limit for no-flow repos';
    public static final String COUNTERPARTY_GREENMESSAGE = 'All the local clients already have a counterparty code';
    public static final String RATING_GREENMESSAGE = 'All the local clients have valid rating';
    public static final String ISDA_GREENMESSAGE = 'All the local clients already have signed ISDA contracts';
    public static final String AMOUNT_HIGHER_GREENMESSAGE = 'All product amount are correct.';
    public static final String CLIENT_SELECTED_GREENMESSAGE = 'A set of customers in the group has been correctly selected.';

    //recordType Names
    public static final String TASK_RT_APPROVAL_STEP ='DMT_Step_Approval';
    public static final String CASE_RT_APPROVAL ='Approval';

    //Approver Types
    public static final String APPROVER_TYPE_RISK ='Risk';
    public static final String APPROVER_TYPE_BUSINESS ='Business';

    //Prospects
    public static final String DMT_PROSPECT_PREFIX = '[P]';

    //HPG anonymization constants
    public static final List<String> ANON_ANY = new List<String>{'XX'};
    public static final List<String> ANON_MX = new List<String>{'MX'};
    public static final List<String> ANON_ALL_COUNTRIES = new List<String>{'ES', 'MX', 'PE', 'CO', 'TR', 'AR', 'VN', 'VE'};
    public static final String MEX = 'MEX';

    //Opportunity product Sustainable Deal Assessment SubCategorys Values
    public static final String DMT_SUSTAINABLE_GREEN = 'Green';
    public static final String DMT_SUSTAINABLE_SOCIAL = 'Social';
    public static final String DMT_SUSTAINABLE_GREEN_AND_SOCIAL = 'Green and social';
    public static final String DMT_SUSTAINABLE_USE_OF_PROCEEDS_SUBTYPE = 'Use of proceeds';  
    public static final String DMT_SUSTAINABLE_SSL_SUBTYPE = 'Sustainability Linked Loan';

    //Opportunity product Sustainable Deal Assessment
    public static final String DMT_SUSTAINABILITY_SSL = '4';
    public static final String DMT_SUSTAINABILITY_SSL_GREEN = '3';
    public static final String DMT_SUSTAINABILITY_USE_OF_PROCEEDS = '6';
    public static final String DMT_SUSTAINABILITY_SUSTAINABLE_LOAN = '5';
    public static final String DMT_SUSTAINABILITY_CHAIN_FINANCE = '2';
    public static final String DMT_SUSTAINABILITY_TRANSITION_FINANCE = '7';

    //Catalogos sostenibilidad
    public static final String DMT_TAXO_CATALOG_RBGR = 'RBGR';
    public static final String DMT_TAXO_CATALOG_RBSO = 'RBSO';
    public static final String DMT_TAXO_CATALOG_RBES = 'RBES';
    public static final String DMT_TAXO_CATALOG_RBST = 'RBST';

    public static final String RT_OPP_DMT_NAME = 'DMT_Opportunity';

}