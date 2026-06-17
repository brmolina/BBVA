({
    executeAction : function(component, act, cllbck) {
        // Promise Execute action against the server
        return new Promise(function(resolve, reject) {
            act.setCallback(this,
                            function(response) {
                                var sts = response.getState();
                                if (sts === 'SUCCESS') {
                                    resolve(response.getReturnValue());
                                } else if (sts === 'ERROR') {
                                    var errors1 = response.getError();
                                    if (errors1) {
                                        if (errors1[0] && errors1[0].message) {
                                            reject(Error('Error msg: '
                                                         + errors1[0].message));
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
    selectOperation : function(component, operation, url, http) {
        var codOppOwner = component.get('v.owner');
        var codOpportunity = component.get('v.codOpportunity');
        var codTeamMember = component.get('v.codTeamMember');
        var opportunityMemberUser = component.get('v.opportunityMemberUser');
        if (operation === 'alta') {

            const optyData = {
                codOppTeamMember : codTeamMember,
                opportunityMemberUser : opportunityMemberUser
            };

            url = url + $A.get("$Label.c.DES_IP_URL_OPP")+ codOpportunity + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS");

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codOppOwner);
            http.send(JSON.stringify(optyData));

        } else if (operation === 'consulta') {

            url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codTeamMember;
            http.open("GET", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codOppOwner);
            http.send(null);

        } else if (operation === 'borrado') {

            url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codTeamMember + "?_method=DELETE";

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  codOppOwner);
            http.send(null);
        }
    },
    fillComponent : function(component, http, operation) {
        if (operation === 'consulta') {
            if (http.responseText != null) {
                var response = JSON.parse(http.responseText);
                component.set('v.owner', response.opportunityMemberUser);
                component.set('v.codTeamMember', response.codOppTeamMember);

            }
        }
    }
})