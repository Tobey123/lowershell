var raw = require('raw-socket');
var socket = raw.createSocket({protocol: raw.Protocol.ICMP});

socket.on("message", function (buffer, source) {
    console.log ("received " + buffer.length + " bytes from " + source);
    console.log(buffer.toString())
});
