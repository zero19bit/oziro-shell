const previewItems = [
  { glyph: 'F', name: 'Files' },
  { glyph: 'W', name: 'Web' },
  { glyph: '>_', name: 'Terminal' },
  { glyph: 'S', name: 'Settings' },
];

export function Dock() {
  return (
    <aside className="dock" aria-label="Preview application dock">
      <span className="dock-caption">PREVIEW</span>
      <div className="dock-items" role="list">
        {previewItems.map((item) => (
          <div className="dock-item" role="listitem" key={item.name}>
            <span className="dock-glyph" aria-hidden="true">
              {item.glyph}
            </span>
            <span className="dock-tooltip">{item.name}</span>
          </div>
        ))}
      </div>
      <span className="dock-separator" />
      <span className="dock-footnote">UI only</span>
    </aside>
  );
}
