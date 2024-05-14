class EvaluatorBase extends ListeningInterface {
    register(key, action) {
        this.actions[key] = action.bind(this);
    }

    actions = {
        [EvaluatorBaseActions.ONMESSAGE]: this.parse.bind(this),
    }

    /**
     *
     * @param {CommunicationHubTargetAction} action
     */
    listen = (action) => {
        this.actions[action.action.value](action);
    }

    /**
     * Parse the message you get back
     * Should be defined by user
     * To properly parse the message het sents
     * from the server
     * @param {CommunicationHubTargetAction} action
     */
    parse(action) {
        const message = JSON.parse(action.metadata.data);
        if (message) {
            this.evaluate(message);
        }
    }

    /**
     * Evaluate parsed message
     * Should be defined by user
     * To properly evaluate the message
     * That was sent from server based on his ServerMessage structure
     * @param {*} message
     * @returns
     */
    evaluate(message) {
        if (!message) {
            return;
        }

        // In this case it is switched upon when deciding what method will handle this message in target class
        // You can also send down the whole unparsed message and parse the actual data in listen method of target class
        // This way you can directly get values you need and operate strictly over the structure you need
        const action = Object.keys(message.action)[0];
        if (!action) {
            return;
        }

        // In this case we are sending the whole message down
        // The actual value parsing is performed in the target class
        const targetOfAction = new TargetType(ServerMessageBaseActions, action);
        const msg = new CommunicationHubTargetAction(targetOfAction, message);
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.SERVERMESSAGE);
        emitter.emit(targetType, msg);
    }
}
