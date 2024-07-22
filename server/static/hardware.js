

const connectWS = function () {
    const protocol = window.location.protocol == "http:" ? "ws:" : "wss:";
    ws = new WebSocket(protocol + "//"+window.location.host+"/hardware");
    ws.onopen = ()=>{
        ws.send(JSON.stringify({"action": "authentication", "token": localStorage.token}));
    };
    ws.onmessage = (message)=>{
        let data = JSON.parse(message.data);
        console.log(data);
    };
    ws.onclose = ()=>{setTimeout(connectWS, 3000)};
};


window.addEventListener('beforeunload', ()=>{
    ws.onclose = ()=>{};
    ws.close()
});



localStorage.token = 'hakieshaslo';
connectWS();
