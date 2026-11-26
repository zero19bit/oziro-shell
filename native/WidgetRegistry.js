function validateManifest(m) {
    if (!m || typeof m !== "object" || Array.isArray(m)) return null;
    if (Object.keys(m).some(k => !["version","id","title","type"].includes(k))) return null;
    if (m.version !== 1 || typeof m.id !== "string" || !/^user-[a-z0-9-]{1,32}$/.test(m.id)) return null;
    if (typeof m.title !== "string" || !m.title.trim() || m.title.length > 48 || /[\u0000-\u001f\u007f]/.test(m.title)) return null;
    if (!["clock","battery","audio","memory"].includes(m.type)) return null;
    return {version:1,id:m.id,title:m.title.trim(),type:m.type};
}

function normalizeExtensions(list) {
    if (!Array.isArray(list)) return [];
    const result=[];
    for (const item of list.slice(0,32)) {
        const m=validateManifest(item);
        if (m && !result.some(x=>x.id===m.id) && result.length<4) result.push(m);
    }
    return result;
}

function builtinCards() {
    return [{id:"clock",title:"Clock",type:"clock"},{id:"battery",title:"Battery",type:"battery"},{id:"audio",title:"Audio",type:"audio"},{id:"memory",title:"System memory",type:"memory"}];
}

function normalizeEnabled(list, extensions) {
    const valid=builtinCards().concat(extensions).map(m=>m.id);
    return Array.isArray(list)?valid.filter(id=>list.includes(id)):builtinCards().map(m=>m.id);
}

function selfTest() {
    const good={version:1,id:"user-power",title:"Power overview",type:"battery"};
    const cases=[
        !!validateManifest(good),
        !validateManifest({...good,command:"echo bad"}),
        !validateManifest({...good,id:"../test"}),
        !validateManifest({...good,id:"clock"}),
        !validateManifest({...good,type:"shell"}),
        !validateManifest({...good,version:2}),
        !validateManifest({...good,title:" "}),
        !validateManifest({...good,title:"x".repeat(49)}),
        !validateManifest({...good,title:"a\nb"}),
        !validateManifest(null),
        normalizeExtensions([good,good,null]).length===1,
        normalizeExtensions(Array.from({length:6},(_,i)=>({...good,id:"user-"+i}))).length===4,
        normalizeEnabled(["clock","bad","clock"],[]).join(",")==="clock",
        normalizeEnabled(["user-power"],[good]).join(",")==="user-power",
        normalizeEnabled([],[]).length===0,
        normalizeEnabled(undefined,[]).length===4
    ];
    return {total:cases.length,passed:cases.filter(Boolean).length,failures:cases.map((v,i)=>v?0:i+1).filter(Boolean)};
}
