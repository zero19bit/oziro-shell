function validateManifest(m) {
    if (!m || typeof m !== "object" || Array.isArray(m)) return null;
    var allowed = ["version","id","title","type"];
    var keys = Object.keys(m);
    for (var i=0;i<keys.length;i++) if (allowed.indexOf(keys[i]) === -1) return null;
    if (m.version !== 1 || typeof m.id !== "string" || !/^user-[a-z0-9-]{1,32}$/.test(m.id)) return null;
    if (typeof m.title !== "string" || !m.title.trim() || m.title.length > 48 || /[\u0000-\u001f\u007f]/.test(m.title)) return null;
    if (["clock","battery","audio","memory"].indexOf(m.type) === -1) return null;
    return {version:1,id:m.id,title:m.title.trim(),type:m.type};
}

function normalizeExtensions(list) {
    if (!Array.isArray(list)) return [];
    var result=[], ids=[];
    for (var i=0;i<Math.min(list.length,32) && result.length<4;i++) {
        var m=validateManifest(list[i]);
        if (m && ids.indexOf(m.id) === -1) {result.push(m);ids.push(m.id);}
    }
    return result;
}

function builtinCards() {
    return [{id:"clock",title:"Clock",type:"clock"},{id:"battery",title:"Battery",type:"battery"},{id:"audio",title:"Audio",type:"audio"},{id:"memory",title:"System memory",type:"memory"}];
}

function normalizeEnabled(list, extensions) {
    var all=builtinCards().concat(normalizeExtensions(extensions));
    var result=[];
    for (var i=0;i<all.length;i++) {
        if (Array.isArray(list) ? list.indexOf(all[i].id) !== -1 : i<4) result.push(all[i].id);
    }
    return result;
}

function testManifest(key,value) {
    var m={version:1,id:"user-power",title:"Power overview",type:"battery"};
    if (typeof key === "string") m[key]=value;
    return m;
}

function selfTest() {
    var good=testManifest();
    var many=[];
    for(var i=0;i<6;i++) many.push(testManifest("id","user-"+i));
    var cases=[
        !!validateManifest(good),
        !validateManifest(testManifest("command","echo bad")),
        !validateManifest(testManifest("id","../test")),
        !validateManifest(testManifest("id","clock")),
        !validateManifest(testManifest("type","shell")),
        !validateManifest(testManifest("version",2)),
        !validateManifest(testManifest("title"," ")),
        !validateManifest(testManifest("title",new Array(50).join("x"))),
        !validateManifest(testManifest("title","a\nb")),
        !validateManifest(null),
        normalizeExtensions([good,good,null]).length===1,
        normalizeExtensions(many).length===4,
        normalizeEnabled(["clock","bad","clock"],[]).join(",")==="clock",
        normalizeEnabled(["user-power"],[good]).join(",")==="user-power",
        normalizeEnabled([],[]).length===0,
        normalizeEnabled(undefined,[]).length===4
    ];
    var failures=[];
    for(var j=0;j<cases.length;j++) if(!cases[j]) failures.push(j+1);
    return {total:cases.length,passed:cases.length-failures.length,failures:failures};
}
