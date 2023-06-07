const config = require("./config.json")
const Discord = require("discord.js")
const client = new Discord.Client({ intents: ["Guilds", "GuildMessages"] })
// Initialize express
const express = require('express');
const app = express();

app.get("/request", async (req, res) => {
	if (req.query.auth != config.auth) return res.send("auth")
	if (req.query.steamid != currentUserId) return res.send("busy");
	switch (state) {
		case "idle":
			currentUserId = req.query.steamid
			client.channels.fetch(config.discord.channel).then(cha => {
				cha.send({
					content: `Someone is requesting the panels to be opened`,
					components: [{
						type: 1,
						components: [
							{
								type: 2,
								label: "Open Door",
								style: Discord.ButtonStyle.Success,
								custom_id: "open"
							},
							{
								type: 2,
								label: "Deny",
								style: Discord.ButtonStyle.Danger,
								custom_id: "deny"
							}
						]
					}]
				}).then(msg => {

					setTimeout(() => {
						if (state == "wait") {
							state = "timeout"
							msg.edit({
								content: `The request has timed out`,
								components: []
							})
						}
					}, 30000)
				})
			})
			break;
		case "wait": // Waiting for input from discord
			res.send("wait")
			break;

		case "timeout": // Discord user did not respond in time
			res.send("to")
			state = "idle"
			break;

		case "open": // Discord user accepted the request
			res.send("open")
			state = "idle"
			break;

		case "deny": // Discord user denied the request
			res.send("deny")
			state = "idle"
			break;

		default:
			res.send("error")
			state = "idle"
			break;
	}
});

client.on("ready", () => {
	console.log("Bot is ready")
	app.listen(config.port, function () {
		console.log("Running on port " + config.port);
	});
})

client.on("interactionCreate", async (interaction) => {
	if (interaction.isButton()) {
		if (state = idle) return interaction.reply({ content: "Timed out", ephemeral: true })
		if (interaction.customId === "open") {
			interaction.reply({ content: "Panel will open", ephemeral: true })
			state = "open"
		} else if (interaction.customId === "deny") {
			interaction.reply({ content: "Panel access denied", ephemeral: true })
			state = "deny"
		}
	}
})


var state = "idle"
var currentUserId = null;

client.login(config.discord.token)