
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

    return {left, right, beep};
}

const updateHardware = function() {
    const values = mapKeys();
    registers.leftEngine.setValue(speedRange.value*values.left, true);
    registers.rightEngine.setValue(speedRange.value*values.right, true);
    registers.beep.setValue(values.beep, true);
    console.log(registers.leftEngine.value, registers.rightEngine.value);
    updateRegisters(false);
};

async function sendKey(event) { 
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


