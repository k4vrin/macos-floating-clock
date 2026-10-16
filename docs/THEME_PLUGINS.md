# Theme plugins

Themes are data-only palettes installed through **Settings → Install theme or clock pack…**. They share the existing schema version 1 pack manifest and native renderers. Existing clock and widget manifests remain compatible because `themes` is optional.

A pack can contain clocks, widgets, themes, or any combination. Theme-only packs specify `"clocks": []`. Each collection permits up to 24 entries. The manifest remains limited to 64 KiB and must be a regular JSON file, not a symbolic link. Pack IDs, theme IDs, names, duplicate IDs, and RGB colors are validated before the atomic installation write. Scripts and dynamic libraries are not loaded.

```json
{
  "schemaVersion": 1,
  "id": "dev.kavrin.tide-pool",
  "name": "Tide Pool",
  "clocks": [],
  "themes": [
    {
      "id": "sea-glass",
      "name": "Sea glass",
      "shell": "163A39",
      "surface": "E0EEE6",
      "ink": "204641",
      "text": "E0EEE6",
      "muted": "A7C4B8",
      "clockAccent": "408B7C",
      "widgetAccent": "A57836"
    }
  ]
}
```

All seven colors are required six-digit RGB strings without `#`. `shell` colors the bar and expanded body; `surface` and `ink` color dial/date materials; `text` and `muted` color labels on the shell. Clock and widget accents replace design accents unless optional `usesDesignAccents` is `true`. The Original objects palette uses this option to preserve installed designs' own accents. Small decorative markers and physical-material highlights remain part of the renderer's design.

The selected theme applies to both compact and expanded components and survives clock or widget replacement. Palettes are held per view so native previews can render different themes without changing another clock instance.

Install [the example](../examples/tide-pool.clockpack.json), then choose **Tide Pool · Sea glass** from Theme. Bundled choices are Original objects, Blue hour, and Plum & brass. Plugins reuse renderers; they cannot add arbitrary native view code, animation scripts, fonts, or assets. There is no theme marketplace or update service in this prototype.
