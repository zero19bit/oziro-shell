function compactWindow(w) {return {id:w.id,app_id:w.app_id||"",title:w.title||"",workspace_id:w.workspace_id,is_focused:!!w.is_focused};}

function equalWindow(a,b) {return a.id===b.id && a.app_id===b.app_id && a.title===b.title && a.workspace_id===b.workspace_id && a.is_focused===b.is_focused;}

function sameWindows(a,b) {if(a.length!==b.length)return false;for(var i=0;i<a.length;i++)if(!equalWindow(a[i],b[i]))return false;return true;}

function snapshot(old,raw) {var next=raw.map(compactWindow).sort(function(a,b){return a.id-b.id;});return sameWindows(old,next)?old:next;}

function update(old,raw) {var w=compactWindow(raw),next=[],found=false;for(var i=0;i<old.length;i++){var item=old[i];if(item.id===w.id){next.push(equalWindow(item,w)?item:w);found=true;}else if(w.is_focused&&item.is_focused){next.push({id:item.id,app_id:item.app_id,title:item.title,workspace_id:item.workspace_id,is_focused:false});}else next.push(item);}if(!found){next.push(w);next.sort(function(a,b){return a.id-b.id;});}return sameWindows(old,next)?old:next;}

function focus(old,id) {var next=old.map(function(w){var focused=w.id===id;if(w.is_focused===focused)return w;return {id:w.id,app_id:w.app_id,title:w.title,workspace_id:w.workspace_id,is_focused:focused};});return sameWindows(old,next)?old:next;}

function remove(old,id) {var next=old.filter(function(w){return w.id!==id;});return next.length===old.length?old:next;}

function selfTest(){var a={id:1,app_id:"a",title:"A",workspace_id:2,is_focused:true},b={id:2,app_id:"b",title:"B",workspace_id:2,is_focused:false};var old=snapshot([], [b,a]);var changed=update(old,{id:2,app_id:"b",title:"B2",workspace_id:2,is_focused:true});var cases=[old[0].id===1,snapshot(old,[a,b])===old,update(old,a)===old,focus(old,1)===old,remove(old,3)===old,changed[0].is_focused===false,changed[1].title==="B2"&&changed[1].is_focused,focus(changed,null).every(function(w){return !w.is_focused;}),remove(old,1)[0].id===2,update(old,{id:3,app_id:"c",title:"C",workspace_id:2,is_focused:false}).length===3,old[0].is_focused&&old[1].title==="B"];return {passed:cases.filter(Boolean).length,total:cases.length};}
