
const cameraView = document.getElementById('camera-view');
const enableVideoChk = document.getElementById('camera-chk');
const speedRange = document.getElementById('speed-range');



enableVideoChk.addEventListener('change', ()=>{
    if (enableVideoChk.checked) 
        cameraView.src = '/video/stream';
    else
        cameraView.src = '';
});


var keyBuf = new Set();


function mapKeys() {
    let left = 0;
    let right = 0;
    if (keyBuf.has('w') || keyBuf.has('s')) {
        left += 1;
        right += 1;
    }
    if (keyBuf.has('d')) {
        left += 1;
        right -= 1;
    }
    if (keyBuf.has('a')) {
        left -= 1;
        right += 1;
    }

    if (keyBuf.has('s')) {
        left *= -1;
        right *= -1;
    }

    if (keyBuf.has('q'))
        left += 1;
    if (keyBuf.has('z'))
        left -= 1;
    if (keyBuf.has('e'))
        right += 1;
    if (keyBuf.has('c'))
        right -= 1;

    let divisor = Math.max(Math.abs(left), Math.abs(right));
    if (divisor > 0) {
        left /= divisor;
        right /= divisor;
    }

    const beep = Number(keyBuf.has('b'));

    const camX = Number(keyBuf.has('l')) - Number(keyBuf.has('j'));
    const camY = Number(keyBuf.has('i')) - Number(keyBuf.has('k'));

    return {left, right, beep, camX, camY};
}

const updateHardware = function() {
    const values = mapKeys();
    registers.leftEngine.setValue(speedRange.value*values.left, true);
    registers.rightEngine.setValue(speedRange.value*values.right, true);
    registers.beep.setValue(values.beep, true);

    const camX = document.getElementById('camera-x');
    const camY = document.getElementById('camera-y');
    if (document.getElementById('camera-push-to-turn').checked) {
        camX.value = values.camX * 140;
        camY.value = values.camY * 140;
    } else {
        camX.value = Number(camX.value) + values.camX * 15;
        camY.value = Number(camY.value) + values.camY * 15;
    }
    updateCamera();
    updateRegisters(false);
};

async function sendKey(event) { 
    keyBuf.add(event.key.toLowerCase());
    if (keyBuf.has(' ')) keyBuf.clear();
    updateHardware();
}

async function sendUpKey(event) {
    keyBuf.delete(event.key.toLowerCase());
    if (keyBuf.has(' ')) keyBuf.clear();
    updateHardware();
}

async function updateLed() {
    registers.led.setValue(document.getElementById('led-chk').checked);
    updateRegisters(false);
}

async function updateCamera() {
    registers.cameraX.setValue(document.getElementById('camera-x').value);
    registers.cameraY.setValue(document.getElementById('camera-y').value);
}

function addGamepad(e) {
    const gamepad = e.gamepad;
    
    const handler = (repeatFun)=>{
        if (gamepad.connected) {
            const returning = gamepad.buttons[4].value ? 1 : -1;
            const forward = -gamepad.axes[1];
            const left = forward - gamepad.axes[0] * returning;
            const right = forward + gamepad.axes[0] * returning;
            const scale = Math.max(1, Math.max(Math.abs(left), Math.abs(right)));

            registers.leftEngine.setValue(speedRange.value*left/scale, true);
            registers.rightEngine.setValue(speedRange.value*right/scale, true);
            registers.beep.setValue(gamepad.buttons[5].value ? 1 : 0, true);
        
            const camX = document.getElementById('camera-x');
            const camY = document.getElementById('camera-y');
            if (document.getElementById('camera-push-to-turn').checked) {
                camX.value = gamepad.axes[3] * 255;
                camY.value = gamepad.axes[2] * 255;
            } else {
                camX.value = Number(camX.value) + gamepad.axes[3] * 60;
                camY.value = Number(camY.value) + gamepad.axes[2] * 60;
            }
            updateCamera();
            updateRegisters(false);

            setTimeout(()=>repeatFun(repeatFun), 50);
        }
    };

    handler(handler);
}

window.addEventListener('load', ()=>{
    document.addEventListener('keydown', sendKey);
    document.addEventListener('keyup', sendUpKey);
    document.getElementById('led-chk').addEventListener('change', updateLed);
    document.getElementById('camera-x').addEventListener('input', updateCamera);
    document.getElementById('camera-y').addEventListener('input', updateCamera);

    window.addEventListener("gamepadconnected", addGamepad);
      
});

