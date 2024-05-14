# Component

Representation of route state.

## Overview

Component is representation of route state. It receives events, updates its state and renders updates for pages. 
Each connection has it's own components associated with it. Their state is isolated and is exclusive to specific component.
Components have to conform to ``LiveRoutableComponent`` protocol.

> Tip: If you want to share state between components you can use `Combine` framework.

### Protocol methods that are worth modifying.

- ``LiveRoutableComponent/baseTemplate()`` - returns base template of component. 
- ``LiveRoutableComponent/cleanUp(for:)`` - method used to clean up after component. It is called by ``LiveRouter`` on route change. It can be used to clean any shared state in the app. For example allowing only certain number of users on page.
- ``LiveRoutableComponent/contextSnapshot()`` - provides snapshot of context. Context in this meaning are any data that we might want to save and are important. Thanks to this method we can save current component context in case of connection inactivity. We can also regularly backup data of component via ``WebSocketCloseStrategy``.
- ``LiveRoutableComponent/loadFromContext(_:)`` - load previously retrived context.
- ``LiveRoutableComponent/receiveMessage(from:message:)`` - entry point method for every component. 
- ``LiveRoutableComponent/setQueryParameters(_:for:)`` - sets query parameters for component. It is called by ``LiveRouter`` and passes `URL` parameters to component, allowing to set up component according to query parameters.
