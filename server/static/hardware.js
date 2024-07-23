
var ws;

const connectWS = function () {
    const protocol = window.location.protocol == "http:" ? "ws:" : "wss:";
    ws = new WebSocket(protocol + "//"+window.location.host+"/hardware");
    ws.onopen = ()=>{
        for (let i=0;i<3;i++)
            ws.send(JSON.stringify({"action": "authentication", "token": localStorage.token}));
    };
    ws.onmessage = (message)=>{
        let data = JSON.parse(message.data);
        //console.log(data);
    };
    ws.onclose = ()=>{setTimeout(connectWS, 1000)};
};


window.addEventListener('beforeunload', ()=>{
    ws.onclose = ()=>{};
    ws.close()
});



localStorage.token = 'hakieshaslo';
connectWS();


function setEngines(left, right) {
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
    ws.send(JSON.stringify({
        action:'set',
        addr: 4,
        value: value
    }));
}