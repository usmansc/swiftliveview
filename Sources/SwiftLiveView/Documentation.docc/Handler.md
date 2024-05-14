# Handler

``LiveViewHandler`` is heart of every ``SwiftLiveView`` framework.

## Overview

`Actor` which acts as main entry point of any application using ``SwiftLiveView`` framework.
Manges `WebSocket` connections and forwards communication to connection specific ``LiveRouter`` and subsequently ``LiveRoutableComponent``s

### Essentials

``LiveViewHandler`` exposes following properties and methods. 

- ``LiveViewHandler/routerConnection`` - which holds dictionary of connections in `JWTString`: `ConnectionLiveRouter`
- ``LiveViewHandler/connections()`` - provides all `WebSocket` connections with the server
- ``LiveViewHandler/handleWebsocket(_:_:)`` - `WebSocket` request handler
