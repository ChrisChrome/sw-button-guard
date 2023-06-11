const config = require("./config.json")
const Discord = require("discord.js")
const client = new Discord.Client({ intents: ["Guilds", "GuildMessages", "MessageContent"] })
// Initialize express
const express = require('express');
const app = express();

app.get("/request", async (req, res) => {
	console.log(req.query)
	if (req.query.auth != config.auth) return res.send("auth")
	if (currentUserId && (req.query.steamid != currentUserId)) return res.send("busy");
	console.log("Testing")
	switch (state) {
		case "idle":
			console.log("idle")
			currentUserId = req.query.steamid
			client.channels.fetch(config.discord.channel).then(cha => {
				cha.send({
					content: `${decodeURI(req.query.name)} on ${decodeURI(req.query.server)} is requesting the panels to be opened`,
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
					state = "wait"
					currentTimeout = setTimeout(() => {
						if (state == "wait") {
							state = "timeout"
							msg.edit({
								content: `The request has timed out`,
								components: []
							})
						}
					}, 60000)
					res.send("wait")
				})
			})
			break;
		case "wait": // Waiting for input from discord
			console.log("wait")
			res.send("wait")
			break;

		case "timeout": // Discord user did not respond in time
			console.log("timeout")
			res.send("to")
			state = "idle"
			currentUserId = null;
			clearTimeout(currentTimeout)
			currentTimeout = null;
			break;

		case "open": // Discord user accepted the request
			console.log("open")
			res.send("open")
			state = "idle"
			currentUserId = null;
			clearTimeout(currentTimeout)
			break;

		case "deny": // Discord user denied the request
			console.log("deny")
			res.send("deny")
			state = "idle"
			currentUserId = null;
			clearTimeout(currentTimeout)
			break;

		default:
			console.log("error")
			res.send("error")
			state = "idle"
			currentUserId = null;
			clearTimeout(currentTimeout)
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
		if (state == "idle") return interaction.reply({ content: "Timed out", ephemeral: true })
		if (interaction.customId === "open") {
			interaction.reply({ content: "Panel will open", ephemeral: true })
			interaction.message.edit({
				content: `The request has been accepted`,
				components: []
			})
			state = "open"
		} else if (interaction.customId === "deny") {
			interaction.reply({ content: "Panel access denied", ephemeral: true })
			interaction.message.edit({
				content: `The request has been denied`,
				components: []
			})
			state = "deny"
		}
	}
})


var state = "idle"
var currentUserId = null;
var currentTimeout = null;
var currentMsg = null;

client.login(config.discord.token)