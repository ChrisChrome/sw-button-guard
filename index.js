const config = require("./config.json")
const Discord = require("discord.js")
const client = new Discord.Client({ intents: ["Guilds", "GuildMessages"] })
// Initialize express
const express = require('express');
const app = express();

app.get("/request", async (req, res) => {
	if (req.query.auth != config.auth) return res.send("auth")
	if(curReq != null) return res.send("busy");
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
			curReq = res;
			setTimeout(() => {
				if (curReq == res) {
					curReq = null;
					res.send("to")
				}
				msg.edit({
					content: `The request has timed out`,
					components: []
				})
			}, 30000)
		})
	})
});

client.on("ready", () => {
	console.log("Bot is ready")
	app.listen(config.port, function () {
		console.log("Running on port " + config.port);
	});
})

client.on("interactionCreate", async (interaction) => {
	if (interaction.isButton()) {
		if (curReq == null) return interaction.reply({ content: "Timed out", ephemeral: true })
		if (interaction.customId === "open") {
			interaction.reply({ content: "Door opened", ephemeral: true })
			curReq.send("true")
			curReq = null;
		} else if (interaction.customId === "deny") {
			interaction.reply({ content: "Door denied", ephemeral: true })
			curReq.send("false")
			curReq = null;
		}
	}
})


var curReq = null;

client.login(config.discord.token)