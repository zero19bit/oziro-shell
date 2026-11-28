// Pure geometry. Stable slot centers avoid feedback between hover and layout.
function factor(distance, pitch, active) {
    if (!active || typeof distance !== "number" || !isFinite(distance) || !(pitch > 0)) return 0;
    var t = Math.abs(distance) / (pitch * 2.35);
    if (t >= 1) return 0;
    return (1 - t * t) * (1 - t * t);
}
function scale(distance, pitch, active) { return 1 + 0.38 * factor(distance, pitch, active); }
// Wheel pixel deltas are already signed according to compositor scroll preference.
function scrollOffset(current, delta, content, viewport) {
    if (![current,delta,content,viewport].every(function(v){return typeof v === "number" && isFinite(v);})) return 0;
    return Math.max(0, Math.min(Math.max(0,content-viewport),current-delta));
}
function selfTest() {
    var p = 52;
    var cases = [
        factor(0,p,true)===1, factor(0,p,false)===0,
        factor(p,p,true)>factor(2*p,p,true), factor(2*p,p,true)>0,
        factor(3*p,p,true)===0, factor(-p,p,true)===factor(p,p,true),
        scale(0,p,true)===1.38, scale(p,p,false)===1,
        factor(NaN,p,true)===0, factor(0,0,true)===0,
        // At max base size, scaled adjacent artwork remains within its combined slot pitch.
        (64*.80*(scale(0,72,true)+scale(72,72,true)))/2 < 72,
        scrollOffset(100,20,300,100)===80,
        scrollOffset(0,20,300,100)===0,
        scrollOffset(190,-30,300,100)===200,
        scrollOffset(0,-20,80,100)===0,
        scrollOffset(10,NaN,300,100)===0,
        scrollOffset(100,-0.5,300,100)===100.5
    ];
    return {total:cases.length,passed:cases.filter(Boolean).length};
}
