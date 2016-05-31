import plugins
def thing(bot, event, *args):
    term = " ".join(args)
    yield from bot.coro_send_message(event.conv, output)

def _initialise(bot):
    plugins.register_user_command(["weather"])
