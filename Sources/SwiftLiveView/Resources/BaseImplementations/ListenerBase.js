class ListenerBase extends ListeningInterface {
    #websocket;
    #authToken;
    #authTokenAPIEndpoint;
    #webSocketEndPoint;

    /**
     *
     * @param {string} authTokenAPIEndpoint
     * @param {string} webSocketEndPoint - i.e /websocket . Should start with /
     */
    constructor(authTokenAPIEndpoint, webSocketEndPoint) {
        super();
        this.#authTokenAPIEndpoint = authTokenAPIEndpoint;
        this.#webSocketEndPoint = webSocketEndPoint;
    }

    estabilishConnection = (authToken) => {
        var wsProtocol = window.location.protocol === "https:" ? "wss://" : "ws://";
        var wsHost = window.location.host;
        var wsPath = this.#webSocketEndPoint + "?authToken=" + authToken + "&initialURL=" + window.location.pathname + window.location.search;
        var wsUrl = wsProtocol + wsHost + wsPath;

        this.#websocket = new WebSocket(wsUrl);
        this.#websocket.onopen = () => {
            this.#websocket.onmessage = (event) => {
                this.getWebsocketAndToken();
                this.getAuthToken();
                const targetOfAction = new TargetType(EvaluatorBaseActions, EvaluatorBaseActions.ONMESSAGE);
                const act = new CommunicationHubTargetAction(targetOfAction, event);
                const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.EVALUATOR);
                emitter.emit(targetType, act);
            }
        }
    }

    /**
     *
     * @param {CommunicationHubTargetAction} action
     */
    listen = (action) => {
        if (action.action.value === ListenerBaseActions.FETCH) {
            this.fetchAuthToken(this.#authTokenAPIEndpoint);
        }
    }

    getWebsocketAndToken() {
        const targetOfAction = new TargetType(CommunicationHubInterfaceActions, CommunicationHubInterfaceActions.SETWEBSOCKET);
        const action = new CommunicationHubTargetAction(targetOfAction, {socket: this.#websocket, token: this.#authToken});
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.MANAGER);
        emitter.emit(targetType, action);
    }

    getAuthToken() {
        const targetOfAction = new TargetType(ClientMessageBaseActions, ClientMessageBaseActions.TOKEN );
        const action = new CommunicationHubTargetAction(targetOfAction, {token: this.#authToken});
        const targetType = new TargetType(CommunicationHubTarget, CommunicationHubTarget.CLIENTMESSAGE);
        emitter.emit(targetType, action);
    }

    async fetchAuthToken(endpoint) {
        this.#authToken = sessionStorage.getItem("authToken")
        if (!this.#authToken) {
            const response = await fetch(endpoint);
            if (!response.ok) {
                console.error('Failed to obtain the JWT token.');
                return;
            }
            this.#authToken = await response.text();
            sessionStorage.setItem('authToken', this.#authToken);
        }
        this.estabilishConnection(this.#authToken);
    }
}
