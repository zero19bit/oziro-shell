function policy(mode,source,manual,auto,dock,pause) {
    const eco = manual || mode === "eco" || (mode === "adaptive" && auto && source === "battery");
    const suspended = !!(dock && pause && source === "battery" && eco);
    const reason = manual ? "Manual override" : mode === "eco" ? "Eco selected" : mode === "balanced" ? "Balanced selected" : !auto ? "Adaptive battery reduction off" : source === "battery" ? "Adaptive: battery power" : source === "ac" ? "Adaptive: AC power" : "Adaptive: power source unknown";
    return {eco:!!eco,suspended,reason};
}

function selfTest() {
    const cases = [
        ["adaptive","ac",false,true,true,true,false,false],
        ["adaptive","battery",false,true,true,true,true,true],
        ["adaptive","unknown",false,true,true,true,false,false],
        ["adaptive","battery",false,false,true,true,false,false],
        ["balanced","battery",false,true,true,true,false,false],
        ["balanced","battery",true,true,true,true,true,true],
        ["eco","ac",false,true,true,true,true,false],
        ["eco","battery",false,true,true,true,true,true],
        ["eco","unknown",false,true,true,true,true,false],
        ["eco","battery",false,true,true,false,true,false],
        ["eco","battery",false,true,false,true,true,false],
        ["adaptive","ac",true,true,true,true,true,false],
        ["balanced","ac",false,false,true,true,false,false],
        ["eco","battery",true,false,true,true,true,true]
    ];
    let failures=[];
    for(let i=0;i<cases.length;i++){
        const x=cases[i], actual=policy(...x.slice(0,6));
        if(actual.eco!==x[6] || actual.suspended!==x[7]) failures.push(i+1);
    }
    return {total:cases.length,passed:cases.length-failures.length,failures};
}
