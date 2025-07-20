local server = require(script.CmdrPlusServer)
local client = require(script.CmdrPlusClient)

export type Server = server.CmdrPlusServer
export type Client = client.CmdrPlusClient

return {
	server = server :: Server,
	client = client :: Client,
} :: {
	server: Server,
	client: Client,
}
