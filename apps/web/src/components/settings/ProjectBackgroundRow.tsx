import type { ProjectIconColor } from "@t3tools/contracts";
import { T, useGT, useMessages } from "gt-react";

import { PROJECT_ICON_COLORS } from "../../projectIconColors";
import { Select, SelectItem, SelectPopup, SelectTrigger, SelectValue } from "../ui/select";
import { SettingResetButton, SettingsRow } from "./settingsLayout";
import {
  useScopedSettings,
  useScopedSettingsMixed,
  useUpdateScopedSettings,
} from "./useScopedSettings";

const NONE = "none";

function isProjectIconColor(value: string | null): value is ProjectIconColor {
  return PROJECT_ICON_COLORS.some((color) => color.value === value);
}

export function ProjectBackgroundRow({ disabled }: { readonly disabled: boolean }) {
  const gt = useGT();
  const m = useMessages();
  const color = useScopedSettings((settings) => settings.projectBackgroundColor);
  const mixed = useScopedSettingsMixed(["projectBackgroundColor"]);
  const updateSettings = useUpdateScopedSettings();
  const swatch = (value: ProjectIconColor) =>
    PROJECT_ICON_COLORS.find((entry) => entry.value === value)?.swatchClassName;

  return (
    <SettingsRow
      serverScoped
      settingKeys={["projectBackgroundColor"]}
      mixed={mixed}
      title={gt("Background")}
      resetAction={
        color !== null ? (
          <SettingResetButton
            ariaLabel={gt("Reset project background to default")}
            disabled={disabled}
            onClick={() => updateSettings({ projectBackgroundColor: null })}
          />
        ) : null
      }
      control={
        <Select
          disabled={disabled}
          value={mixed ? null : (color ?? NONE)}
          onValueChange={(value) =>
            updateSettings({ projectBackgroundColor: isProjectIconColor(value) ? value : null })
          }
        >
          <SelectTrigger size="sm" aria-label={gt("Project background colour")}>
            <SelectValue>
              {(value: string | null) =>
                isProjectIconColor(value) ? (
                  <span className="flex items-center gap-2">
                    <span className={`size-3 shrink-0 rounded-full ${swatch(value)}`} />
                    {m(PROJECT_ICON_COLORS.find((entry) => entry.value === value)!.label)}
                  </span>
                ) : value === NONE ? (
                  gt("None", { $context: "no project background colour" })
                ) : (
                  gt("Mixed", { $context: "values differ across targets" })
                )
              }
            </SelectValue>
          </SelectTrigger>
          <SelectPopup align="end" alignItemWithTrigger={false}>
            <SelectItem value={NONE}>
              <T>None</T>
            </SelectItem>
            {PROJECT_ICON_COLORS.map((entry) => (
              <SelectItem key={entry.value} value={entry.value}>
                <span className="flex items-center gap-2">
                  <span className={`size-3 shrink-0 rounded-full ${entry.swatchClassName}`} />
                  {m(entry.label)}
                </span>
              </SelectItem>
            ))}
          </SelectPopup>
        </Select>
      }
    />
  );
}
