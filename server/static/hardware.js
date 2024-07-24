
var ws = null;

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
    ws.onclose = ()=>{
        ws = null;
        setTimeout(connectWS, 1000);
    };
};


window.addEventListener('beforeunload', ()=>{
    ws.onclose = ()=>{};
    ws.close()
});



localStorage.token = 'hakieshaslo';
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


const updateHardware = function() {
    const values = mapKeys();
    setEngines(values.left*255, values.right*255);
};

var keyBuf = new Set();

function mapKeys(){
    var left = 0;
    var right = 0;
    if (keyBuf.has("d")) {
        left += 1;
        right -= 1;
    }
    if (keyBuf.has("a")) {
        left -= 1;
        right += 1;
    }
    if (keyBuf.has("e")) 
        right += 1;
    if (keyBuf.has("c"))
        right -= 1;
    if (keyBuf.has("q"))
        left += 1;
    if (keyBuf.has("z"))
        left -= 1;
    if (keyBuf.has("w") || (keyBuf.has("s"))) {
        left += 1;
        right += 1;
    }
    if (keyBuf.has("s")) {
        left *= -1;
        right *= -1;
    }
    if (keyBuf.has(" ")) {
        left = 0;
        right = 0;
        keyBuf.clear();
    }
    var divisor = Math.max(Math.abs(left), Math.abs(right));
    if (divisor > 0) {
        left /= divisor;
        right /= divisor;
    }
    return {left, right};
}


async function sendKey(event) { 
    console.log(event);
    keyBuf.add(event.key.toLowerCase());
    updateHardware();
}

async function sendUpKey(event) {
    keyBuf.delete(event.key.toLowerCase());
    updateHardware();
}

window.addEventListener('load', ()=>{
    document.addEventListener('keydown', sendKey);
    document.addEventListener('keyup', sendUpKey);
});


