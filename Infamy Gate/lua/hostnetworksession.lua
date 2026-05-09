local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local ls_original_hostnetworksession_onjoinrequestreceived = HostNetworkSession.on_join_request_received
function HostNetworkSession:on_join_request_received(...)
    local required = Global.game_settings.infamy_permission or 0
    if required > 0 then
        local peer_rank = select(8, ...)
        if type(peer_rank) == 'number' and peer_rank < required then
            return
        end
    end

    ls_original_hostnetworksession_onjoinrequestreceived(self, ...)
end