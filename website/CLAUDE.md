# Website Development

## Build
```bash
cd website
bun install
bun run build    # builds to dist/
bun run dev      # watch mode + local server
```

## Style Rules

- **Tailwind only**: No inline `style` attributes. Use Tailwind utility classes or arbitrary value syntax (`bg-[var(--custom)]`).
- **Theme colors**: Defined as CSS custom properties in `src/styles.css` via `@theme`. Use semantic names: `bg-bg`, `text-fg`, `text-fg-muted`, `bg-bg-surface`, `bg-bg-elevated`, `border-fg-faint`, `text-wine-light`, etc.
- **Dark/light mode**: Theme class (`dark`/`light`) on `<html>`. CSS variables swap values in `.light` class. No Tailwind `dark:` variant needed since colors are variable-based.
- **Fonts**: JetBrains Mono (`font-mono`) for headings, code, and UI elements. DM Sans (`font-sans`) for body text.
- **Brand colors**: wine (#5B2333), wine-light (#7a3348), from All Tuner brand palette.
- **Section structure**: Each section uses the pattern: section label (uppercase mono, wine-light) + h2 title (mono, bold) + description paragraph (fg-muted).
- **Animations**: Custom keyframes in CSS (`animate-fade-up`, `animate-blink`, etc.). Scroll reveals use `.reveal` class with IntersectionObserver.
- **No external JS dependencies**. Vanilla JS only.
- **Google Fonts loaded via `<link>`** in the HTML head (JetBrains Mono + DM Sans).
- **Poblenou skyline SVG** in footer, using wine gradient stroke.
