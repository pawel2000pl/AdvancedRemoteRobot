const PING_INTERVAL = 1000;
const SEND_INTERVAL = 60;
const SEND_ALL_INTERVAL = 5000;

var ws = null;
var onHardwareMessage = ()=>{};
var configuration = null;
var registers = null;
var registersByAddress = {};

const sendDataArray =  (packets)=>{
    if (packets.length === 0 || ws === null || ws.readyState !== ws.OPEN)
        return;
    let data = Array(packets.length * 3);
    let i = 0;
    packets.forEach((packet)=>{
        data[i++] = packet[0] & 0xFF;
        data[i++] = packet[1] & 0xFF;
        data[i++] = (packet[1] & 0xFF00) >> 8;
    });
    ws.send(new Uint8Array(data));
};

const sendData = (addr, value) => sendDataArray([[addr, value]]);

const updateRegisters = function(all=true) {
    sendDataArray(Object.values(registers).filter((register)=>register.writeable).filter((register)=>all||register.modified).map((register)=>{
        register.modified = false;
        return [register.address, register.value];}
    ));
};

const makeSigned16 = function(x) {
    return x <= 0x7FFF ? x : x - 0x10000;
};

const connectWS = function () {
    const protocol = window.location.protocol == "http:" ? "ws:" : "wss:";
    var pingTimer = 0; 

    ws = new WebSocket(protocol + "//"+window.location.host+"/hardware");
    ws.onopen = ()=>{};
    ws.onmessage = async (message)=>{
        const data = await message.data.bytes();
        let i = 0;
        let l = data.length - 2;
        while (i < l) {
            const address = data[i++];
            const lo = data[i++];
            const hi = data[i++];
            const value = makeSigned16(lo | (hi << 8));
            onHardwareMessage(address, value);
            if (registersByAddress[address] !== undefined) {
                registersByAddress[address].value = value;
                registersByAddress[address].onChange(value);
                registersByAddress[address].modified = false;
            }
        }
    };
    ws.onclose = ()=>{
        clearInterval(pingTimer);
        ws = null;
        setTimeout(connectWS, 1000);
    };
};


window.addEventListener('beforeunload', ()=>{
    if (ws!==null) {
        ws.onclose = ()=>{};
        ws.close()
    }
});


const settingsPromise = fetch('/settings').then(async (response)=>{
    const data = await response.json();
    configuration = data.configuration;
    registers = Object.fromEntries(Object.keys(data.registers_addresses).map((key)=>{
        const register = {
            name: key,
            address: data.registers_addresses[key],
            writeable: data.write_registers.find(val=>val===key) !== undefined,
            readable: data.read_registers.find(val=>val===key) !== undefined,
            value: 0,
            modified: false,
            onChange: ()=>{},
        };
        register.setValue = (value, forceSetModify=false)=>{
            value = Number(value);
            register.modified = forceSetModify || register.value !== value;
            register.value = value;
        };
        register.appendOnChange = (fun)=>{
            const prev = register.onChange;
            register.onChange = (val)=>{
                prev(val);
                fun(val);
            }
        };
        return [key, register];
    }));
    registersByAddress = Object.fromEntries(Object.values(registers).map(register=>[register.address, register]));
    const arrayDetector = /(.*)\[0\]/i;
    const arrays = Object.keys(registers).map((key)=>arrayDetector.exec(key)).filter((x)=>x!==null).map((x)=>x[1]);
    for (let i=0;i<arrays.length;i++) {
        let curArray = [];
        const prefix = arrays[i];
        let j=0;
        for (let j=0;registers[prefix+'['+j+']']!==undefined;j++)
            curArray.push(registers[prefix+'['+j+']']);
        registers[prefix] = curArray;
    }

    connectWS();
});


function setEngines(left, right) {
    sendDataArray([
        [registers.leftEngine.address, left],
        [registers.rightEngine.address, right]
    ]);
}


function setBeep(value) {
    sendData(registers.beep.address, value);
}


setInterval(()=>{
    if (registers == null)
        return;
    if (ws !== null && ws.readyState === WebSocket.OPEN)
        updateRegisters(false);
}, SEND_INTERVAL);


setInterval(()=>{
    if (registers == null)
        return;
    if (ws !== null && ws.readyState === WebSocket.OPEN)
        updateRegisters(true);
}, SEND_ALL_INTERVAL);


setInterval(()=>{
    if (registers == null)
        return;
    registers.ping.setValue(PING_INTERVAL, true);
    registers.query.setValue(1, true);
}, PING_INTERVAL/5);



settingsPromise.then(()=>{
    const sensorTBody = document.getElementById('sensor-tbody');
    var i=0;
    registers.sensorsStates.forEach((state)=>{
        const tr = document.createElement('tr');
        const tdNum = document.createElement('td');
        const tdName = document.createElement('td');
        const tdVal = document.createElement('td');
        tdNum.textContent = String(i++);
        tdName.textContent = '';
        tdVal.textContent = 0;
        state.appendOnChange((value)=>{
            tdVal.textContent = String(value);
        });
        tr.appendChild(tdNum);
        tr.appendChild(tdName);
        tr.appendChild(tdVal);
        sensorTBody.appendChild(tr);
    });
});


settingsPromise.then(()=>{
    registers.battery.appendOnChange((val)=>{
        document.getElementById('battery-voltage').textContent = (val/1000).toFixed(2) + ' V'; 
    });
    registers.leftVelocity.appendOnChange((val)=>{
        document.getElementById('velocity-left').textContent = val;
    });
    registers.rightVelocity.appendOnChange((val)=>{
        document.getElementById('velocity-right').textContent = val;
    });
});
