class ClientMessageBase extends ListeningInterface {
    authToken;
    #preventDefaultAction;

    listeners = [
        new ClientMessageAction('[' + ClientMessageActions.LIVE_HREF + ']',ClientMessageActions.LIVE_HREF,ClientMessageActions.LIVE_HREF, this.attachLiveHrefClickListener.bind(this), "click"),
        new ClientMessageAction('[' + ClientMessageActions.LIVE_LOAD + ']',ClientMessageActions.LIVE_LOAD,ClientMessageActions.LIVE_LOAD, this.attachLiveLoad.bind(this)),
        new ClientMessageAction('[' + ClientMessageActions.LIVE_ACTION + ']',ClientMessageActions.LIVE_ACTION,ClientMessageActions.LIVE_ACTION, this.attachLiveActionClickListener.bind(this), "click"),
        new ClientMessageAction("input",ClientMessageActions.LIVE_INPUT ,ClientMessageActions.LIVE_INPUT, this.attachInputListener.bind(this), "input")
    ]

    /**
     *
     * @param {boolean} preventDefault - if the default actions should be prevented, i.e if href listener, we do not want to redirect
     */
    constructor(preventDefault) {
        super();
        this.#preventDefaultAction = preventDefault;
        this.attachWindowListener();
    }

    attachWindowListener() {
        window.addEventListener('popstate', (event) => {
            // The popstate event is fired each time when the current history entry changes.
            let pathAfterDomain = window.location.pathname + window.location.search;

            // Add a forward slash '/' at the beginning of the path if it's missing
            if (!pathAfterDomain.startsWith('/')) {
              pathAfterDomain = '/' + pathAfterDomain;
            }
            const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SEND);
            const act = new CommunicationHubTargetAction(targetOfAction, {object: this.encode("", ClientMessageActions.LIVE_HREF, pathAfterDomain, this.authToken)});
            const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
            emitter.emit(targetType, act);
        }, false);
    }

    /**
     *
     * @param {CommunicationHubTargetAction} action
     */
    listen = (action) => {
        if (action.action.value === ClientMessageBaseActions.TOKEN) {
            this.setAuthToken(action.metadata.token);
        } else if (action.action.value === ClientMessageBaseActions.ATTACHLISTENERS) {
            this.listenForClientEventsOn(action.onObject);
        }
    }

    listenForClientEventsOn(object) {
        this.listeners.forEach(function(func) {
            func.onListen(this, func, object);
        }.bind(this));
    }

    /**
     *
     * @param {string} selector
     * @param {(element, elementID: string) => {}} callback
     */
    apllyCallbackToElements = (object, selector, callback) => {
        const privateSelector = selector;
        object.querySelectorAll(privateSelector).forEach((element) => {
            let elementID = element.getAttribute('id');
            if (elementID === undefined) {
                elementID = "";
            }
            callback(element, elementID);
        });
    }

    setAuthToken(token) {
        this.authToken = token;
    }

    register(listener) {
        this.listeners.push(listener);
    }

    /**
     * Meant to be implemented by user based on the
     * users expected client message
     * @param {String} elementID
     * @param {String} action
     * @param {String} value
     * @param {String} authToken
     * @param {*} metadata
     * @returns
     */
    encode(elementID, action, value, authToken, metadata) {
        return JSON.stringify(new MessageObject(elementID, action, value, authToken, metadata));
    }

    /**
     *
     * @param {ClientMessageAction} action
     * @param {HTMLElement} object
     */
    attachLiveHrefClickListener(context, action, object) {
        this.apllyCallbackToElements(object, action.selector, (element, elementID) => {
            element.addEventListener(action.event, (originalEvent) => {
                if (this.#preventDefaultAction === true) {
                    originalEvent.preventDefault()
                }
                const value = element.getAttribute(action.getValueBySelector);
                if (value) {
                    const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SEND);
                    const act = new CommunicationHubTargetAction(targetOfAction, {object: this.encode(elementID, action.action, value, this.authToken)});
                    const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
                    emitter.emit(targetType, act);
                    const url = window.location.protocol + '//' + window.location.host + value
                    history.pushState({}, "", url);
                }
            });
        });
    }

    /**
     *
     * @param {ClientMessageAction} action
     * @param {HTMLElement} object
     */
    attachLiveLoad(context, action, object) {
        this.apllyCallbackToElements(object, action.selector, (_element, elementID) => {
            const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SEND);
            const act = new CommunicationHubTargetAction(targetOfAction, {object: this.encode(elementID, action.action, "", this.authToken)});
            const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
            emitter.emit(targetType, act);
        });
      }

    /**
     *
     * @param {ClientMessageAction} action
     * @param {HTMLElement} object
     */
    attachLiveActionClickListener(context, action, object) {
        this.apllyCallbackToElements(object, action.selector, (element, elementID) => {
            element.addEventListener(action.event, (originalEvent) => {
                if (this.#preventDefaultAction === true) {
                    originalEvent.preventDefault()
                }
                const value = element.getAttribute(action.getValueBySelector)
                if (elementID) {
                    const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SEND);
                    const act = new CommunicationHubTargetAction(targetOfAction, {object: this.encode(elementID, action.action, value, this.authToken)});
                    const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
                    emitter.emit(targetType, act);
                }
            });
        });
    }

    /**
     *
     * @param {ClientMessageAction} action
     * @param {HTMLElement} object
     */
    attachInputListener(context, action, object) {
        this.apllyCallbackToElements(object, action.selector, (element, elementID) => {
            element.addEventListener(action.event, (event) => {
                if (this.#preventDefaultAction === true) {
                    event.preventDefault()
                }
                const value = event.target.value;
                const type = event.target.type;
                const name = event.target.name;
                let metadata = {
                    "type": type,
                    "name": name,
                }
                if (value.length > 0) {
                    const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SEND);
                    const act = new CommunicationHubTargetAction(targetOfAction, {object: this.encode(elementID, action.action, value, this.authToken, metadata)});
                    const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
                    emitter.emit(targetType, act);
                }
            })
        })
    }
}
