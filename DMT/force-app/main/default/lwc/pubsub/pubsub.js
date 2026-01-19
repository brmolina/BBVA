const callbacks = {};

const pubsub = {
    // Publicar un evento
    publish: (eventName, payload) => {
        if (callbacks[eventName]) {
            callbacks[eventName].forEach(callback => {
                try {
                    callback(payload);
                } catch (e) {
                    console.error(e);
                }
            });
        }
    },
    // Suscribirse a un evento
    subscribe: (eventName, callback) => {
        if (!callbacks[eventName]) {
            callbacks[eventName] = [];
        }
        callbacks[eventName].push(callback);
    },
    // Desuscribirse de un evento
    unsubscribe: (eventName, callback) => {
        if (callbacks[eventName]) {
            callbacks[eventName] = callbacks[eventName].filter(cb => cb !== callback);
        }
    }
};

export default pubsub;