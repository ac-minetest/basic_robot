-- send data from robot to irc client, rnd 2018 ( works on vanessae skyblock)

if not init then
  ircchat = minetest.registered_chatcommands["irc_msg"].func;
  name = "r_n_d" -- client on irc you want to send msg too
  ircchat("ROBOT", name .." " .. "hello irc world") -- chat will appear as coming from <ROBOT> on skyblock
  init = true
end

