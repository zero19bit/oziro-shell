// Stable IDs preserve existing user preferences. Local, original vector artwork only.
var themes = [
  {
    "id": "material",
    "name": "Midnight",
    "file": "midnight",
    "bg": "#111c30",
    "surface": "#172234",
    "card": "#202e43",
    "accent": "#a4bdf0",
    "outline": "#35445c",
    "muted": "#a4b1c5",
    "fg": "#f1f4f9"
  },
  {
    "id": "glass",
    "name": "Graphite",
    "file": "graphite",
    "bg": "#191b20",
    "surface": "#25272c",
    "card": "#303238",
    "accent": "#aabbd8",
    "outline": "#45474e",
    "muted": "#b1b3bc",
    "fg": "#f1f1f3"
  },
  {
    "id": "cyber",
    "name": "Aurora",
    "file": "aurora",
    "bg": "#102629",
    "surface": "#172d31",
    "card": "#203b3e",
    "accent": "#9bd0c3",
    "outline": "#3b5559",
    "muted": "#a7bfbd",
    "fg": "#eff6f3"
  },
  {
    "id": "light",
    "name": "Porcelain",
    "file": "porcelain",
    "bg": "#e1e6ed",
    "surface": "#f1f3f6",
    "card": "#e5e8ed",
    "accent": "#325b98",
    "outline": "#c9d0da",
    "muted": "#596575",
    "fg": "#202b39"
  },
  {
    "id": "minimal",
    "name": "Minimal",
    "file": "graphite",
    "bg": "#191b20",
    "surface": "#191b20",
    "card": "#25282d",
    "accent": "#aabbd8",
    "outline": "#41454b",
    "muted": "#a5aab3",
    "fg": "#eeeeef"
  }
];
function palette(id) { for(var i=0;i<themes.length;i++) if(themes[i].id===id) return themes[i]; return themes[0]; }
function wallpaperId(theme,preset) { return ["midnight","graphite","aurora","porcelain"].indexOf(preset)>=0 ? preset : palette(theme).file; }
function selfTest() { var c=[palette("material").file==="midnight",palette("glass").file==="graphite",palette("cyber").file==="aurora",palette("light").file==="porcelain",palette("bad").file==="midnight",wallpaperId("cyber","auto")==="aurora",wallpaperId("light","graphite")==="graphite",wallpaperId("light","../../bad")==="porcelain"]; return {total:c.length,passed:c.filter(Boolean).length}; }
