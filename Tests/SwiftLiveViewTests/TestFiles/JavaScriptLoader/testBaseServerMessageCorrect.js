class TestBaseServerMessage extends ServerMessageBase {
    updateNodeValue(message) {
        const element = document.getElementById(message.targetElement);
        element.innerText = message.value;
    }
}
