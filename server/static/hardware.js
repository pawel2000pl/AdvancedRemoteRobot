
var ws = null;
var onHardwareMessage = ()=>{};

const connectWS = function () {
    const protocol = window.location.protocol == "http:" ? "ws:" : "wss:";
    ws = new WebSocket(protocol + "//"+window.location.host+"/hardware");
    ws.onopen = ()=>{};
    ws.onmessage = (message)=>{
        let data = JSON.parse(message.data);
        onHardwareMessage(data);
    };
    ws.onclose = ()=>{
        ws = null;
        setTimeout(connectWS, 1000);
    };
};


window.addEventListener('beforeunload', ()=>{
    ws.onclose = ()=>{};
    ws.close()
});



connectWS();


function setEngines(left, right) {
    if (!ws) return;
    ws.send(JSON.stringify({
        action:'set',
        data: [
            {
                addr: 1,
                value: left
            },
            {
                addr: 2,
                value: right
            }
        ]
    }));
}


function setBeep(value) {
    if (!ws) return;
    ws.send(JSON.stringify({
        action:'set',
        addr: 4,
        value: value
    }));
}

