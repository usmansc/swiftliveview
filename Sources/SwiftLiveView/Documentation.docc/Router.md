# Router

Routing heart of every ``SwiftLiveView`` app.

## Overview

``LiveRouter`` manages routing for specific connection. Manages specific ``LiveRoutableComponent`` components and forwards messages to them.

### Essentials

``LiveRouter`` exposes 2 methods for handling incoming requests. These are:

- ``LiveRouter/changeURL(_:_:to:for:)`` - changes url based on request
- ``LiveRouter/passMessageToCurrentComponent(_:from:)`` - passes message to currently active component

Both of these methods are exposed only because ``SwiftLiveView`` allows users to define their own structures for client and server messages.
Based on the contents of the message user has to decide whether to call ``LiveRouter/changeURL(_:_:to:for:)`` or ``LiveRouter/passMessageToCurrentComponent(_:from:)``.

