# Hello world!

Say hello to the world! Create your first interactive website hassle(JavaScript) free!

## Overview

This article showcases how you can use ``SwiftLiveView`` framework to create interactive server side renderend website as fast as possible. This article skips some information about configuration and component details. To further explore these parts of framework follow up with <doc:Configuration> or <doc:Component>. This demo project is available [here](https://github.com/usmansc/swiftliveview-demo?tab=readme-ov-file).

### Project setup

From termminal inside your desired directory create new Vapor project.

```
vapor new swiftliveview-demo -n
```

This will give us basic template for Vapor project. Open your `Package.swift` file and proceed to the next step.

#### SwiftPM

Include ``SwiftLiveView`` package in your `Package.swift`. Optionally as the source below shows you can choose to include templating language of your choice. Here we have both `Leaf` and `Tokamak`.

First to dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    .package(url: "https://github.com/TokamakUI/TokamakVapor.git", branch: "main"),
    .package(url: "https://github.com/usmansc/swiftliveview.git", branch: "main")
]
```

and then target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Leaf", package: "leaf"), 
        .product(name: "TokamakVapor", package: "TokamakVapor"),
        .product(name: "SwiftLiveView", package: "SwiftLiveView")
    ],
    swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
    ]
),
```

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

#### Routes

Having public and private keys in `PEM` format you can define your app routes.

One to provide `JWT` tokens and one to handle `webSocket` connections.

Your `routes.swift` file should look like this.

```swift
import Vapor
import SwiftLiveView

func routes(_ app: Application) throws {
    app.get("api", "issue-token") { req async throws -> String in
        try TokenGenerator.generateToken(app)
    }

    let handler: LiveViewHandler<ClientMessage> = app.liveViewHandler()
    app.webSocket("websocket", onUpgrade: handler.handleWebsocket)
}
```

#### Templates

Now lets create two templates.
One in `Tokamak` and one in `Leaf`.

Create new directory under `Sources/App` and name it `Views`. In it create `IvalidPath.swift` file. Under your `Package` create directory `Resources/Views` and `index.leaf` file.

`InvalidPath.swift` should look something like this and will be used to present users with warning, that they entered invalid path.

```swift
import TokamakVapor

/// Invalid path representation
struct InvalidPath: TokamakVapor.View {
    var body: some TokamakVapor.View {
        VStack {
            Text("Sorry, could not find this URL")
                .foregroundColor(.red)
            Text("Try again with different path...")
                .foregroundColor(.black)
        }
    }
}
```

`index.leaf` should look like this 

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Demo counter</title>
</head>
<body>
    <main>
        <h1>Counter is: <span id="counterLabel"></span><h1>
        <button live-action="increment" id="increment">+</button>
        <button live-action="decrement" id="decrement">-</button>
    </main>
</body>
</html>

```

in this file we create two button with `live-action` parameter and `id`. This `live-action` parameter name will be important in our `Component`

#### Component

Under `Sources/App/Controllers` create new file named `IndexComponent.swift`. This component/controller will handle request from `index.leaf` view.

Your file should look like this 

```swift
import Vapor
import SwiftLiveView
import Combine

class IndexComponent: LiveRoutableComponent {
    var app: Vapor.Application
    var path: String
    var webSocket: WebSocket?
    var counter = 0 {
        didSet {
            guard let webSocket else { return }
            self.sendUpdate(via: webSocket, content: BaseServerMessage(value: "\(counter)", action: .updateNodeValue(target: "counterLabel")))
        }
    }

    init(app: Vapor.Application, path: String, webSocket: WebSocket? = nil) {
        self.app = app
        self.path = path
        self.webSocket = webSocket
    }

    /// Helper method to render leaf template
    private func renderView(_ app: Application, template: String) async throws -> String {
        let view = try await app.view.render(template).get()
        let buff = view.data
        return String(buffer: buff)
    }

    /// Protocol required method to render base template for component
    func baseTemplate() async throws -> String {
        try await renderView(app, template: "index.leaf")
    }
    
    /// Protocol required method to handle incoming messages
    func receiveMessage<ClientMessageType: ClientMessageDecodable>(from ws: WebSocket, message: ClientMessageType) {
        // Typecast incoming message to our typealiased message from `configure.swift`
        guard let message = message as? ClientMessage else { return }
        switch message.action {
        case .live_action:
            guard let target = LiveActionCall(rawValue: message.value ?? "") else { return }
            switch target {
            case .increment:
                counter += 1
            case .decrement:
                counter -= 1
            }
            return
        default:
            return
        }
    }

    // Mapping for request ids from `index.leaf` template
    private enum LiveActionCall: String {
        case increment = "increment"
        case decrement = "decrement"
    }
}

// MARK: Extension with unused required methods
extension IndexComponent {
    typealias Context = Never
    func contextSnapshot() -> Context? { nil }
    func loadFromContext(_ context: Never) { return }
}
```

#### Configure

All we need to do now is to configure our app properly. Here I am serving private and public keys from `.env` file placed in root directory.
`configure.swift` file should look like this.

```swift
import Vapor
import TokamakVapor
import Leaf
import SwiftLiveView

// configures your application
public func configure(_ app: Application) async throws {
    app.views.use(.leaf)
    app.middleware.use(WebsocketInitializer())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let router = LiveRouter<String, ClientMessage> {
        // View that is rendered at invalid path request
        TokamakStaticHTML.StaticHTMLRenderer(InvalidPath()).render()
    } handleMessage: { router, request, message, socket in
        await router.passMessageToCurrentComponent(message, from: socket)
    }
    guard let privateKeySecret = Environment.get("PRIVATE")?.base64Decoded(),
          let publicKeySecret = Environment.get("PUBLIC")?.base64Decoded() else {
        fatalError("Could not read private or public key environment")
    }
    // register routes
    app.setLiveViewHandler(
        LiveViewHandler<ClientMessage>(
            configuration: LiveViewHandlerConfiguration<ClientMessage>(
                app: app,
                router: router,
                privateKeySecret: privateKeySecret,
                publicKeySecret: publicKeySecret,
                onCloseStrategy: .deleteConnection(after: 10)) {
                [
                    IndexComponent(app: app, path: "/")
                ]
            }
        )
    )
    try routes(app)
}

public enum Action: String, Decodable {
    case live_action = "live-action"
}

typealias ClientMessage = BaseClientMessage<Action>

extension String {
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

#### Serve and enjoy

If you run the app now, you should see counter with two buttons. If you enter invalid `URL` path, you will get our `InvalidPath.swift` view serverd.

Not part of this tutorial, but I can highly recommend [FlyIO](https://fly.io) for app deployment.
