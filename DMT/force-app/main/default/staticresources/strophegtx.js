/**
 * File: strophe.openlink.js
 * A Strophe plugin for Openlink.
 * http://openlink.4ng.net:8080/openlink/xep-xxx-openlink_15-11.xml
 */
Strophe.addConnectionPlugin('gtx', {

    _connection: null,

    profiles: {},
    calls: {},
    callHandlers: {},

    init: function (connection) {
        this._connection = connection;
        console.log('loaded gtx strophe library');
    },

    statusChanged: function(status, condition) {
        var self = this;
        if (status == Strophe.Status.DISCONNECTED) {
            this._connection.removeHandler(this.callHandlerId);
        }
    },

    addHandler: function(system) {
        var self = this;
        this.callHandlerId = this._connection.addHandler(function(packet) {
            var callEv = self._parseCall(packet);
            if (callEv) {
                self._updateCalls(callEv);
            }
            return true;
        }, null, 'message', null, null, this.getGtxEventAddress(system));
    },

    /**
     * Call this on startup to notify the server that the app is ready to receive events.
     */
    sendPresence: function() {
        this._connection.send($pres());
    },

    /**
     * Returns the default pubsub address on the XMPP servers (tested on Openfire).
     * @returns {string} pubsub component address.
     */
    getGtxEventAddress: function(system) {
        return system + '.' + this._connection.domain;
    },

    /**
        * Implements GTX Make Call
    */
    makeCallGtx: function(to, system, extension, successCallback, errorCallback) {
        console.log("Make call to: " + extension);

        var mc_iq = $iq({
            to : to,
            type : "set"
        }).c("gtx-action", {
            xmlns : "http://gltd.net/protocol/gtx"
        }).c("plugin", {
            system : system
        }).up().c("action", {
            command : "makeCall",
            destination : extension
        });

        var self = this;
        var _successCallback = function(iq) {
            if (errorCallback && self._isError(iq)) {
                errorCallback(self._getErrorNote(iq));
                return;
            }

            var call = self._parseCall(packet);
            if (successCallback) {
                successCallback(call);
            }
        };

        var _errorCallback = function(iq) {
            if (errorCallback) {
                errorCallback('Error on make call');
            }
        };

        this._connection.sendIQ(mc_iq, _successCallback, _errorCallback);
    },

    /**
        * Implements GTX Asnwer Call
    */
    answerCallGtx: function(to, system, id, successCallback, errorCallback) {

        var mc_iq = $iq({
            to : to,
            type : "set"
        }).c("gtx-action", {
            xmlns : "http://gltd.net/protocol/gtx"
        }).c("plugin", {
            system : system
        }).up().c("action", {
            command : "answerCall",
            callnumber : id
        });

        var self = this;
        var _successCallback = function(iq) {
            if (errorCallback && self._isError(iq)) {
                errorCallback(self._getErrorNote(iq));
                return;
            }
            var call = self._parseCall(iq);
            if (successCallback) {
                successCallback(call);
            }
        }
        var _errorCallback = function(iq) {
            if (errorCallback) {
                errorCallback('Error on Answer call');
            }
        };

        this._connection.sendIQ(mc_iq, _successCallback, _errorCallback);
    },

    /**
        * Implements GTX Asnwer Call
    */
    holdCallGtx: function(to, system, id, successCallback, errorCallback) {

        var mc_iq = $iq({
            to : to,
            type : "set"
        }).c("gtx-action", {
            xmlns : "http://gltd.net/protocol/gtx"
        }).c("plugin", {
            system : system
        }).up().c("action", {
            command : "holdCall",
            callnumber : id
        });

        var self = this;
        var _successCallback = function(iq) {
            if (errorCallback && self._isError(iq)) {
                errorCallback(self._getErrorNote(iq));
                return;
            }
            var call = self._parseCall(iq);
            if (successCallback) {
                successCallback(call);
            }
        }
        var _errorCallback = function(iq) {
            if (errorCallback) {
                errorCallback('Error on Hold call');
            }
        };

        this._connection.sendIQ(mc_iq, _successCallback, _errorCallback);
    },

    /**
        * Implements GTX Asnwer Call
    */
    unholdCallGtx: function(to, system, id, successCallback, errorCallback) {

        var mc_iq = $iq({
            to : to,
            type : "set"
        }).c("gtx-action", {
            xmlns : "http://gltd.net/protocol/gtx"
        }).c("plugin", {
            system : system
        }).up().c("action", {
            command : "unholdCall",
            callnumber : id
        });

        var self = this;
        var _successCallback = function(iq) {
            if (errorCallback && self._isError(iq)) {
                errorCallback(self._getErrorNote(iq));
                return;
            }
            var call = self._parseCall(iq);
            if (successCallback) {
                successCallback(call);
            }
        }
        var _errorCallback = function(iq) {
            if (errorCallback) {
                errorCallback('Error on Un-Hold call');
            }
        };

        this._connection.sendIQ(mc_iq, _successCallback, _errorCallback);
    },

    /**
        * Implements GTX Drop Call
    */
    clearCallGtx: function(to, system, id, extension, successCallback, errorCallback) {
        console.log("Make call to: " + extension);

        var mc_iq = $iq({
            to : to,
            type : "set"
        }).c("gtx-action", {
            xmlns : "http://gltd.net/protocol/gtx"
        }).c("plugin", {
            system : system
        }).up().c("action", {
            command : "dropCall",
            callnumber : id
        });

        var self = this;
        var _successCallback = function(iq) {
            if (errorCallback && self._isError(iq)) {
                errorCallback(self._getErrorNote(iq));
                return;
            }
            var call = self._parseCall(iq);
            if (successCallback) {
                successCallback(call);
            }
        }
        var _errorCallback = function(iq) {
            if (errorCallback) {
                errorCallback('Error on Clear call');
            }
        };

        this._connection.sendIQ(mc_iq, _successCallback, _errorCallback);
    },

    _updateCalls: function(callEv) {
        console.log("CALLS UPDATED");
        if (callEv) {
            var id = callEv.id;
            if (id) {
                this.calls[id] = callEv;
                var changed = callEv.changed;

                // notify call handlers here
                for (var handler in this.callHandlers) {
                    this.callHandlers[handler](callEv, changed);
                }

                if (callEv.callState === 'IDLE') {
                    delete this.calls[id];
                }
            }
        }
    },

    _getUid: function s4() {
        return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16)
            .substring(1);
    },

    /**
     * Adds a call handler which is notified on any call event with the parameters: Call Event and Changed Element.
     * @param handler
     * @returns {*} the id associated with the handler. Retain this in order to remove the handler.
     */
    addCallHandler: function(handler) {
        var id = this._getUid();
        this.callHandlers[id] = handler;
        return id;
    },

    /**
     * Removes the call handler.
     * @param id the call handler id.
     * @returns {boolean}
     */
    removeHandler: function(id) {
        return delete this.callHandlers[id];
    },

    /* Parser Helpers */
    _parseProfile: function(profile) {
        var data = {};
        data.actions = [];
        if (profile) {
            var a = profile.attributes;
            if (a) {
                if (a.id && a.device) {
                    for (var _i = 0, _len = a.length; _i < _len; _i++) {
                        data[a[_i].name] = a[_i].value;
                    }
                    var query = profile.getElementsByTagName('action');
                    for (var _j = 0, _len1 = query.length; _j < _len1; _j++) {
                        var action = this._parseAttributes(query[_j]);
                        data.actions.push(action);
                    }
                }
            }
        }
        return data;
    },

    _parseAttributes: function(elem) {
        var data = {};
        if (elem) {
            var a = elem.attributes;
            if (a) {
                for (var _i = 0, _len = a.length; _i < _len; _i++) {
                    data[a[_i].name] = a[_i].value;
                }
            }
        }
        return data;
    },

    _flattenElementAndText: function(elem) {
        var data = {};
        if (elem) {
            for (var _i = 0; _i < elem.childNodes.length; _i++) {
                data[elem.childNodes[_i].tagName] = elem.childNodes[_i].textContent;
            }
        }
        return data;
    },

    _parseCallActions: function(elem) {
        var data = [];
        if (elem) {
            for (var _i = 0; _i < elem.childNodes.length; _i++) {
                data.push(elem.childNodes[_i].tagName);
            }
        }
        return data;
    },

    _getElementText: function(name, elem) {
        var result;
        if (name && elem) {
            var foundElem = elem.getElementsByTagName(name)[0];
            if (foundElem) {
                result = foundElem.textContent;
            }
        }
        return result;
    },

    _parseCall: function(elem) {
        var call = null;
        if (elem) {
            var gtxEvent = elem.getElementsByTagName('gtx-event')[0];
            var gtxAction = elem.getElementsByTagName('gtx-action')[0];
            if (gtxEvent || gtxAction) {
                var callElem;
                if (gtxEvent) {
                    callElem = gtxEvent.getElementsByTagName('call')[0];
                } else if (gtxAction) {
                    callElem = gtxAction.getElementsByTagName('call')[0];
                }
                if (callElem) {
                    var id = this._getElementText('id', callElem);
                    var call = new GtxCall({id: id});

                    call.changed = this._getElementText('changed', callElem);
                    call.callerId = this._getElementText('callerId', callElem);
                    call.calledId = this._getElementText('calledId', callElem) || "";
                    call.callState = this._getElementText('callState', callElem);
                    call.callOrigin = this._getElementText('callOrigin', callElem);

                    call.line = this._getElementText('line', callElem);
                    call.callRef = this._getElementText('callRef', callElem);
                    call.system = this._getElementText('system', callElem);

                    call.actions = this._parseCallActions(callElem.getElementsByTagName('actions')[0]);
                }
            }
        }
        return call;
    },

    _getErrorNote: function(elem) {
        var errorNpte = '';
        if (elem) {
            var foundElem = elem.getElementsByTagName('note')[0];
            if (foundElem) {
                if (foundElem.attributes.type && foundElem.attributes.type.value == 'error') {
                    if (foundElem.textContent && foundElem.textContent.length > 0)
                        errorNote = foundElem.textContent;
                }
            }
        }
        return errorNote;
    },

    _isError: function(elem) {
        var error = false;
        if (elem) {
            var foundElem = elem.getElementsByTagName('note')[0];
            if (foundElem) {
                if (foundElem.attributes.type && foundElem.attributes.type.value == 'error') {
                    if (foundElem.textContent && foundElem.textContent.length > 0)
                        console.error(foundElem.textContent);
                        error = true;
                    }
                }
            }
            else if (elem.attribute.type == 'error') {
                error = true;
            }
        return error;
    }

});

function Profile(data) {
    this.actions = {};
    this.interests = {};
    for (var elem in data) {
        this[elem] = data[elem];
    }
}

Profile.prototype._addAction = function(data) {
    var action = new Action(data);
    this.actions[action.id] = action;
    return action;
};

Profile.prototype._addInterest = function(data) {
    var interest = new Interest(data);
    this.interests[interest.id] = interest;
    return interest;
};

function Action(data) {
    for (var elem in data) {
        this[elem] = data[elem];
    }
}

function Interest(data) {
    for (var elem in data) {
        this[elem] = data[elem];
    }
}

function Feature(data) {
    for (var elem in data) {
        this[elem] = data[elem];
    }
}

function GtxCall(data, actions) {
    this.id = data.id;
    this.changed = data.changed;
    this.callerId = data.callerId;
    this.calledId = data.calledId;
    this.callState = data.callState;
    this.callOrigin = data.callOrigin;
    this.line = data.line;
    this.actions = actions;
    this.callRef = data.callRef;
    this.system = data.system;
}

Call.prototype._update = function(data, caller, called, actions, participants, features) {
    this.profile = data.profile;
    this.interest = data.interest;
    this.changed = data.changed;
    this.state = data.state;
    this.direction = data.direction;
    this.duration = data.duration;
    this.caller = caller;
    this.called = called;
    this.actions = actions;
    this.participants = participants;
    this.features = features;
}