-- Keep the recording overlay from receiving the paste intended for an editor.
if spokenly_trial_overlay_rule then
    spokenly_trial_overlay_rule:set_enabled(false)
end
spokenly_trial_overlay_rule = hl.window_rule({
    name = "spokenly-trial-overlay-no-focus",
    match = { class = "Spokenly", initial_title = "Recording" },
    no_focus = true,
    -- Use monitor-local geometry after lid/display changes.
    move = { "(monitor_w-window_w)/2", "monitor_h-window_h-40" },
})
