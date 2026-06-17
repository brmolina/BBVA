({
    executeAction : function(component, act, cllbck) {
        // Promise Execute action against the server
        return new Promise(function(resolve, reject) {
            act.setCallback(this,
                            function(response) {
                                var sts1 = response.getState();
                                if (sts1 === 'SUCCESS') {
                                    resolve(response.getReturnValue());
                                } else if (sts1 === 'ERROR') {
                                    var errors2 = response.getError();
                                    if (errors2) {
                                        if (errors2[0] && errors2[0].message) {
                                            reject(Error('Error msg: '
                                                         + errors2[0].message));
                                        }
                                    } else {
                                        reject(
                                            Error('Error')
                                        );
                                    }
                                }
                            });
            $A.enqueueAction(action);
        });
    },
    selectOperation : function(component, event, operation, url, http) {
        var codVisitOwner = component.get('v.owner');
        var codVisit = component.get('v.codVisit');
        var codBBVAParticipant = component.get('v.codBBVAParticipant');
        var visitMemberUser = component.get('v.visitMemberUser');
        if (operation === 'alta') {

            const vistyData = {
                codVisitManagementTeam : codBBVAParticipant,
                codManagementTeamUser : visitMemberUser
            };

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT")+ codVisit + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS");

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codVisitOwner);
            http.send(JSON.stringify(vistyData));

        } else if (operation === 'consulta') {

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codBBVAParticipant;
            http.open("GET", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codVisitOwner);
            http.send(null);

        } else if (operation === 'borrado') {

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codBBVAParticipant + "?_method=DELETE";

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codVisitOwner);
            http.send(null);
        }
    },
    fillComponent : function(component, http, operation) {
        if (operation === 'consulta') {
            if (http.responseText != null) {
                var response = JSON.parse(http.responseText);
                component.set('v.owner', response.opportunityMemberUser);
                component.set('v.codBBVAParticipant', response.codOppTeamMember);

            }
        }
    }
})