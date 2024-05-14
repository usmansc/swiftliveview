# Configuration

Possible additional configuration optios for your ``SwiftLiveView`` app.

## Overview

``SwiftLiveView`` can be configured to match your needs. There are several configuartion options taht you can use right away, or you can experiment and create your own configuration. This article showcases mandatory configuartion steps and explains options for custom configuration. Mandatory steps are also shown in <doc:GettingStarted> article.

### Mandatory steps

``SwiftLiveView`` uses `JWT` tokens in its communication process with client. It is required to generate private and public keys befored deployment.

#### Private and public keys

Both key pairs has to be supplied to the ``LiveViewHandler`` as `String`s. You can follow [this](https://kentakodashima.medium.com/generate-pem-keys-with-openssl-on-macos-ecac55791373) article to generate get `PEM` formatted keys. Signer is expecting them to be in `rs256` format.

As general rule of thumb you can use following command to export your public key to `PEM` format. Following code was taken from [this](https://serverfault.com/a/706412) post.

```
ssh-keygen -f id_rsa.pub -m 'PEM' -e > id_rsa.pub.pem
```
Then simply copy the .pem key as necessary.

Options as follows: (See man ssh-keygen)

-f id_rsa.pub: input file
-m 'PEM': output format PEM
-e: output to STDOUT

Consider providing your app with keys using ``Environment``

#### Client and server messages

``SwiftLiveView`` provides you with base templates which you can use for structuring client and server messages between client and server. These are ``BaseClientMessage`` and ``BaseServerMessage``. ``BaseClientMessage`` further takes generic paramter which dictates structure of action parameter of ``BaseClientMessage``. 

Define your `Action` structure and typealias it in your app as follows. Now you can use these in your app. 
```swift
public enum Action: String, Decodable {
    case live_href = "live-href"
}

typealias ClientMessage = BaseClientMessage<Action>
```

#### In configure method

You start configuration in your app's `configure()` method. 

First you need to use ``WebSocketInitializer`` middleware, that provides response with minimal JavaScript code that is needed to respond to server messages.

Then we need to create and set ``LiveViewHandler`` handler.

To do this you need to create configuration using ``LiveViewHandlerConfiguration`` which further accepts ``LiveRouter`` as router and ``WebSocketCloseStrategy``.

your router definition may look something like this: 

```swift
let router = LiveRouter<String, ClientMessage> {
    // View that is rendered at invalid path request
    TokamakStaticHTML.StaticHTMLRenderer(InvalidPath()).render()
} handleMessage: { router, request, message, socket in
    // to change router url we have to decide based on the action 
    // because it might be defined by user it needs to be handled outside 
    // of the actual router
    if message.action == .live_href {
        try? router.changeURL(request, socket, to: message.value ?? "/", for: message.authToken)
    } else {
        // all other messages should be passed to current component
        await router.passMessageToCurrentComponent(message, from: socket)
    }
}
```

```swift
app.setLiveViewHandler(
    LiveViewHandler<ClientMessage>(
        configuration: LiveViewHandlerConfiguration<ClientMessage>(
            app: app,
            router: router,
            privateKeySecret: privateKeySecret,
            publicKeySecret: publicKeySecret,
            onCloseStrategy: .moveToSwap(after: 10, completion: { message, object in
                // After 10 seconds we will just get snapshot
                // furthermore we can save it to database or something
                guard let _ = message as? ClientMessage,
                      let object = object as? LiveIndex else { return }
                let _ = object.contextSnapshot()
            })
        ) {
            [
                LiveIndex(path: "/",
                          app: app),
                LiveDetail(path: "/detail",
                           app: app)
            ]
        }
    )
)
```

``WebSocketCloseStrategy`` provides you with option to manipulate connection data after certain amount of inactivity. In this example we access active component context.

#### Routes

Configuration of routes is important for proper functionality of ``SwiftLiveView``

Your app needs to issue `JWT` token for client. It is requested automatically by client side code for path `app/issue-token`. It uses ``TokenGenerator`` to issue the token

```swift
app.get("api", "issue-token") { req async throws -> String in
    try TokenGenerator.generateToken(app)
}
```

After issuing the token, client tries to open `WebSocket` connection. To handle incoming `WebSocket` request you need to register handler method as follows:

```swift
let handler: LiveViewHandler<ClientMessage> = app.liveViewHandler()
app.webSocket("websocket", onUpgrade: handler.handleWebsocket)
```

### Custom configuration

#### Registration of new JavaScript methods

When using ``WebSocketInitializer`` we can initialize it with custom ``JavaScriptLoader`` instance. 
``JavaScriptLoader`` can register new handling methods directly on the user end. Contets of registering method may look something like this:

```js
let method = (context, action, object) => {
    context.apllyCallbackToElements(object, action.selector, (element, elementID) => {
        element.addEventListener("mouseover", (event) => {
          // Send message to server/Handle mousover event
        });
    });
}
```

and its registration 

```swift
loader.registerClientMessageAction(liveSelector: "live-onover", withContents: method)
```

In similar fashion you can register new methods to handle server messages. Please refer to ``JavaScriptLoader`` to see all methods that can be utilized for customization of loader.
