class ServerMessageBase extends ListeningInterface {
    /**
     *
     * @param {CommunicationHubTargetAction} action
     */
    listen = (action) => {
        const parsedValue = this.parseValueToActionAndMetadata(action);
        this.applyAction(parsedValue.action, parsedValue.object);
    }

    /**
     * Provides parsed message to target method
     * User should implement this method based on the server message
     * that he sents back from browser
     * @param {*} action
     */
    parseValueToActionAndMetadata(action){
        let value = action.action.value;
        switch(value) {
            case ServerMessageBaseActions.REPLACE_BODY:
                return {
                    action: ServerMessageBaseActions.REPLACE_BODY,
                    object: {nodeValue: action.metadata.action.replaceBody.with}
                };
            case ServerMessageBaseActions.APPEND_NODE:
                return {
                    action: ServerMessageBaseActions.APPEND_NODE,
                    object: {targetElement: action.metadata.action.appendNode.target, value: action.metadata.value}
                };
            case ServerMessageBaseActions.INSERT_NODE:
                return {
                    action: ServerMessageBaseActions.INSERT_NODE,
                    object: {targetElement: action.metadata.action.insertNode.target, value: action.metadata.value}
                };
            case ServerMessageBaseActions.UPDATE_NODE_VALUE:
                return {
                    action: ServerMessageBaseActions.UPDATE_NODE_VALUE,
                    object: {targetElement: action.metadata.action.updateNodeValue.target, value: action.metadata.value}
                };
            case ServerMessageBaseActions.SET_INPUT:
                return {
                    action: ServerMessageBaseActions.SET_INPUT,
                    object: {targetElement: action.metadata.action.setInput.target, value: action.metadata.value}
                };
            case ServerMessageBaseActions.REMOVE_ATTRIBUTE:
                return {
                    action: ServerMessageBaseActions.REMOVE_ATTRIBUTE,
                    object: {targetElement: action.metadata.action.removeAttribute.target, attributes: action.metadata.action.removeAttribute.attributes}
                };
            case ServerMessageBaseActions.ADD_ATTRIBUTE:
                return {
                    action: ServerMessageBaseActions.ADD_ATTRIBUTE,
                    object: {targetElement: action.metadata.action.addAttribute.target, attributes: action.metadata.action.addAttribute.attributes}
                };
            case ServerMessageBaseActions.UPDATE_ATTRIBUTE:
                return {
                    action: ServerMessageBaseActions.UPDATE_ATTRIBUTE,
                    object: {targetElement: action.metadata.action.addAttribute.target, attributes: action.metadata.action.addAttribute.attributes}
                };
            case ServerMessageBaseActions.ADD_STYLE_TO:
                return {
                    action: ServerMessageBaseActions.ADD_STYLE_TO,
                    object: {targetElement: action.metadata.action.addStyleTo.target, style: action.metadata.value}
                };
            case ServerMessageBaseActions.REMOVE:
                return {
                    action: ServerMessageBaseActions.REMOVE,
                    object: {targetElement: action.metadata.action.remove.selector}
                };
            case ServerMessageBaseActions.REMOVE_STYLE:
                return {
                    action: ServerMessageBaseActions.REMOVE_STYLE,
                    object: {targetElement: action.metadata.action.removeStyle.target}
                };
        }
    }

    /**
     * Updated value of node based on the message object
     * @param {{targetElement: String, value: String}} message
     */
    updateNodeValue(message) {
        const element = document.getElementById(message.targetElement);
        if (element) {
            element.innerText = message.value;
        }
    }

    /**
     * Add attribute to element based on the message object
     * @param {{targetElement: String, attributes: {name: String, value: String}}} message
     */
    addAttribute(message) {
        const element = document.getElementById(message.targetElement);
        const attributes = message.attributes;

        attributes.forEach((attribute) => {
            const attributeName = attribute.name;
            const attributeValue = attribute.value;
            element.setAttribute(attributeName, attributeValue);
          })
    }

    /**
     * Remove attribute from element based on the message object
     * @param {{targetElement: String, attributesName: [{name:String, value: String}]}} message
     */
    removeAttribute(message) {
        const element = document.getElementById(message.targetElement);
        const attributes = message.attributes;

        attributes.forEach((attribute) => {
            element.removeAttribute(attribute.name);
        })
    }

    /**
     * Insert node to target element based on the message object
     * This method replaces the whole node content
     * @param {{targetElement: String, value: String}} message
     */
    insertNode(message) {
        const element = document.getElementById(message.targetElement);
        element.innerHTML = message.value;
        const targetOfAction = new TargetType(ClientMessageBaseActions, ClientMessageBaseActions.ATTACHLISTENERS);
        const action = new CommunicationHubTargetAction(targetOfAction, element);
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.CLIENTMESSAGE);
        emitter.emit(targetType, action);
    }

    /**
     * Sets input value based ond the message object
     * @param {{targetElement: String, value: String}} message
     */
    setInput(message) {
        const element = document.getElementById(message.targetElement);
        if (element != null && element.tagName === 'INPUT') {
            element.value = message.value;
        }
    }

    /**
     * Appends node to target element based on the message object
     * @param {{targetElement: String, value: String}} message
     */
    appendNode(message) {
        const tempContainer = document.createElement('div');
        tempContainer.innerHTML = message.value;
        const targetContainer = document.getElementById(message.targetElement);
        const targetOfAction = new TargetType(ClientMessageBaseActions, ClientMessageBaseActions.ATTACHLISTENERS);
        const action = new CommunicationHubTargetAction(targetOfAction, tempContainer);
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.CLIENTMESSAGE);
        emitter.emit(targetType, action);
        while (tempContainer.firstChild) {
            targetContainer.appendChild(tempContainer.firstChild);
        }
    }

    /**
     * Replace the body contents based on the message object
     * @param {{nodeValue: String}} message
     */
    replaceBody(message) {
        document.body.innerHTML = message.nodeValue;
        const targetOfAction = new TargetType(ClientMessageBaseActions, ClientMessageBaseActions.ATTACHLISTENERS);
        const action = new CommunicationHubTargetAction(targetOfAction, document.body);
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.CLIENTMESSAGE);
        emitter.emit(targetType, action);
    }

    /**
     * Removes node from document based on the message object
     * @param {targetElement: String} message
     */
    remove(message) {
        let element = document.getElementById(message.targetElement);
        element.remove();
    }

    /**
     * Adds style to element based on the message object
     * Style should be parsable CSS-json string
     * @param {targetElement: String, style: String}
     */
    addStyleTo(message) {
        const target = message.targetElement;
        let element = document.getElementById(target);
        let newStyle = JSON.parse(message.style)
        for (let key in newStyle) {
            if (newStyle.hasOwnProperty(key)) {
                element.style[key] = newStyle[key];
            }
        }
    }

    /**
     * Removes style from element based on the message object
     * This method removes all styles
     * @param {{targetElement: String} message
     */
    removeStyle(message) {
        const target = message.targetElement;
        let element = document.getElementById(target);
        element.style.cssText = '';
    }

    register(key, action) {
        this.actions[key] = action;
    }

    actions = {
        [ServerMessageBaseActions.INSERT_NODE] : this.insertNode,
        [ServerMessageBaseActions.ADD_ATTRIBUTE] : this.addAttribute,
        [ServerMessageBaseActions.UPDATE_ATTRIBUTE] : this.addAttribute,
        [ServerMessageBaseActions.REMOVE_ATTRIBUTE]: this.removeAttribute,
        [ServerMessageBaseActions.UPDATE_NODE_VALUE] : this.updateNodeValue,
        [ServerMessageBaseActions.SET_INPUT] : this.setInput,
        [ServerMessageBaseActions.APPEND_NODE] : this.appendNode,
        [ServerMessageBaseActions.REPLACE_BODY] : this.replaceBody,
        [ServerMessageBaseActions.REMOVE] : this.remove,
        [ServerMessageBaseActions.ADD_STYLE_TO]: this.addStyleTo,
        [ServerMessageBaseActions.REMOVE_STYLE]: this.removeStyle
    };

    applyAction(action, message) {
        this.actions[action](message);
    }
}
