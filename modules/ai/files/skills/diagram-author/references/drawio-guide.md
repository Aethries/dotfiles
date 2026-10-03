# draw.io XML Guide

Generating uncompressed, valid `.drawio` XML files for visual editors.

---

## 1. Minimal Uncompressed Template
Save file with extension `.drawio` (or embedded in XML markdown blocks).

```xml
<mxfile host="Electron" modified="2026-09-20T00:00:00.000Z" agent="Antigravity" version="22.0.0" type="device">
  <diagram id="diagram-1" name="Architecture">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="node-client" value="Client App" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="120" y="160" width="140" height="60" as="geometry" />
        </mxCell>
        <mxCell id="node-server" value="API Gateway" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="360" y="160" width="140" height="60" as="geometry" />
        </mxCell>
        <mxCell id="edge-1" value="HTTPS" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" edge="1" source="node-client" target="node-server" parent="1">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## 2. Construction Guidelines
- Ensure all IDs (`id="0"`, `id="1"`, `id="node-..."`) are globally unique within the `<root>`.
- Use explicit coordinates (`x`, `y`, `width`, `height`) with uniform spacing (e.g. 100px increments).
- Verify all XML opening tags have matching closing tags.
