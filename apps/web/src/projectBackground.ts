import type { ProjectIconColor } from "@t3tools/contracts";
import type { CSSProperties } from "react";

const tint = (color: ProjectIconColor) =>
  `color-mix(in oklab, var(--color-${color}-500) var(--project-background-tint), transparent)`;

/** Repaints `--background` for a subtree; the parent must expose `--project-base-background`. */
export function projectBackgroundStyle(color: ProjectIconColor | null): CSSProperties | undefined {
  if (color === null) return undefined;
  return {
    "--background": `color-mix(in oklab, var(--project-base-background), var(--color-${color}-500) var(--project-background-tint))`,
  } as CSSProperties;
}

/** Layers the tint over an element's own surface colour, so hover and active fills still show. */
export function projectTintOverlayStyle(color: ProjectIconColor | null): CSSProperties | undefined {
  if (color === null) return undefined;
  return { backgroundImage: `linear-gradient(${tint(color)}, ${tint(color)})` };
}
