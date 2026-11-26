// Pure geometry. Stable slot centers avoid feedback between hover and layout.
function factor(distance, pitch, active) {
    if (!active || typeof distance !== "number" || !isFinite(distance) || !(pitch > 0)) return 0;
    var t = Math.abs(distance) / (pitch * 2.35);
    if (t >= 1) return 0;
    return (1 - t * t) * (1 - t * t);
}
function scale(distance, pitch, active) { return 1 + 0.38 * factor(distance, pitch, active); }
function selfTest() {
    var p = 52;
    var cases = [
        factor(0,p,true)===1, factor(0,p,false)===0,
        factor(p,p,true)>factor(2*p,p,true), factor(2*p,p,true)>0,
        factor(3*p,p,true)===0, factor(-p,p,true)===factor(p,p,true),
        scale(0,p,true)===1.38, scale(p,p,false)===1,
        factor(NaN,p,true)===0, factor(0,0,true)===0,
        // At max base size, scaled adjacent artwork remains within its combined slot pitch.
        (64*.80*(scale(0,72,true)+scale(72,72,true)))/2 < 72
    ];
    return {total:cases.length,passed:cases.filter(Boolean).length};
}
