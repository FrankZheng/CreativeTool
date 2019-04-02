console = {};
console.log = function(s) {
    window.webkit.messageHandlers.VungleMessageHandler.postMessage('log:'+s);
}

console.error = function(s) {
    window.webkit.messageHandlers.VungleMessageHandler.postMessage('error:'+s);
}

window.onerror = function(errorMsg, script, lineNumber, column, stack) {
    var msg = '(' + script + ':' + lineNumber + ',' + column + ')' + errorMsg + '\n' + stack;
    console.error(msg);
}

window.console = console;

