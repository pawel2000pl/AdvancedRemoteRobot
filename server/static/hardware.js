const PING_INTERVAL = 1000;

var ws = null;
var onHardwareMessage = ()=>{};
var configuration = null;
var registers = null;

const connectWS = function () {
    const protocol = window.location.protocol == "http:" ? "ws:" : "wss:";
    var pingTimer = 0; 
    pingTimer = setInterval(()=>{
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                action:'set',
                addr: registers.ping.address,
                value: PING_INTERVAL
            }));
        } else if (ws.readyState === WebSocket.CONNECTING)
            clearInterval(pingTimer);
    }, PING_INTERVAL);
    ws = new WebSocket(protocol + "//"+window.location.host+"/hardware");
    ws.onopen = ()=>{};
    ws.onmessage = (message)=>{
        let data = JSON.parse(message.data);
        onHardwareMessage(data);
    };
    ws.onclose = ()=>{
        clearInterval(pingTimer);
        ws = null;
        setTimeout(connectWS, 1000);
    };
};


window.addEventListener('beforeunload', ()=>{
    ws.onclose = ()=>{};
    ws.close()
});


const settingsPromise = fetch('/settings').then(async (response)=>{
    const data = await response.json();
    configuration = data.configuration;
    registers = Object.fromEntries(Object.keys(data.registers_addresses).map((key)=>{
            return [key, {
                name: key,
                address: data.registers_addresses[key],
                writeable: key in data.write_registers,
                readable: key in data.read_registers,
            }];
        })
    );
    connectWS();
});


function setEngines(left, right) {
    if (!ws) return;
    ws.send(JSON.stringify({
        action:'set',
        data: [
            {
                addr: registers.leftEngine.address,
                value: left
            },
            {
                addr: registers.rightEngine.address,
                value: right
            }
        ]
    }));
}


function setBeep(value) {
    if (!ws) return;
    ws.send(JSON.stringify({
        action:'set',
        addr: registers.beep.address,
        value: value
    }));
}

