-define(SYSLOG_EMERGENCY(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, emergency, Msg, Args)
).
-define(SYSLOG_ALERT(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, alert, Msg, Args)
).
-define(SYSLOG_CRITICAL(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, critical, Msg, Args)
).
-define(SYSLOG_ERROR(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, error, Msg, Args)
).
-define(SYSLOG_WARNING(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, warning, Msg, Args)
).
-define(SYSLOG_NOTICE(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, notice, Msg, Args)
).
-define(SYSLOG_INFO(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, info, Msg, Args)
).
-define(SYSLOG_DEBUG(Who, Msg, Args),
    syslog:send(?MODULE_STRING, self(), ?LINE, Who, debug, Msg, Args)
).