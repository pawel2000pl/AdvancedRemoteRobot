
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

window.addEventListener('load', ()=>{
    document.addEventListener('keydown', sendKey);
    document.addEventListener('keyup', sendUpKey);
    document.getElementById('led-chk').addEventListener('change', updateLed);
    document.getElementById('camera-x').addEventListener('input', updateCamera);
    document.getElementById('camera-y').addEventListener('input', updateCamera);
});

