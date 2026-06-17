import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const CONTACT_API_NAME = 'Contact';
const EXTERNAL_CONTACT_API_NAME = 'ONB_External_Contact__c';
const ONBOARDING_CONTACT_RELATIONSHIP_API_NAME = 'ONB_Onboarding_Contact_Relationship__c';
const RELATIONSHIP_CONTACT_TYPE = 'RELATIONSHIP_CONTACTS';

/**
 * Valida el email y crea el Contacto y su Relación.
 * @param {Object} cmp - Referencia al componente padre (this) para poder lanzar Toasts.
 * @param {Object} contactData - Los campos recolectados del formulario.
 * @param {String} onboardingId - El ID del Onboarding actual.
 * @param {String} contactType - El tipo de contacto (RISK, RELATIONSHIP, LIQUIDATION...).
 * @param {String} existingContactId - (Opcional) Si se está editando un contacto existente, su ID para actualizar en vez de crear.
 * @returns {Object} { success: boolean, contactId: string }
 */

export async function processAndCreateContact(cmp, contactData, onboardingId, contactType, existingContactId = null) {
    const emailIngresado = contactData.Email_ExternalID__c;

    // 1. Validación del correo

    //Solo cuando sea RELATIONSHIP_CONTACTS
    if (contactType === RELATIONSHIP_CONTACT_TYPE && emailIngresado && !emailIngresado.toLowerCase().endsWith('@bbva.com')) {
        cmp.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Email',
                message: 'The email address must end with @bbva.com',
                variant: 'error'
            })
        );
        return { success: false };
    }

    try {
        if (existingContactId) {
            const camposParaActualizar = Object.assign({}, contactData);
            camposParaActualizar.Id = existingContactId;
            await updateRecord({ fields: camposParaActualizar });
            return { success: true, contactId: existingContactId };
        }else{
            // 2. Crear Contacto
            const contactRecord = await createRecord({
                apiName: CONTACT_API_NAME,
                fields: contactData
            });

            // 3. Crear Relación
            const relationshipFields = {
                'ContactId__c': contactRecord.id,
                'Email__c': contactRecord.Email_ExternalID__c,
                'OnboardingId__c': onboardingId,
                'ONB_Contact_Type_State__c': contactType
            };

            await createRecord({
                apiName: ONBOARDING_CONTACT_RELATIONSHIP_API_NAME,
                fields: relationshipFields
            });

            return { success: true, contactId: contactRecord.id };
        }

    } catch (error) {
        console.error('Error al crear el contacto:', JSON.stringify(error));
        cmp.dispatchEvent(
            new ShowToastEvent({
                title: 'Error saving contact',
                message: error?.body?.message || 'Check the data and try again.',
                variant: 'error'
            })
        );
        return { success: false };
    }
}

export async function processAndCreateExternalContact(cmp, contactData, existingContactId = null) {

    try {
        if (existingContactId) {
            const camposParaActualizar = Object.assign({}, contactData);
            camposParaActualizar.Id = existingContactId;
            await updateRecord({ fields: camposParaActualizar });
            return { success: true, contactId: existingContactId };
        }else{
            // 2. Crear Contacto Externo
            const externalContactRecord = await createRecord({
                apiName: EXTERNAL_CONTACT_API_NAME,
                fields: contactData
            });

            return { success: true, contactId: externalContactRecord.id };
        }

    } catch (error) {
        console.error('Error al crear el contacto:', JSON.stringify(error));
        cmp.dispatchEvent(
            new ShowToastEvent({
                title: 'Error saving contact',
                message: error?.body?.message || 'Check the data and try again.',
                variant: 'error'
            })
        );
        return { success: false };
    }
}

export function extractContactIdByType(data, contactType) {
    if (!data || !Array.isArray(data)) return null;

    // 1. Ahora buscamos por el nuevo campo Type__c
    const record = data.find(r => r.Type__c === contactType);

    // 2. Y devolvemos directamente el Id del registro, no el ContactId__c
    return record ? record.Id : null;
}



// export function extractContactIdByType(data, contactType) {
//     if (!data ||!Array.isArray(data)) return null;
//     const rel = data.find(r => r.ONB_Contact_Type_State__c === contactType);
//     return rel ? rel.ContactId__c : null;
// }


export async function deleteExternalContact(cmp, contactId) {
    try {
        if (contactId) {
            await deleteRecord(contactId);
        }
        return true;
    } catch (error) {
        console.error('Error al borrar el contacto externo:', JSON.stringify(error));
        if (cmp && cmp.dispatchEvent) {
            cmp.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting contact',
                    message: error?.body?.message || 'Cannot delete record. Check permissions.',
                    variant: 'error'
                })
            );
        }
        return false;
    }
}