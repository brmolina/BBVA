public with sharing class FollowedRecordsController {

    public static final String FORMATO_FECHA_HORA = 'YYYY/MM/dd HH:mm';
    public List<WrapperFollowedAccount> wrapperFollowedAccountList {get; set;}         
    public static final String ID_ACCOUNT = '001'; // cadena con la que empieza el ID de las Accounts
    private static User currentUser;   // necesario para actualizar la selección de "columnas para mostrar" hecha por el usuario
    //private String sortedColumn; //nombre de la columna actual por la que está ordenada la tabla. Si un usuario vuelve a pulsar en la misma columna se cambia el orden entre ASC y DESC
    //private String orderASC_DESC; // orden ASC o DESC de la columna seleccionada
    


    //Variables de control para renderizar o no las columnas que seleccione el usuario
    // Estas variables se guardan en el campo "My_Clients_Columns_To_Display__c" de User, para que a cada usuario que le se mantenga la seleccion de sus colmnas.
    //Para hacer el mapeo es importante mantener alineadas estas 14 variables con otros 14 valores almacenados en el campo  "My_Clients_Columns_To_Display__c" de User     
    public boolean accClientStarID {get; set;}
    public boolean accName {get; set;}    
    public boolean manaYTDTotalFranchise {get; set;}
    public boolean manaPercentFranchise {get; set;}    
    public boolean accCashBondYTDTotalFranchise {get; set;}
    public boolean accFXYTDTotalFranchise {get; set;}   
    public boolean accCEYTDTotalFranchise {get; set;}
    public boolean accMiFID {get; set;}   
    public boolean accEmirType {get; set;}   
    public boolean accDFAType {get; set;}    
    public boolean accPercentCreditConsumpt {get; set;}
    public boolean accPercentDerivativesConsumpt {get; set;}   
    public boolean accPercentDepositsConsumpt {get; set;}
    public boolean accPercentReposConsumpt {get; set;}
    public boolean accLastCall {get; set;}
    public Integer numColToDisplay {get; set;}
      
    
// ---------------
// Constructors
// ---------------  
  public FollowedRecordsController (){                        
        currentUser = [select id, My_Clients_Columns_To_Display__c FROM User Where Id = :UserInfo.getUserId()];
        System.debug('User: '+currentUser);
        setWrapperList(); // Inicializa la lista wrapper        
        initColumnsToDisplay(); // Inicializa las variables que indican las columnas que se mostrarán por defecto. Si se quiere añadir una nueva columna en la tabla: añadir el campo en la query. Añadir y rellenar el campo en la wrapperClass. Añadir una variable Checkbox e inicializarla        
  }


  public void actualizar(){
        currentUser = [select id, My_Clients_Columns_To_Display__c FROM User Where Id = :UserInfo.getUserId()];
        System.debug('User: '+currentUser);
        setWrapperList(); // Inicializa la lista wrapper        
        initColumnsToDisplay();     
  }


    @RemoteAction
    public static String getUrl() {
        String finalUrl = URL.getOrgDomainURL().toExternalForm();
        return finalUrl;

    }
  


    // ---------------
    // Private Methods
    // ---------------  
    
    // Método que rellena la lista de cuentas que se siguen, según el orden de la columna que se ha elegido (por defecto por el Name) 
    private void setWrapperList(){
        wrapperFollowedAccountList = new List<WrapperFollowedAccount>();    
        list<Id> accountIdList = new list<Id>();
        list<Account> followedAccountList = new list<Account>();        
        list<Manager_Franchise__c> followedAccManagerList = new list<Manager_Franchise__c>();
        map<Id,Manager_Franchise__c> followedAccManagerMap = new map<Id,Manager_Franchise__c>();

        List<EntitySubscription> subscriptionList = [Select Id, SubscriberId, ParentId From EntitySubscription where SubscriberId = :UserInfo.getUserId() Limit 1000];
        system.debug(Logginglevel.INFO,'>>>>>>> subscriptionList: ' + subscriptionList);        
        for (EntitySubscription eS : subscriptionList){
          String stringID = (String) eS.ParentId;
          if (stringID.startsWith(ID_ACCOUNT)) {
                accountIdList.add(eS.ParentId);
            }                
        }
                
        system.debug(Logginglevel.INFO,'>>>>>>> accountIdList: ' + accountIdList );

        /*  Hacerlo en una única query no nos vale porque puede haber Accounts que yo sigo pero no tienen ManagerFranchises porque su franquicia es nula  */
        if (!accountIdList.isEmpty()){                      
/*          
            if (String.isBlank(this.sortedColumn) ) {
                this.sortedColumn = 'Name';                 
            }
            if (String.isBlank(this.orderASC_DESC)){
                this.orderASC_DESC = 'ASC';
            }           
            String orderBy = this.sortedColumn + ' ' + this.orderASC_DESC;
                     
            followedAccountList = Database.query(
                'Select Id, ParentId, Name, Client_STAR_ID__c, YTD_Total_Franchise__c, MTD_Total_Franchise__c, Prior_Year_Franchise__c,' + 
                        'Prior_Year_Franchise_Cash_Bond__c, Cash_Bond_MTD_Total_Franchise__c, Cash_Bond_YTD_Total_Franchise__c, Prior_Year_Franchise_FX__c,' +
                         'FX_MTD_Total_Franchise__c, FX_YTD_Total_Franchise__c, Prior_Year_Franchise_CE__c, CE_YTD_Total_Franchise__c, CE_MTD_Total_Franchise__c ' +
                'FROM Account ' +
                'WHERE Id in ' + accountIdList + ' ORDER BY ' + orderBy + ' Limit 1000');                                    
                                            
             */ 
        
            followedAccountList = [Select Id, ParentId, Name, Client_STAR_ID__c, YTD_Total_Franchise__c, MTD_Total_Franchise__c, Prior_Year_Franchise__c, 
                                        Prior_Year_Franchise_Cash_Bond__c, Cash_Bond_MTD_Total_Franchise__c, Cash_Bond_YTD_Total_Franchise__c, Prior_Year_Franchise_FX__c,
                                         FX_MTD_Total_Franchise__c, FX_YTD_Total_Franchise__c, Prior_Year_Franchise_CE__c, CE_YTD_Total_Franchise__c, CE_MTD_Total_Franchise__c,
                                         Percent_Credit_consumpt__c, Percent_Deposits_consumption__c, Percent_Derivatives_consumption__c, Percent_Repos_consumption__c, MiFID_categorisation__c, Emir_type__c, DFA_type__c, SAL_ultima_llamada__c
                                    FROM Account 
                                    WHERE Id in :accountIdList ORDER BY Client_STAR_ID__c Limit 1000];
            
                     
                                    
            system.debug(Logginglevel.INFO,'>>>>>>> followedAccountList : ' + followedAccountList );
            
            // si tiene Cuentas favoritas
            if (!followedAccountList.isEmpty()){
                followedAccManagerList = [Select Id, Client_Account__c, MTD_Total_Franchise__c, Prior_year_Franchise__c, YTD_Total_Franchise__c, My_franchise_YTD_PriorYear__c
                                            FROM Manager_Franchise__c  
                                            WHERE Client_Account__c in :accountIdList and Manager_equals_User__c = true ORDER BY YTD_Total_Franchise__c Limit 1000];
                system.debug(Logginglevel.INFO,'>>>>>>> followedAccManagerList : ' + followedAccManagerList );                                            
                                            
                
                //si tiene informacion de franquicias del Manager
                if (!followedAccManagerList.isEmpty()){
                    for (Manager_Franchise__c manager: followedAccManagerList){
                        followedAccManagerMap.put(manager.Client_Account__c, manager);
                    }
                    
                } 
                
                
                for (Account followedAccount : followedAccountList){
                    WrapperFollowedAccount auxWrapper = new WrapperFollowedAccount(followedAccount, followedAccManagerMap.get(followedAccount.Id));
                    wrapperFollowedAccountList.add(auxWrapper);         
                }                 
            }           
                                               
        }                   
    }   
    
    
    // Método que inicializa las variables que definen las columnas que se mostraran en la tabla 
    private void initColumnsToDisplay(){
        this.accClientStarID  = TRUE;
        this.accName  = TRUE;                
        this.manaYTDTotalFranchise  = TRUE;
        this.manaPercentFranchise  = TRUE;
        this.accCashBondYTDTotalFranchise = FALSE;
        this.accFXYTDTotalFranchise  = FALSE;
        this.accCEYTDTotalFranchise  = FALSE;       
        this.accMiFID = FALSE;
        this.accEmirType = FALSE;
        this.accDFAType = FALSE;      
        this.accPercentCreditConsumpt = FALSE;
        this.accPercentDerivativesConsumpt = FALSE;
        this.accPercentDepositsConsumpt = FALSE;     
        this.accPercentReposConsumpt = FALSE;
        this.accLastCall  = TRUE;
        this.numColToDisplay = 5; // por defecto hay 5 columnas TRUE

        If (currentUser != null && !String.isBlank(currentUser.My_Clients_Columns_To_Display__c)) {
            setMyClientsColumnsToDisplay();     
        }
    }
    
    //Cargamos la selección que tenga el usuario guardad de "columnas a mostrar"
    //El formato del campo "My_Clients_Columns_To_Display__c" debe ser nombre de la columna=valor y separados por punto y coma: "accClientStarID=TRUE;accName=FALSE;manaYTDTotalFranchise=TRUE;
    private void setMyClientsColumnsToDisplay(){
        this.numColToDisplay = 0;
        List<String> columnsToDisplay = currentUser.My_Clients_Columns_To_Display__c.split(';');
        
        for (String columnValue : columnsToDisplay){
            String colName = columnValue.split('=')[0];
            Boolean colValue = Boolean.valueOf(columnValue.split('=')[1]);
            
            if (colValue){
                this.numColToDisplay++;
            }

            if (colName == 'ClientStarID'){
                this.accClientStarID  = colValue;
            }else if(colName == 'accName'){
                this.accName  = colValue;
            }else if(colName == 'ManaYTDFranchi'){
                 this.manaYTDTotalFranchise = colValue;
            }else if(colName == 'ManaPercent'){
                 this.manaPercentFranchise = colValue;
            }else if(colName == 'FIYTDFranchi'){
                 this.accCashBondYTDTotalFranchise = colValue;
            }else if(colName == 'FXYTDFranchi'){
                 this.accFXYTDTotalFranchise = colValue;
            }else if(colName == 'CEYTDFranchi'){
                 this.accCEYTDTotalFranchise = colValue;
            }else if(colName == 'MiFID'){
                 this.accMiFID = colValue;
            }else if(colName == 'Emir'){
                 this.accEmirType = colValue;
            }else if(colName == 'DFA'){
                 this.accDFAType = colValue;
            }else if(colName == 'CreditConsum'){
                 this.accPercentCreditConsumpt = colValue;
            }else if(colName == 'DerivConsum'){
                 this.accPercentDerivativesConsumpt = colValue;
            }else if(colName == 'DepoConsum'){
                 this.accPercentDepositsConsumpt = colValue;
            }else if(colName == 'RepConsum'){
                this.accPercentReposConsumpt = colValue;
            }else if(colName == 'LastCall'){
                this.accLastCall = colValue;
            }            
        }        
    }
    
    // Grabamos la nueva selección de "columnas a mostrar" del usuario
    //El formato del campo "My_Clients_Columns_To_Display__c" debe ser nombre de la columna=valor y separados por punto y coma: "accClientStarID=TRUE;accName=FALSE;manaYTDTotalFranchise=TRUE;
    //private void saveMyClientsColumnsToDisplay(){
    //    System.debug('LastCall: '+this.accLastCall);
    //    this.currentUser.My_Clients_Columns_To_Display__c = 'ClientStarID=' + this.accClientStarID + ';' +
    //                                                        'Name=' + this.accName + ';' +
    //                                                        'ManaYTDFranchi=' + this.manaYTDTotalFranchise + ';' +
    //                                                        'ManaPercent=' + this.manaPercentFranchise + ';' +
    //                                                        'FIYTDFranchi=' + this.accCashBondYTDTotalFranchise + ';' +
    //                                                        'FXYTDFranchi=' + this.accFXYTDTotalFranchise + ';' +
    //                                                        'CEYTDFranchi=' + this.accCEYTDTotalFranchise + ';' +
    //                                                        'MiFID=' + this.accMiFID +  + ';' +
    //                                                        'Emir=' + this.accEmirType  + ';' +
    //                                                        'DFA=' + this.accDFAType + ';' +
    //                                                        'CreditConsum=' + this.accPercentCreditConsumpt + ';' +
    //                                                        'DerivConsum=' + this.accPercentDerivativesConsumpt + ';' +
    //                                                        'DepoConsum=' + this.accPercentDepositsConsumpt + ';' +
    //                                                        'RepConsum=' + this.accPercentReposConsumpt + ';' +
    //                                                        'LastCall=' + this.accLastCall;
    //    System.debug('>>>>>>>>>>>>>>> Actualizando nueva selección de "columnas a mostrar" del usuario: ' + this.currentUser.My_Clients_Columns_To_Display__c);                                                            
    //    update this.currentUser;
    //}      
    
    // ---------------
    // Public Methods
    // ---------------   
    @remoteAction
    public static PageReference doRefreshColumns(List<boolean> listCheckbox) {        
        System.debug('>>>>>>>>>>>>>>> método doRefreshColumns');

        currentUser = [select id, My_Clients_Columns_To_Display__c FROM User Where Id = :UserInfo.getUserId()];
        
        currentUser.My_Clients_Columns_To_Display__c = 'ClientStarID=' + listCheckbox[0] + ';' +
                                                            'accName=' + listCheckbox[1] + ';' +
                                                            'ManaYTDFranchi=' + listCheckbox[2] + ';' +
                                                            'ManaPercent=' + listCheckbox[3] + ';' +
                                                            'FIYTDFranchi=' + listCheckbox[4] + ';' +
                                                            'FXYTDFranchi=' + listCheckbox[5] + ';' +
                                                            'CEYTDFranchi=' + listCheckbox[6] + ';' +
                                                            'MiFID=' + listCheckbox[7] +  + ';' +
                                                            'Emir=' + listCheckbox[8]  + ';' +
                                                            'DFA=' + listCheckbox[9] + ';' +
                                                            'CreditConsum=' + listCheckbox[10] + ';' +
                                                            'DerivConsum=' + listCheckbox[11] + ';' +
                                                            'DepoConsum=' + listCheckbox[12] + ';' +
                                                            'RepConsum=' + listCheckbox[13] + ';' +
                                                            'LastCall=' + listCheckbox[14];

        System.debug('>>>>>>>>>>>>>>> Actualizando nueva selección de "columnas a mostrar" del usuario: ' + currentUser.My_Clients_Columns_To_Display__c);                                                            
        
        update currentUser;
        
        return null; // Sólamente queremos que haga rerender de la tabla en funcion de las columnas seleccionadas (en las variables checkbox), por lo que se devuelve null
    }    
    
    /*
    public PageReference doSortByColumn() {
        String columnName = System.currentPageReference().getParameters().get('columnName');
        if (this.sortedColumn == columnName){
            if (orderASC_DESC == 'ASC') {
                this.orderASC_DESC = 'DESC';
            }else {
                this.orderASC_DESC = 'ASC';
            }                       
        }else{
            this.sortedColumn = columnName; 
            this.orderASC_DESC = 'ASC';
        }
        
        
        setWrapperList(); // se vuelve a invocar el método para que se pueble de nuevo la lista
                                
        // Sólamente queremos que haga rerender de la tabla por lo que se devuelve null
        System.debug('>>>>>>>>>>>>>>> método doSortByColumn');
        
        return null;
    } 
    */          
  
 
    // ---------------
    // Classes
    // ---------------
    // Definición de la Wrapper Class de la respuesta
    public class WrapperFollowedAccount {
            
        public String managerId {get;set;}       
        public String managerYTDTotalFranchise {get;set;}         
        public String managerPercentFranchise {get;set;}
        
        public String accountId {get;set;}        
        public String accountName {get;set;}        
        public String accountClientStarID {get;set;}
        public String accountLastCall {get;set;}
                    
        public String accountCashBondYTDTotalFranchise {get;set;}
        public String accountFXYTDTotalFranchise {get;set;}
        public String accountCEYTDTotalFranchise {get;set;}     
        public String accountMiFIDcategorisation {get;set;}
        public String accountEmirType {get;set;}
        public String accountDFAType {get;set;}
        public String accountPercentCreditConsumpt {get;set;}
        public String accountPercentDerivativesConsumpt {get;set;}
        public String accountPercentDepositsConsumpt {get;set;}       
        public String accountPercentReposConsumpt {get;set;}     
        
        /* Campos extras que no se muestran en la página */ 
        public String managerMTDTotalFranchise {get;set;}
        public String managerPriorYearFranchise {get;set;}
        
        public String accountPriorYearFranchise {get;set;}
        public String accountYTDTotalFranchise {get;set;}
        public String accountMTDTotalFranchise {get;set;}
        
        public String accountPriorYearFranchiseCashBond {get;set;}
        public String accountCashBondMTDTotalFranchise {get;set;}
        
        public String accountPriorYearFranchiseFX {get;set;}
        public String accountFXMTDTotalFranchise {get;set;}
        
        public String accountPriorYearFranchiseCE {get;set;}
        public String accountCEMTDTotalFranchise {get;set;}
           
        
        public WrapperFollowedAccount(Account followedAccount, Manager_Franchise__c manager){

                managerId = (manager == null ? '' : manager.Id);
                managerYTDTotalFranchise = (manager == null || manager.YTD_Total_Franchise__c == null ? '0' : String.valueOf(manager.YTD_Total_Franchise__c.format()) );
                managerPercentFranchise = (manager == null || manager.my_franchise_YTD_PriorYear__c == null ? '0' : String.valueOf(manager.my_franchise_YTD_PriorYear__c.format()) );
                
                accountId = followedAccount.Id;
                accountName = followedAccount.Name;
                accountClientStarID = followedAccount.Client_STAR_ID__c;
                
                accountCashBondYTDTotalFranchise = (followedAccount.Cash_Bond_YTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.Cash_Bond_YTD_Total_Franchise__c.format()) );
                accountFXYTDTotalFranchise = (followedAccount.FX_YTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.FX_YTD_Total_Franchise__c.format()) );
                accountCEYTDTotalFranchise = (followedAccount.CE_YTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.CE_YTD_Total_Franchise__c.format()) );
                                                                
                accountMiFIDcategorisation = followedAccount.MiFID_categorisation__c; 
                accountEmirType = followedAccount.Emir_type__c;
                accountDFAType = followedAccount.DFA_type__c;                
                
                accountPercentCreditConsumpt = (followedAccount.Percent_Credit_consumpt__c == null ? '0' : String.valueOf(followedAccount.Percent_Credit_consumpt__c.format() ) );
                accountPercentDerivativesConsumpt = (followedAccount.Percent_Derivatives_consumption__c == null ? '0' : String.valueOf(followedAccount.Percent_Derivatives_consumption__c.format() ) );
                accountPercentDepositsConsumpt = (followedAccount.Percent_Deposits_consumption__c == null ? '0' : String.valueOf(followedAccount.Percent_Deposits_consumption__c.format() ) );        
                accountPercentReposConsumpt = (followedAccount.Percent_Repos_consumption__c == null ? '0' : String.valueOf(followedAccount.Percent_Repos_consumption__c.format() ) );
                  
                
                /* Campos extras que no se muestran en la página */
                managerMTDTotalFranchise = (manager == null || manager.MTD_Total_Franchise__c == null ? '0' : String.valueOf(manager.MTD_Total_Franchise__c.format()) );
                managerPriorYearFranchise = (manager == null || manager.Prior_Year_Franchise__c == null ? '0' : String.valueOf(manager.Prior_Year_Franchise__c.format()) );                         
                
                accountYTDTotalFranchise = (followedAccount.YTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.YTD_Total_Franchise__c.format()) );                
                accountMTDTotalFranchise = (followedAccount.MTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.MTD_Total_Franchise__c.format() ) );                
                accountPriorYearFranchise = (followedAccount.Prior_Year_Franchise__c == null ? '0' : String.valueOf(followedAccount.Prior_Year_Franchise__c.format()) );    
                
                accountCashBondMTDTotalFranchise = (followedAccount.Cash_Bond_MTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.Cash_Bond_MTD_Total_Franchise__c.format()) );                
                accountPriorYearFranchiseCashBond = (followedAccount.Prior_Year_Franchise_Cash_Bond__c == null ? '0' : String.valueOf(followedAccount.Prior_Year_Franchise_Cash_Bond__c.format()) );               
                
                accountFXMTDTotalFranchise = (followedAccount.FX_MTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.FX_MTD_Total_Franchise__c.format()) );                
                accountPriorYearFranchiseFX = (followedAccount.Prior_Year_Franchise_FX__c == null ? '0' : String.valueOf(followedAccount.Prior_Year_Franchise_FX__c.format()) );               
                
                accountCEMTDTotalFranchise = (followedAccount.CE_MTD_Total_Franchise__c == null ? '0' : String.valueOf(followedAccount.CE_MTD_Total_Franchise__c.format()) );
                accountPriorYearFranchiseCE = (followedAccount.Prior_Year_Franchise_CE__c == null ? '0' : String.valueOf(followedAccount.Prior_Year_Franchise_CE__c.format()) );
                
                accountLastCall = (followedAccount.SAL_ultima_llamada__c == null ? 'Never or outdated' : String.valueOf(followedAccount.SAL_ultima_llamada__c.format(FORMATO_FECHA_HORA)) );
        }                

    }     
}