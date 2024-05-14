class CommunicationHubInterface {
    listen(target, action) {};
}

class CommunicationHub extends CommunicationHubInterface {
    websocket;
    authToken;
    hubActions;

    /**
     *
     * @param {ListenerBase} listener
     * @param {EvaluatorBase} evaluator
     * @param {ServerMessageBase} serverMessage
     * @param {ClientMessageBase} clientMessage
     */
    constructor(listener, evaluator, serverMessage, clientMessage) {
        super();
        this.listener = listener;
        this.evaluator = evaluator;
        this.serverMessage = serverMessage;
        this.clientMessage = clientMessage;
        this.hubActions = {
            [CommunicationHubTarget.LISTENER]: this.listener.listen,
            [CommunicationHubTarget.EVALUATOR]: this.evaluator.listen,
            [CommunicationHubTarget.SERVERMESSAGE]: this.serverMessage.listen,
            [CommunicationHubTarget.CLIENTMESSAGE]: this.clientMessage.listen,
            [CommunicationHubTarget.MANAGER]: this.evaluateMessage.bind(this),
        };
        emitter.setHub(this);
        const fetch = new CommunicationHubTargetAction(new TargetType(ListenerBaseActions, ListenerBaseActions.FETCH));
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.LISTENER);
        emitter.emit(targetType, fetch);
    }

    listenerActions = {
        [CommunicationHubInterfaceActions.SEND]: this.sendMessage.bind(this),
        [CommunicationHubInterfaceActions.SETWEBSOCKET]: this.setWebsocketAndToken.bind(this)
    };

    setWebsocketAndToken(metadata) {
        this.websocket = metadata.socket;
        this.token = metadata.token;
    }

    sendMessage(metadata) {
        if (this.websocket !== undefined) {
            this.websocket.send(metadata.object);
        }
    }

    /**
     * Handle a message by forwarding it to the appropriate class based on the target
     * @param {string} target - A target class indentifier
     * @param  {CommunicationHubTargetAction} action - An action object
     */
    listen(target, action) {
        this.hubActions[target](action);
    }

    /**
     *
     * @param {CommunicationHubTargetAction} action
     */
    evaluateMessage(action) {
        this.listenerActions[action.action.value](action.metadata);
    }
}
