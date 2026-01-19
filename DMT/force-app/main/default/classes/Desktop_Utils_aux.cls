/**********************************************************************************
* @author       Global Desktop
* @date         11/07/2019
* @description  Clase de variables globales
* @Revision
**********************************************************************************/
global without sharing class Desktop_Utils_aux { //NOSONAR
    /*Chatter notifications*/
	global static List<ConnectApi.BatchInput> batchFeedItemInputs = new List<ConnectApi.BatchInput>(); //NOSONAR
    /*Edit add error*/
    global static final Boolean addEditError = true;

    /*
    * @author Global Desktop
    * @Description Funcion que genera el post de chatter para las notificaciones
    */
    global static void generarPostChatter(Id idUser, String textNotification) {
		System.debug('idUser: ' + idUser);
        System.debug('textNotification: ' + textNotification);
        final ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        final ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = idUser; // The ID of the user to mention.
        messageInput.messageSegments.add(mentionSegment);
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' ' + textNotification;
        messageInput.messageSegments.add(textSegment);
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = '.';
        messageInput.messageSegments.add(textSegment);
        final ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = idUser;
        final ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
        batchFeedItemInputs.add(batchInput);
        System.debug('batchFeedItemInputs.size(): ' + batchFeedItemInputs.size());
        if(batchFeedItemInputs.size() == 500 || !test.isRunningTest()) { //NOSONAR
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchFeedItemInputs);
            batchFeedItemInputs = new List<ConnectApi.BatchInput>();
            System.debug('>>>>> batchFeedItemInputs FORMATEADO : ' + batchFeedItemInputs);
        }
    }

    /*
    * @author Global Desktop
    * @Description Gives edit access to AP
    */
    public static acpl__Account_Planning__Share newManualSharingAccountPlanning(Id recordId, Id userOrGroupId, String accessType) {
        // Creo un registro del sharing object de account planning
        acpl__Account_Planning__Share apShare;
        final List<acpl__Account_Planning__Share> shareExisting = [SELECT Id FROM acpl__Account_Planning__Share
                                                    WHERE ParentId =: recordId AND UserOrGroupId =: userOrGroupId
                                                    AND AccessLevel = 'Edit' AND RowCause =: Schema.acpl__Account_Planning__Share.RowCause.Manual];
        if(shareExisting.isEmpty()) {
            apShare  = new acpl__Account_Planning__Share();
            // Vinculo el registro que quiero compartir
            apShare.ParentId = recordId;
            // Vinculo el usuario/grupo con el que lo quiero compartir
            apShare.UserOrGroupId = userOrGroupId;
            // Indico el nivel de acceso
            apShare.AccessLevel = accessType;
            // Indico que es un share manual
            apShare.RowCause = Schema.acpl__Account_Planning__Share.RowCause.Manual;
        }

        return apShare;
    }

    /*
    * @author Global Desktop
    * @Description Gives edit access to AP
    */
    public static void insertSharingAP(List<acpl__Account_Planning__Share> apToInsert) {
        if(!apToInsert.isEmpty()) {
            final List<Database.SaveResult> listSR_AP = Database.insert(apToInsert, false); //NOSONAR
        }
    }

    /*
    * @author Global Desktop
    * @Description Get Account_Planning__Share record for an user related to an account planning
    */
    public static acpl__Account_Planning__Share getManualSharingAccountPlanning(Id recordId, Id userOrGroupId) {
        final List<acpl__Account_Planning__Share> liShareReturn = [SELECT Id FROM acpl__Account_Planning__Share WHERE ParentId =: recordId AND UserOrGroupId =: userOrGroupId AND AccessLevel =: 'Edit'];
        acpl__Account_Planning__Share shareReturn;
        if(!liShareReturn.isEmpty()) {
            shareReturn = liShareReturn.get(0);
        }

        return shareReturn;
    }

    /*
    * @author Global Desktop
    * @Description Delete sharing record for user related to AP
    */
    public static void deleteSharingAP(List<acpl__Account_Planning__Share> apToDelete) {
        if(!apToDelete.isEmpty()) {
            final List<Database.DeleteResult> listDR_AP = Database.delete(apToDelete, false); //NOSONAR
        }
    }
    
    /*
    * @author Global Desktop
    * @Description Gives edit access to BP
    */
    public static bupl__BusinessPlan__Share newManualSharingBusinessPlan(Id recordId, Id userOrGroupId, String accessType) {
        bupl__BusinessPlan__Share bpShare;
        final List<bupl__BusinessPlan__Share> shareExisting = [SELECT Id FROM bupl__BusinessPlan__Share
                                                    WHERE ParentId =: recordId AND UserOrGroupId =: userOrGroupId
                                                    AND AccessLevel = 'Edit' AND RowCause =: Schema.bupl__BusinessPlan__Share.RowCause.Manual];
        if(shareExisting.isEmpty()) {
            bpShare  = new bupl__BusinessPlan__Share();
            bpShare.ParentId = recordId;
            bpShare.UserOrGroupId = userOrGroupId;
            bpShare.AccessLevel = accessType;
            bpShare.RowCause = Schema.bupl__BusinessPlan__Share.RowCause.Manual;
        }
        return bpShare;
    }

    /*
    * @author Global Desktop
    * @Description Gives edit access to BP
    */
    public static void insertSharingBP(List<bupl__BusinessPlan__Share> bpToInsert) {
        if(!bpToInsert.isEmpty()) {
            final List<Database.SaveResult> listSR_BP = Database.insert(bpToInsert, false); //NOSONAR
        }
    }

    /*
    * @author Global Desktop
    * @Description Get BusinessPlan__Share record for an user related to a Business Plan
    */
    public static bupl__BusinessPlan__Share getManualSharingBusinessPlan(Id recordId, Id userOrGroupId) {
        final List<bupl__BusinessPlan__Share> liShareReturn = [SELECT Id FROM bupl__BusinessPlan__Share WHERE ParentId =: recordId AND UserOrGroupId =: userOrGroupId AND AccessLevel =: 'Edit'];
        bupl__BusinessPlan__Share shareReturn;
        if(!liShareReturn.isEmpty()) {
            shareReturn = liShareReturn.get(0);
        }

        return shareReturn;
    }

    /*
    * @author Global Desktop
    * @Description Delete sharing record for user related to BP
    */
    public static void deleteSharingBP(List<bupl__BusinessPlan__Share> bpToDelete) {
        if(!bpToDelete.isEmpty()) {
            final List<Database.DeleteResult> listDR_BP = Database.delete(bpToDelete, false); //NOSONAR
        }
    }
}