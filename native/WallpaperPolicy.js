function validPath(p) {return typeof p==="string"&&p.length<=2048&&p.charAt(0)==="/"&&p.charAt(1)!=="/"&&!/[\u0000-\u001f\u007f]/.test(p)&&/\.(png|jpe?g|webp|bmp)$/i.test(p);}

function fileUrl(p) {if(!validPath(p))return "";try{return "file://"+p.split("/").map(function(part){return encodeURIComponent(part);}).join("/");}catch(e){return "";}}

function normalize(c) {if(!c||typeof c!=="object")c={};var path=fileUrl(c.path)?c.path:"";return {enabled:c.enabled===true,mode:c.mode==="image"&&path?"image":"solid",color:typeof c.color==="string"&&/^#[0-9a-fA-F]{6}$/.test(c.color)?c.color.toLowerCase():"#18232f",path:path,fit:c.fit==="contain"?"contain":"cover"};}

function selfTest(){var cases=[!normalize(null).enabled,normalize(null).mode==="solid",normalize({enabled:true,mode:"image",path:"/home/a.png"}).mode==="image",normalize({mode:"image",path:"https://a.png"}).mode==="solid",!validPath("//host/a.png"),!validPath("/tmp/a.svg"),!validPath("/tmp/a\n.png"),fileUrl("/tmp/my photo #1.png")==="file:///tmp/my%20photo%20%231.png",normalize({color:"#ABCDEF"}).color==="#abcdef",normalize({color:"red"}).color==="#18232f",normalize({fit:"contain"}).fit==="contain",normalize({fit:"unknown"}).fit==="cover"];return {total:cases.length,passed:cases.filter(Boolean).length};}
