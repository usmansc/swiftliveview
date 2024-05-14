/**
* Validates if the passed target is valid enum option
* @param {TargetType} target - wrapped enumeration
* @param {any} subclassOf class to check against TargetType.targetClass, leave blank if you wish to skip this check
*/
function validateEnumeration(target, subclassOf = null) {
    if (subclassOf !== null && typeof subclassOf !== 'function') {
        throw new Error("The passed `subclassOf` argument in not a class");
    }
    if (target instanceof TargetType) {
        if (subclassOf === null || target.targetClass === subclassOf || TargetType.isSubclassOf(target.targetClass, subclassOf)) {
            if (target.targetClass.isValidOption(target.value)) {
                return true;
            }
            throw new Error("Passed enum option is not part of the target class or any of its parents.");
        }
        throw new Error("TargetType target class does not correctly subclass", + subclassOf.name);
    }
    throw new Error("Passed target is not instance of `TargetType`");
}

/**
 * Represents wrapped enum to enforce validation
 * Also its static methods are used to ensure
 * proper subclassing and implemetation of interface
 */
class TargetType {
    /**
     *
     * @param {EnumBase} targetClass - The class reference for the target type
     * @param {any} value - The value associated with the target class
     */
    constructor(targetClass, value) {
        if (!targetClass || !value) {
            throw new Error('TargetClass and value are required');
        }
        this.targetClass = targetClass;
        this.value = value;
    }

    static isSubclassOf(childClass, parentClass) {
        return childClass.prototype instanceof parentClass;
    }

    static validateInstanceAgainstInterface(instance, classInterface) {
        const interfaceProperties = Object.getOwnPropertyNames(classInterface.prototype);

        for (const prop of interfaceProperties) {
            if (prop === 'constructor') continue;

            let currentProto = instance;
            let hasMethod = false;

            while (currentProto !== null && !hasMethod) {
                hasMethod = typeof currentProto[prop] === 'function';
                currentProto = Object.getPrototypeOf(currentProto);
            }

            if (!hasMethod) {
                return false;
            }
        }
        return true;
    }
}

/**
 *  Extend this class if you want to create
 *  enumeration
 */
class EnumBase {
    static _cases = null;

    static getCases() {
        if (this._cases === null) {
            let currentClass = this;
            const properties = new Set();

            while (currentClass !== Function.prototype) {
                Object.getOwnPropertyNames(currentClass)
                .filter(prop => typeof currentClass[prop] === 'string')
                .forEach(prop => properties.add(currentClass[prop]));

                currentClass = Object.getPrototypeOf(currentClass);
            }
            this._cases = properties;
        }
        return this._cases;
    }

    /**
     *
     * @param {any} option - Enum case option to check for
     * @returns {bool} - Wheter the enum / any of parent enum contains option
     */
    static isValidOption(option) {
        return this.getCases().has(option);
    }
}

// Enum for CommunicationHub targets
class CommunicationHubTarget extends EnumBase {
    static LISTENER = "listener";
    static EVALUATOR = "evaluator";
    static SERVERMESSAGE = "serverMessage";
    static CLIENTMESSAGE = "clientMessage";
    static MANAGER = "manager";
}

// MARK: Objects

// Target action of communication hub
class CommunicationHubTargetAction {
    /**
     * Used to represent the action
     * that all listener methods should listen to
     *
     * @param {TargetType} action - target type describing enum and its enum case
     * @param {HTMLElement|Object} onObject - The HTMLElement the action is related to, or metadata
     * @param {Object} metadata - Metadata associated with the action, if `secondArg` is an HTMLElement
     */
    constructor(action, onObject, metadata) {
        // This should force user to create an Enum with target action for each module
        // So if the target is `ListenerBase` we should create or extend `ListenerBaseActions`
        // This should enforce some type safety
        // There is also need to register the action in the target class
        if (validateEnumeration(action)) {
            this.action = action;
        }

        // If second argument is instace of HTMLElement set it onObject
        // If there is a thrid argument it is metadata
        if(onObject instanceof HTMLElement) {
            this.onObject = onObject;
            this.metadata = metadata || {};
        } else {
            this.onObject = null;
            this.metadata = onObject || {};
        }
    }
}

/**
 * Object for base server message
 * @param {string} id
 * @param {string} action
 * @param {string} value
 * @param {string} authToken
 * @param {*} metadata
 */
function MessageObject(id, action, value, authToken,metadata = {}) {
    this.id = id;
    this.action = action;
    this.value = value;
    this.metadata = metadata
    this.authToken = authToken;
}

/**
 *
 * @param {string} selector
 * @param {string} action
 * @param {string} getValueBySelector
 * @param {any} onListen - action to be fired
 * @param {string} event - observed event (input / click / onmouseover)
 */

function ClientMessageAction(selector, action, getValueBySelector, onListen, event) {
    this.selector = selector;
    this.action = action;
    this.getValueBySelector = getValueBySelector;
    this.onListen = onListen;
    this.event = event;
}

// MARK: Interfaces / Base classes

class ListeningInterface {
    /**
     *
     * @param  {CommunicationHubTargetAction} action  - An action object
     */
    listen(action) {};
}

class EventEmitter {
    hub;
    /**
     * @param {TargetType} target - The target must be one of the CommunicationHubTarget class static properties, or static properties of the class that extend CommunicationHubTarget
     * @param  {CommunicationHubTargetAction} action  - An action object
     */
    emit(target , action) {
        if (this.hub) {
            if (validateEnumeration(target, CommunicationHubTarget)) {
                this.hub.listen(target.value, action);
                return;
            }
        }
        throw new Error("Hub is not defined yet");
    }

    /**
     * @param {CommunicationHub} hub
     */
    setHub(hub) {
        this.hub = hub;
    }
}

const emitter = new EventEmitter();
