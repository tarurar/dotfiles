-- BEGIN spokenly-trial focus rule
do
    local path = os.getenv("HOME") .. "/.config/hypr/spokenly-trial.lua"
    local file = io.open(path, "r")
    if file then
        file:close()
        dofile(path)
    end
end
-- END spokenly-trial focus rule
