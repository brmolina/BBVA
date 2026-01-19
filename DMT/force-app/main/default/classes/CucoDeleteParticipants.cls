/**
* ____________________________________________________________________________
* Cuco Delete Participants
* Web Service to Execute Batch that removes participants marked as deleted.
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-16
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@RestResource(urlMapping='/cucoDeleteParticipants')
@SuppressWarnings('sf:UseSingleton')
global with sharing class CucoDeleteParticipants {

    /*
    * Constructor
    */
    @TestVisible
    private CucoDeleteParticipants() {}

    /*
    *  start batch
    */
    @HttpGet
    global static Id doGet() {
        final Id batchInstanceId = Database.executeBatch(new CucoDeleteParticipantsBatch(), Integer.valueOf(System.Label.Batch_Size_Cuco));
        system.debug('Started CucoDeleteParticipantsBatch with instance ID: ' + batchInstanceId);
        return batchInstanceId;
    }

}